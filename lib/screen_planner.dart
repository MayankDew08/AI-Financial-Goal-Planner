// ignore_for_file: unused_element, unused_element_parameter, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_theme.dart';
import 'api_service.dart';

// ══════════════════════════════════════════════════════════════════════════════
// ── Planner Screen ─────────────────────────────────────────────────────────────
// ══════════════════════════════════════════════════════════════════════════════
class PlannerScreen extends StatefulWidget {
  final UserProfile user;
  const PlannerScreen({super.key, required this.user});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  // ── Active tab: 0 = Retirement SIP, 1 = Future Value, 2 = Allocation ────
  int _activeTab = 0;

  // ── Results ──────────────────────────────────────────────────────────────
  Map<String, dynamic>? _sipResult;
  Map<String, dynamic>? _fvResult;
  Map<String, dynamic>? _allocationResult;

  // ── Loading / error per tab ───────────────────────────────────────────────
  bool _sipLoading = false;
  bool _fvLoading = false;
  bool _allocLoading = false;
  String? _sipError;
  String? _fvError;
  String? _allocError;

  // ── SIP form ──────────────────────────────────────────────────────────────
  final _sipFormKey = GlobalKey<FormState>();
  late final TextEditingController _sipGoalCtrl; // goal_amount
  late final TextEditingController _sipYearsCtrl; // years_to_goal
  late final TextEditingController _sipReturnCtrl; // pre_ret_return
  late final TextEditingController _sipInflationCtrl; // inflation_rate
  late final TextEditingController _sipRaiseCtrl; // income_raise_pct

  // ── Future Value form (POST /calculation/future_value_goal)
  // Schema: { principal, infation_rate, years }
  final _fvFormKey = GlobalKey<FormState>();
  late final TextEditingController _fvPrincipalCtrl; // principal
  late final TextEditingController
      _fvInflationCtrl; // infation_rate (backend typo)
  late final TextEditingController _fvYearsCtrl; // years

  // ── Allocation form ───────────────────────────────────────────────────────
  String _allocRisk = 'moderate';

  static const _tabs = ['RETIREMENT SIP', 'FUTURE VALUE', 'ALLOCATION'];

  @override
  void initState() {
    super.initState();
    final yearsToRetire = (60 - widget.user.age).clamp(1, 60).toDouble();

    // Pre-fill from user profile where possible
    _sipGoalCtrl = TextEditingController();
    _sipYearsCtrl =
        TextEditingController(text: yearsToRetire.toInt().toString());
    _sipReturnCtrl = TextEditingController(text: '10.0');
    _sipInflationCtrl = TextEditingController(
        text: widget.user.incomeRaisePct.toStringAsFixed(1));
    _sipRaiseCtrl = TextEditingController(
        text: widget.user.incomeRaisePct.toStringAsFixed(1));

    _fvPrincipalCtrl = TextEditingController();
    _fvInflationCtrl = TextEditingController(
        text: widget.user.inflationRate.toStringAsFixed(1));
    _fvYearsCtrl =
        TextEditingController(text: yearsToRetire.toInt().toString());
  }

  @override
  void dispose() {
    _sipGoalCtrl.dispose();
    _sipYearsCtrl.dispose();
    _sipReturnCtrl.dispose();
    _sipInflationCtrl.dispose();
    _sipRaiseCtrl.dispose();
    _fvPrincipalCtrl.dispose();
    _fvInflationCtrl.dispose();
    _fvYearsCtrl.dispose();
    super.dispose();
  }

  // ── API calls ─────────────────────────────────────────────────────────────

  Future<void> _runSip() async {
    if (!_sipFormKey.currentState!.validate()) return;
    setState(() {
      _sipLoading = true;
      _sipError = null;
    });
    try {
      final result = await ApiService.instance.calcStartingSip(
        goalAmount: double.parse(_sipGoalCtrl.text),
        yearsToGoal: double.parse(_sipYearsCtrl.text),
        preRetReturn: double.parse(_sipReturnCtrl.text),
        inflationRate: double.parse(_sipInflationCtrl.text),
        incomeRaisePct: double.parse(_sipRaiseCtrl.text),
      );
      setState(() => _sipResult = result);
    } on ApiException catch (e) {
      setState(() => _sipError = e.message);
    } catch (_) {
      setState(() => _sipError = 'Network error. Please try again.');
    } finally {
      setState(() => _sipLoading = false);
    }
  }

  Future<void> _runFutureValue() async {
    if (!_fvFormKey.currentState!.validate()) return;
    setState(() {
      _fvLoading = true;
      _fvError = null;
    });
    try {
      final result = await ApiService.instance.calcFutureValue(
        principal: double.parse(_fvPrincipalCtrl.text),
        inflationRate: double.parse(_fvInflationCtrl.text),
        years: double.parse(_fvYearsCtrl.text),
      );
      setState(() => _fvResult = result);
    } on ApiException catch (e) {
      setState(() => _fvError = e.message);
    } catch (_) {
      setState(() => _fvError = 'Network error. Please try again.');
    } finally {
      setState(() => _fvLoading = false);
    }
  }

  Future<void> _runAllocation() async {
    setState(() {
      _allocLoading = true;
      _allocError = null;
    });
    try {
      final result = await ApiService.instance.calcSuggestAllocation(
        years: int.tryParse(_sipYearsCtrl.text) ??
            (60 - widget.user.age).clamp(1, 60),
        risk: _allocRisk,
      );
      setState(() => _allocationResult = result);
    } on ApiException catch (e) {
      setState(() => _allocError = e.message);
    } catch (_) {
      setState(() => _allocError = 'Network error. Please try again.');
    } finally {
      setState(() => _allocLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          CustomPaint(
              size: MediaQuery.of(context).size, painter: GridPainter()),
          // Glow
          Positioned(
            bottom: -60,
            left: -60,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.green.withOpacity(0.06),
                  Colors.transparent
                ]),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                _buildTabBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                    child: _buildActiveTab(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() => Container(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 20, height: 1, color: AppColors.green),
            const SizedBox(width: 10),
            Text('FINANCIAL PLANNER',
                style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 9,
                    letterSpacing: 4,
                    color: AppColors.green.withOpacity(0.6))),
            const Spacer(),
            // User age badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  border: Border.all(color: AppColors.green.withOpacity(0.25))),
              child: Text('AGE ${widget.user.age}',
                  style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 9,
                      letterSpacing: 2,
                      color: AppColors.green.withOpacity(0.6))),
            ),
          ]),
          const SizedBox(height: 12),
          const Text('PLAN YOUR\nFUTURE.',
              style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  height: 1.0,
                  color: Colors.white)),
          const SizedBox(height: 10),
          Text(
            'Calculations powered by /calculation API.\nProfile data pre-filled from your account.',
            style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 11,
                height: 1.7,
                color: AppColors.textMuted.withOpacity(0.35)),
          ),
          const SizedBox(height: 20),
        ]),
      );

  // ── Tab Bar ───────────────────────────────────────────────────────────────
  Widget _buildTabBar() => Container(
        height: 44,
        decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(color: AppColors.green.withOpacity(0.1)))),
        child: Row(
          children: _tabs.asMap().entries.map((e) {
            final active = _activeTab == e.key;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _activeTab = e.key),
                child: Container(
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.green.withOpacity(0.08)
                        : Colors.transparent,
                    border: Border(
                        bottom: BorderSide(
                            color:
                                active ? AppColors.green : Colors.transparent,
                            width: 2)),
                  ),
                  child: Center(
                    child: Text(
                      e.value,
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 8,
                        letterSpacing: 2,
                        fontWeight:
                            active ? FontWeight.bold : FontWeight.normal,
                        color: active
                            ? AppColors.green
                            : AppColors.textMuted.withOpacity(0.35),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );

  Widget _buildActiveTab() {
    switch (_activeTab) {
      case 0:
        return _buildSipTab();
      case 1:
        return _buildFutureValueTab();
      case 2:
        return _buildAllocationTab();
      default:
        return const SizedBox();
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── TAB 0: RETIREMENT SIP ──────────────────────────────────────────────────
  // Calls: POST /calculation/starting-sip
  // "What SIP do I need each month to hit my retirement corpus?"
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildSipTab() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Context strip
          _InfoStrip(
            icon: Icons.savings_outlined,
            text:
                'Enter your goal amount, timeline, and return assumptions. We\'ll calculate the SIP needed.',
          ),
          const SizedBox(height: 24),

          // User snapshot
          _ProfileSnapshot(user: widget.user),
          const SizedBox(height: 24),

          // Form
          _SectionLabel(label: 'INPUTS'),
          const SizedBox(height: 16),
          Form(
            key: _sipFormKey,
            child: Column(children: [
              _PlannerField(
                label: 'GOAL AMOUNT',
                hint: 'e.g. 50000000',
                ctrl: _sipGoalCtrl,
                validator: (v) {
                  final n = double.tryParse(v ?? '');
                  return (n == null || n <= 0) ? 'Required' : null;
                },
              ),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                    child: _PlannerField(
                  label: 'YEARS TO GOAL',
                  hint: 'e.g. 25',
                  ctrl: _sipYearsCtrl,
                  validator: (v) {
                    final n = double.tryParse(v ?? '');
                    return (n == null || n <= 0) ? 'Required' : null;
                  },
                )),
                const SizedBox(width: 14),
                Expanded(
                    child: _PlannerField(
                  label: 'PRE-RETIREMENT RETURN (%)',
                  hint: '10.0',
                  ctrl: _sipReturnCtrl,
                  validator: (v) {
                    final n = double.tryParse(v ?? '');
                    return (n == null || n <= 0 || n > 30) ? '0.1–30' : null;
                  },
                )),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                    child: _PlannerField(
                  label: 'INFLATION RATE (%)',
                  hint: '6.0',
                  ctrl: _sipInflationCtrl,
                  validator: (v) {
                    final n = double.tryParse(v ?? '');
                    return (n == null || n <= 0) ? 'Required' : null;
                  },
                )),
                const SizedBox(width: 14),
                Expanded(
                    child: _PlannerField(
                  label: 'INCOME RAISE (%)',
                  hint: '5.0',
                  ctrl: _sipRaiseCtrl,
                  validator: (v) {
                    final n = double.tryParse(v ?? '');
                    return (n == null || n < 0) ? 'Required' : null;
                  },
                )),
              ]),
            ]),
          ),

          const SizedBox(height: 24),
          if (_sipError != null) ...[
            _ErrorBanner(msg: _sipError!),
            const SizedBox(height: 16)
          ],
          _RunButton(
              label: 'CALCULATE MONTHLY SIP',
              loading: _sipLoading,
              onTap: _runSip),

          // Result
          if (_sipResult != null) ...[
            const SizedBox(height: 28),
            _SectionLabel(label: 'RESULT'),
            const SizedBox(height: 16),
            _ApiResultCard(rawData: _sipResult!, title: 'MONTHLY SIP REQUIRED'),
          ],
        ],
      );

  // ══════════════════════════════════════════════════════════════════════════
  // ── TAB 1: FUTURE VALUE ────────────────────────────────────────────────────
  // Calls: POST /calculation/future_value_goal
  // Schema: { principal, infation_rate, years }
  // "What will my lump sum be worth in N years at X% inflation?"
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildFutureValueTab() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoStrip(
            icon: Icons.show_chart,
            text:
                'Enter a lump sum amount and inflation rate to see its real future value.',
          ),
          const SizedBox(height: 24),
          _SectionLabel(label: 'INPUTS'),
          const SizedBox(height: 16),
          Form(
            key: _fvFormKey,
            child: Column(children: [
              _PlannerField(
                  label: 'PRINCIPAL AMOUNT (lump sum today)',
                  hint: 'e.g. 1000000',
                  ctrl: _fvPrincipalCtrl,
                  validator: (v) {
                    final n = double.tryParse(v ?? '');
                    return (n == null || n <= 0) ? 'Required' : null;
                  }),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                    child: _PlannerField(
                        label: 'INFLATION RATE (%)',
                        hint: '6.0',
                        ctrl: _fvInflationCtrl,
                        validator: (v) {
                          final n = double.tryParse(v ?? '');
                          return (n == null || n <= 0 || n > 30)
                              ? '0.1–30'
                              : null;
                        })),
                const SizedBox(width: 14),
                Expanded(
                    child: _PlannerField(
                        label: 'YEARS',
                        hint: 'e.g. 20',
                        ctrl: _fvYearsCtrl,
                        validator: (v) {
                          final n = double.tryParse(v ?? '');
                          return (n == null || n <= 0) ? 'Required' : null;
                        })),
              ]),
            ]),
          ),
          const SizedBox(height: 24),
          if (_fvError != null) ...[
            _ErrorBanner(msg: _fvError!),
            const SizedBox(height: 16)
          ],
          _RunButton(
              label: 'PROJECT FUTURE VALUE',
              loading: _fvLoading,
              onTap: _runFutureValue),
          if (_fvResult != null) ...[
            const SizedBox(height: 28),
            _SectionLabel(label: 'RESULT'),
            const SizedBox(height: 16),
            _ApiResultCard(
                rawData: _fvResult!, title: 'PROJECTED FUTURE VALUE'),
          ],
        ],
      );

  // ══════════════════════════════════════════════════════════════════════════
  // ── TAB 2: SUGGESTED ALLOCATION ────────────────────────────────────────────
  // Calls: POST /calculation/suggest_allocation
  // "Given my age and risk tolerance, how should I split equity/debt?"
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildAllocationTab() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoStrip(
            icon: Icons.pie_chart_outline,
            text:
                'Get a suggested equity/debt split based on your investment horizon and risk tolerance.',
          ),
          const SizedBox(height: 24),

          _SectionLabel(label: 'RISK TOLERANCE'),
          const SizedBox(height: 16),

          // Risk selector — full width cards
          Column(
            children: [
              ['conservative', 'Low risk. Capital preservation focus.'],
              ['moderate', 'Balanced growth & stability.'],
              ['aggressive', 'High growth. Volatility tolerance.'],
            ].map((r) {
              final id = r[0];
              final desc = r[1];
              final sel = _allocRisk == id;
              return GestureDetector(
                onTap: () => setState(() {
                  _allocRisk = id;
                  _allocationResult = null;
                }),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: sel
                        ? AppColors.green.withOpacity(0.08)
                        : AppColors.blackCard,
                    border: Border.all(
                        color: sel
                            ? AppColors.green
                            : AppColors.green.withOpacity(0.1)),
                  ),
                  child: Row(children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: sel ? AppColors.green : Colors.transparent,
                        border: Border.all(
                            color: sel
                                ? AppColors.green
                                : AppColors.textMuted.withOpacity(0.3)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(id.toUpperCase(),
                              style: TextStyle(
                                  fontFamily: 'Courier',
                                  fontSize: 11,
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.bold,
                                  color: sel ? AppColors.green : Colors.white)),
                          const SizedBox(height: 3),
                          Text(desc,
                              style: TextStyle(
                                  fontFamily: 'Courier',
                                  fontSize: 9,
                                  color: AppColors.textMuted.withOpacity(0.4))),
                        ]),
                  ]),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),
          if (_allocError != null) ...[
            _ErrorBanner(msg: _allocError!),
            const SizedBox(height: 16)
          ],
          _RunButton(
              label: 'GET SUGGESTED ALLOCATION',
              loading: _allocLoading,
              onTap: _runAllocation),

          if (_allocationResult != null) ...[
            const SizedBox(height: 28),
            _AllocationResultCard(data: _allocationResult!),
          ],
        ],
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// ── Shared Smart Result Card ───────────────────────────────────────────────────
// Handles any API response shape: flat, nested, or wrapped.
// First numeric field → hero tile. All others → detail rows.
// ══════════════════════════════════════════════════════════════════════════════

Map<String, dynamic> _flattenResult(Map<String, dynamic> raw) {
  final out = <String, dynamic>{};
  raw.forEach((k, v) {
    if (v is Map<String, dynamic>) {
      v.forEach((ik, iv) {
        if (iv is! List && iv is! Map) out[ik] = iv;
      });
    } else if (v is! List) {
      out[k] = v;
    }
  });
  return out;
}

// Smart formatter: detects percent, large currency, plain number
String _smartFmt(String key, dynamic raw) {
  if (raw == null) return '—';
  final s = raw.toString().trim();
  if (s.isEmpty || s == 'null' || s == 'None') return '—';
  final n = num.tryParse(s);
  if (n == null) {
    if (s.toLowerCase() == 'true') return 'YES';
    if (s.toLowerCase() == 'false') return 'NO';
    return s.length > 40 ? '${s.substring(0, 40)}…' : s;
  }
  final lk = key.toLowerCase();
  // Percentage
  if (lk.contains('pct') ||
      lk.contains('rate') ||
      lk.contains('return') ||
      lk.contains('percent') ||
      lk.contains('raise') ||
      lk.contains('yield')) {
    return '${n.toStringAsFixed(1)}%';
  }
  // Age / year / count — plain int
  if (lk.contains('age') ||
      lk.contains('year') ||
      lk.contains('duration') ||
      lk.contains('period') ||
      lk.contains('count')) {
    return n.toInt().toString();
  }
  // Currency — everything else numeric
  final abs = n.abs();
  if (abs >= 10000000) return '₹${(n / 10000000).toStringAsFixed(2)} Cr';
  if (abs >= 100000) return '₹${(n / 100000).toStringAsFixed(2)} L';
  if (abs >= 1000) return '₹${(n / 1000).toStringAsFixed(1)} K';
  if (abs > 0 && abs < 1) return n.toStringAsFixed(4); // small decimals
  return n % 1 == 0 ? n.toInt().toString() : n.toStringAsFixed(2);
}

String _keyLabel(String key) => key.replaceAll('_', ' ').trim().toUpperCase();

// Decides which keys are "primary" outputs worth showing as hero tiles.
// Strategy: any key whose value is a large number and whose name suggests
// it's an output (not an input echo) gets hero treatment.
bool _isPrimaryKey(String key, dynamic value) {
  final lk = key.toLowerCase();
  final n = num.tryParse(value?.toString() ?? '');
  // Must be numeric
  if (n == null) return false;
  // Input-echo keys we deprioritise
  if (lk.contains('inflation') ||
      lk.contains('raise') ||
      lk.contains('input') ||
      lk == 'years' ||
      lk == 'age' ||
      lk == 'goal_amount' ||
      lk == 'years_to_goal') {
    return false;
  }
  // Strong output signal
  if (lk.contains('sip') ||
      lk.contains('corpus') ||
      lk.contains('required') ||
      lk.contains('monthly') ||
      lk.contains('future') ||
      lk.contains('value') ||
      lk.contains('maturity') ||
      lk.contains('target') ||
      lk.contains('shortfall') ||
      lk.contains('surplus') ||
      lk.contains('saving') ||
      lk.contains('investment') ||
      lk.contains('result') ||
      lk.contains('amount') ||
      lk.contains('fund')) {
    return true;
  }
  // Large number = likely an output
  return n.abs() >= 1000;
}

class _ApiResultCard extends StatelessWidget {
  final Map<String, dynamic> rawData;
  final String title;
  const _ApiResultCard({required this.rawData, required this.title});

  @override
  Widget build(BuildContext context) {
    final data = _flattenResult(rawData);
    if (data.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.blackCard,
          border: Border.all(color: AppColors.green.withOpacity(0.15)),
        ),
        child: Text('No result data returned.',
            style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 11,
                color: AppColors.textMuted.withOpacity(0.4))),
      );
    }

    final primary =
        data.entries.where((e) => _isPrimaryKey(e.key, e.value)).toList();
    final secondary =
        data.entries.where((e) => !_isPrimaryKey(e.key, e.value)).toList();

    // If nothing matched primary heuristic, treat ALL numeric entries as primary
    final heroes = primary.isNotEmpty
        ? primary
        : data.entries
            .where((e) => num.tryParse(e.value?.toString() ?? '') != null)
            .toList();
    final details = primary.isNotEmpty
        ? secondary
        : data.entries
            .where((e) => num.tryParse(e.value?.toString() ?? '') == null)
            .toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // ── Section label ──────────────────────────────────────────────────────
      Row(children: [
        Container(width: 20, height: 1, color: AppColors.green),
        const SizedBox(width: 10),
        Text(title,
            style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 10,
                letterSpacing: 4,
                color: AppColors.green.withOpacity(0.7))),
      ]),
      const SizedBox(height: 16),

      // ── Hero tiles (primary outputs) ───────────────────────────────────────
      if (heroes.isNotEmpty) ...[
        ...List.generate((heroes.length / 2).ceil(), (i) {
          final left = heroes[i * 2];
          final right = (i * 2 + 1 < heroes.length) ? heroes[i * 2 + 1] : null;
          return Padding(
            padding: EdgeInsets.only(
                bottom: i < (heroes.length / 2).ceil() - 1 ? 10 : 0),
            child: Row(children: [
              Expanded(
                  child: _ResultHeroTile(
                      label: _keyLabel(left.key),
                      value: _smartFmt(left.key, left.value))),
              const SizedBox(width: 10),
              Expanded(
                  child: right != null
                      ? _ResultHeroTile(
                          label: _keyLabel(right.key),
                          value: _smartFmt(right.key, right.value))
                      : const SizedBox()),
            ]),
          );
        }),
        const SizedBox(height: 14),
      ],

      // ── Detail rows (secondary / input-echo fields) ────────────────────────
      if (details.isNotEmpty)
        Container(
          decoration: BoxDecoration(
              color: AppColors.blackCard,
              border: Border.all(color: AppColors.green.withOpacity(0.1))),
          child: Column(
            children: details.asMap().entries.map((e) {
              final isLast = e.key == details.length - 1;
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                decoration: isLast
                    ? null
                    : BoxDecoration(
                        border: Border(
                            bottom: BorderSide(
                                color: AppColors.green.withOpacity(0.06)))),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                        flex: 2,
                        child: Text(_keyLabel(e.value.key),
                            style: TextStyle(
                                fontFamily: 'Courier',
                                fontSize: 9,
                                letterSpacing: 1,
                                color: AppColors.textMuted.withOpacity(0.35)))),
                    const SizedBox(width: 8),
                    Expanded(
                        flex: 3,
                        child: Text(_smartFmt(e.value.key, e.value.value),
                            textAlign: TextAlign.right,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontFamily: 'Courier',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textMuted.withOpacity(0.75)))),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
    ]);
  }
}

class _ResultHeroTile extends StatelessWidget {
  final String label, value;
  const _ResultHeroTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.blackCard,
          border: Border.all(color: AppColors.green.withOpacity(0.4)),
          boxShadow: [
            BoxShadow(
                color: AppColors.green.withOpacity(0.04),
                blurRadius: 12,
                spreadRadius: 1)
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 8,
                  letterSpacing: 2,
                  color: AppColors.textMuted.withOpacity(0.4))),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.green,
                  shadows: [
                    Shadow(
                        color: AppColors.green.withOpacity(0.35),
                        blurRadius: 10)
                  ],
                )),
          ),
        ]),
      );
}

// Allocation gets its own visual treatment with equity/debt bar
class _AllocationResultCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _AllocationResultCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final flat = _flattenResult(data);
    double equityPct = 0;
    double debtPct = 0;

    flat.forEach((k, v) {
      final lk = k.toLowerCase();
      final n = num.tryParse(v?.toString() ?? '')?.toDouble() ?? 0;
      if (lk.contains('equity')) equityPct = n > 1 ? n : n * 100;
      if (lk.contains('debt') ||
          lk.contains('bond') ||
          lk.contains('fixed') ||
          lk.contains('large') && lk.contains('cap') == false) {
        debtPct = n > 1 ? n : n * 100;
      }
    });
    if (equityPct > 0 && debtPct == 0) debtPct = 100 - equityPct;
    if (equityPct == 0 && debtPct == 0) {
      // Fallback: just show raw data
      return _ApiResultCard(rawData: data, title: 'SUGGESTED ALLOCATION');
    }

    final eqInt = equityPct.round().clamp(1, 99);
    final dtInt = (100 - eqInt).clamp(1, 99);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Label
      Row(children: [
        Container(width: 20, height: 1, color: AppColors.green),
        const SizedBox(width: 10),
        Text('SUGGESTED ALLOCATION',
            style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 10,
                letterSpacing: 4,
                color: AppColors.green.withOpacity(0.7))),
      ]),
      const SizedBox(height: 16),

      // Bar
      ClipRRect(
        child: Row(children: [
          Expanded(
              flex: eqInt,
              child: Container(
                height: 12,
                color: AppColors.green,
              )),
          Expanded(
              flex: dtInt,
              child: Container(
                height: 12,
                color: AppColors.textMuted.withOpacity(0.18),
              )),
        ]),
      ),
      const SizedBox(height: 14),

      // Legend tiles
      Row(children: [
        Expanded(child: _ResultHeroTile(label: 'EQUITY', value: '$eqInt%')),
        const SizedBox(width: 10),
        Expanded(
            child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.blackCard,
            border: Border.all(color: AppColors.green.withOpacity(0.12)),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('DEBT / BONDS',
                style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 8,
                    letterSpacing: 2,
                    color: AppColors.textMuted.withOpacity(0.4))),
            const SizedBox(height: 10),
            Text('$dtInt%',
                style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textMuted.withOpacity(0.65))),
          ]),
        )),
      ]),
      const SizedBox(height: 14),

      // All fields as detail rows
      Container(
        decoration: BoxDecoration(
            color: AppColors.blackCard,
            border: Border.all(color: AppColors.green.withOpacity(0.1))),
        child: Column(
          children: flat.entries.toList().asMap().entries.map((e) {
            final isLast = e.key == flat.length - 1;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: isLast
                  ? null
                  : BoxDecoration(
                      border: Border(
                          bottom: BorderSide(
                              color: AppColors.green.withOpacity(0.06)))),
              child: Row(children: [
                Expanded(
                    flex: 3,
                    child: Text(_keyLabel(e.value.key),
                        style: TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 9,
                            letterSpacing: 1,
                            color: AppColors.textMuted.withOpacity(0.35)))),
                Text(_smartFmt(e.value.key, e.value.value),
                    style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.green.withOpacity(0.8))),
              ]),
            );
          }).toList(),
        ),
      ),
    ]);
  }
}

// ── Profile Snapshot (shown on SIP tab for context) ───────────────────────────
class _ProfileSnapshot extends StatelessWidget {
  final UserProfile user;
  const _ProfileSnapshot({required this.user});

  String _fmtIncome(double v) {
    if (v >= 10000000) return '\$${(v / 10000000).toStringAsFixed(1)}Cr/yr';
    if (v >= 100000) return '\$${(v / 100000).toStringAsFixed(1)}L/yr';
    if (v >= 1000) return '\$${(v / 1000).toStringAsFixed(0)}K/yr';
    return '\$${v.toStringAsFixed(0)}/yr';
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.blackCard,
          border: Border.all(color: AppColors.green.withOpacity(0.12)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('YOUR PROFILE',
              style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 8,
                  letterSpacing: 3,
                  color: AppColors.textMuted.withOpacity(0.35))),
          const SizedBox(height: 12),
          Row(children: [
            _SnapStat(label: 'AGE', value: '${user.age}'),
            _SnapStat(label: 'INCOME', value: _fmtIncome(user.currentIncome)),
            _SnapStat(
                label: 'RAISE',
                value: '${user.incomeRaisePct.toStringAsFixed(1)}%'),
            _SnapStat(
                label: 'STATUS',
                value: user.maritalStatus.toUpperCase().substring(0, 1)),
          ]),
        ]),
      );
}

class _SnapStat extends StatelessWidget {
  final String label, value;
  const _SnapStat({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 7,
                  letterSpacing: 2,
                  color: AppColors.textMuted.withOpacity(0.3))),
          const SizedBox(height: 3),
          Text(value,
              style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.green.withOpacity(0.85))),
        ]),
      );
}

// ── Scenario hint row (Future Value tab) ──────────────────────────────────────
class _ScenarioHintRow extends StatelessWidget {
  final int years;
  const _ScenarioHintRow({required this.years});

  double _mult(double r) =>
      ((1 + r / 100 / 12) *
              ((((1 + r / 100 / 12) * (years * 12) - 1)) / (r / 100 / 12)))
          .clamp(0, double.infinity) /
      (years * 12);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            border: Border.all(color: AppColors.green.withOpacity(0.1)),
            color: AppColors.blackCard),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('SCENARIO PREVIEW (per \$1K/month over $years yrs)',
              style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 8,
                  letterSpacing: 2,
                  color: AppColors.textMuted.withOpacity(0.3))),
          const SizedBox(height: 12),
          Row(children: [
            _ScenChip(
                label: '6%  CONSERVATIVE',
                value: '\$${(_mult(6) * 1000 / 1000).toStringAsFixed(0)}K',
                color: AppColors.textMuted.withOpacity(0.5)),
            const SizedBox(width: 8),
            _ScenChip(
                label: '10%  MODERATE',
                value: '\$${(_mult(10) * 1000 / 1000).toStringAsFixed(0)}K',
                color: AppColors.green),
            const SizedBox(width: 8),
            _ScenChip(
                label: '14%  AGGRESSIVE',
                value: '\$${(_mult(14) * 1000 / 1000).toStringAsFixed(0)}K',
                color: AppColors.greenDim),
          ]),
        ]),
      );
}

class _ScenChip extends StatelessWidget {
  final String label, value;
  final Color color;
  const _ScenChip(
      {required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 7,
                  letterSpacing: 1,
                  color: AppColors.textMuted.withOpacity(0.35))),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color)),
        ]),
      );
}

// ── Shared Widgets ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});
  @override
  Widget build(BuildContext context) => Row(children: [
        Container(width: 20, height: 1, color: AppColors.green),
        const SizedBox(width: 10),
        Text(label,
            style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 10,
                letterSpacing: 4,
                color: AppColors.green.withOpacity(0.7))),
      ]);
}

class _InfoStrip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoStrip({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            border: Border.all(color: AppColors.green.withOpacity(0.12)),
            color: AppColors.green.withOpacity(0.04)),
        child: Row(children: [
          Icon(icon, color: AppColors.green.withOpacity(0.5), size: 18),
          const SizedBox(width: 12),
          Expanded(
              child: Text(text,
                  style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 10,
                      height: 1.6,
                      color: AppColors.textMuted.withOpacity(0.45)))),
        ]),
      );
}

class _ErrorBanner extends StatelessWidget {
  final String msg;
  const _ErrorBanner({required this.msg});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            border: Border.all(color: AppColors.error.withOpacity(0.4)),
            color: AppColors.error.withOpacity(0.06)),
        child: Row(children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 16),
          const SizedBox(width: 10),
          Expanded(
              child: Text(msg,
                  style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 10,
                      height: 1.5,
                      color: AppColors.error.withOpacity(0.8)))),
        ]),
      );
}

class _RunButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onTap;
  const _RunButton(
      {required this.label, required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: loading ? null : onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          color: loading ? AppColors.green.withOpacity(0.5) : AppColors.green,
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.black))
                : Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.play_arrow_rounded,
                        color: AppColors.black, size: 16),
                    const SizedBox(width: 8),
                    Text(label,
                        style: const TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 11,
                            letterSpacing: 3,
                            fontWeight: FontWeight.bold,
                            color: AppColors.black)),
                  ]),
          ),
        ),
      );
}

class _PlannerField extends StatelessWidget {
  final String label, hint;
  final TextEditingController ctrl;
  final String? Function(String?)? validator;
  final bool isRequired;
  const _PlannerField({
    required this.label,
    required this.ctrl,
    required this.hint,
    this.validator,
    this.isRequired = true,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 9,
                  letterSpacing: 3,
                  color: AppColors.green.withOpacity(0.6))),
          const SizedBox(height: 6),
          TextFormField(
            controller: ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
            ],
            validator: validator ??
                (v) => (isRequired && (v == null || v.isEmpty))
                    ? 'Required'
                    : null,
            style: const TextStyle(
                fontFamily: 'Courier', fontSize: 13, color: Colors.white),
            cursorColor: AppColors.green,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 12,
                  color: AppColors.textMuted.withOpacity(0.2)),
              filled: true,
              fillColor: AppColors.blackMid,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide:
                      BorderSide(color: AppColors.green.withOpacity(0.15))),
              focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: AppColors.green, width: 1.5)),
              errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide:
                      BorderSide(color: AppColors.error.withOpacity(0.6))),
              focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: AppColors.error)),
              errorStyle: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 9,
                  color: AppColors.error.withOpacity(0.8)),
            ),
          ),
        ],
      );
}
