// ignore_for_file: deprecated_member_use

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

  // ── Future Value form ─────────────────────────────────────────────────────
  final _fvFormKey = GlobalKey<FormState>();
  late final TextEditingController _fvMonthlyCtrl;
  late final TextEditingController _fvReturnCtrl;
  late final TextEditingController _fvYearsCtrl;
  late final TextEditingController _fvCurrentSavingsCtrl;

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

    _fvMonthlyCtrl = TextEditingController();
    _fvReturnCtrl = TextEditingController(text: '10.0');
    _fvYearsCtrl =
        TextEditingController(text: yearsToRetire.toInt().toString());
    _fvCurrentSavingsCtrl = TextEditingController(text: '0');
  }

  @override
  void dispose() {
    _sipGoalCtrl.dispose();
    _sipYearsCtrl.dispose();
    _sipReturnCtrl.dispose();
    _sipInflationCtrl.dispose();
    _sipRaiseCtrl.dispose();
    _fvMonthlyCtrl.dispose();
    _fvReturnCtrl.dispose();
    _fvYearsCtrl.dispose();
    _fvCurrentSavingsCtrl.dispose();
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
        monthlyInvestment: double.parse(_fvMonthlyCtrl.text),
        annualReturn: double.parse(_fvReturnCtrl.text),
        years: double.parse(_fvYearsCtrl.text),
        currentSavings: double.tryParse(_fvCurrentSavingsCtrl.text) ?? 0,
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
        age: widget.user.age,
        riskTolerance: _allocRisk,
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
          const _InfoStrip(
            icon: Icons.savings_outlined,
            text:
                'Enter your goal amount, timeline, and return assumptions. We\'ll calculate the SIP needed.',
          ),
          const SizedBox(height: 24),

          // User snapshot
          _ProfileSnapshot(user: widget.user),
          const SizedBox(height: 24),

          // Form
          const _SectionLabel(label: 'INPUTS'),
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
            const _SectionLabel(label: 'RESULT'),
            const SizedBox(height: 16),
            _CalcResultCard(data: _sipResult!, primaryKeys: const [
              'monthly_sip',
              'sip',
              'required_sip',
              'monthly_investment'
            ]),
          ],
        ],
      );

  // ══════════════════════════════════════════════════════════════════════════
  // ── TAB 1: FUTURE VALUE ────────────────────────────────────────────────────
  // Calls: POST /calculation/future_value_goal
  // "If I invest X/month for N years at R%, what corpus will I build?"
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildFutureValueTab() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _InfoStrip(
            icon: Icons.show_chart,
            text:
                'Enter a monthly investment amount to project its future value at different return rates.',
          ),
          const SizedBox(height: 24),

          const _SectionLabel(label: 'INPUTS'),
          const SizedBox(height: 16),
          Form(
            key: _fvFormKey,
            child: Column(children: [
              _PlannerField(
                  label: 'MONTHLY INVESTMENT',
                  hint: 'e.g. 25000',
                  ctrl: _fvMonthlyCtrl,
                  validator: (v) {
                    final n = double.tryParse(v ?? '');
                    return (n == null || n <= 0) ? 'Required' : null;
                  }),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                    child: _PlannerField(
                        label: 'YEARS',
                        hint: 'e.g. 20',
                        ctrl: _fvYearsCtrl,
                        validator: (v) {
                          final n = double.tryParse(v ?? '');
                          return (n == null || n <= 0) ? 'Required' : null;
                        })),
                const SizedBox(width: 14),
                Expanded(
                    child: _PlannerField(
                        label: 'ANNUAL RETURN (%)',
                        hint: '10.0',
                        ctrl: _fvReturnCtrl,
                        validator: (v) {
                          final n = double.tryParse(v ?? '');
                          return (n == null || n <= 0 || n > 30)
                              ? '0.1–30'
                              : null;
                        })),
              ]),
              const SizedBox(height: 14),
              _PlannerField(
                  label: 'CURRENT SAVINGS (lump sum)',
                  hint: '0',
                  ctrl: _fvCurrentSavingsCtrl,
                  required: false),
            ]),
          ),

          // Scenario hint
          const SizedBox(height: 16),
          _ScenarioHintRow(years: int.tryParse(_fvYearsCtrl.text) ?? 20),

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
            const _SectionLabel(label: 'RESULT'),
            const SizedBox(height: 16),
            _CalcResultCard(data: _fvResult!, primaryKeys: const [
              'future_value',
              'corpus',
              'total_value',
              'maturity_value'
            ]),
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
                'Get a suggested equity/debt split based on your age (${widget.user.age}) and risk tolerance.',
          ),
          const SizedBox(height: 24),

          const _SectionLabel(label: 'RISK TOLERANCE'),
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
            const _SectionLabel(label: 'SUGGESTED ALLOCATION'),
            const SizedBox(height: 16),
            _AllocationResultCard(data: _allocationResult!),
          ],
        ],
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// ── Result Cards ───────────────────────────────────────────────────────────────
// ══════════════════════════════════════════════════════════════════════════════

// Generic calculation result — highlights primary keys as hero tiles
class _CalcResultCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final List<String> primaryKeys; // keys to show as hero tiles

  const _CalcResultCard({required this.data, required this.primaryKeys});

  String _fmt(String key, dynamic raw) {
    if (raw == null) return '—';
    final s = raw.toString().trim();
    if (s.isEmpty || s == 'null') return '—';
    final n = num.tryParse(s);
    if (n == null) return s;
    final lk = key.toLowerCase();
    if (lk.contains('pct') ||
        lk.contains('rate') ||
        lk.contains('return') ||
        lk.contains('percent')) {
      return '${n.toStringAsFixed(1)}%';
    }
    // Currency
    if (n.abs() >= 10000000) return '\$${(n / 10000000).toStringAsFixed(2)}Cr';
    if (n.abs() >= 100000) return '\$${(n / 100000).toStringAsFixed(2)}L';
    if (n.abs() >= 1000) return '\$${(n / 1000).toStringAsFixed(1)}K';
    return '\$${n.toStringAsFixed(0)}';
  }

  String _label(String key) => key.replaceAll('_', ' ').toUpperCase();

  @override
  Widget build(BuildContext context) {
    // Split hero vs supporting
    final heroEntries = data.entries
        .where((e) => primaryKeys
            .any((k) => e.key.toLowerCase().contains(k.toLowerCase())))
        .toList();
    final supportEntries = data.entries
        .where((e) => !primaryKeys
            .any((k) => e.key.toLowerCase().contains(k.toLowerCase())))
        .where((e) => e.value != null && e.value.toString().isNotEmpty)
        .toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Hero tiles
      if (heroEntries.isNotEmpty) ...[
        ...List.generate((heroEntries.length / 2).ceil(), (i) {
          final left = heroEntries[i * 2];
          final right =
              i * 2 + 1 < heroEntries.length ? heroEntries[i * 2 + 1] : null;
          return Padding(
            padding: EdgeInsets.only(
                bottom: i < (heroEntries.length / 2).ceil() - 1 ? 12 : 0),
            child: Row(children: [
              Expanded(
                  child: _HeroTile(
                      label: _label(left.key),
                      value: _fmt(left.key, left.value))),
              const SizedBox(width: 12),
              Expanded(
                  child: right != null
                      ? _HeroTile(
                          label: _label(right.key),
                          value: _fmt(right.key, right.value))
                      : const SizedBox()),
            ]),
          );
        }),
        const SizedBox(height: 12),
      ],

      // Supporting rows
      if (supportEntries.isNotEmpty)
        Container(
          decoration: BoxDecoration(
              color: AppColors.blackCard,
              border: Border.all(color: AppColors.green.withOpacity(0.12))),
          child: Column(
            children: supportEntries.asMap().entries.map((e) {
              final isLast = e.key == supportEntries.length - 1;
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: isLast
                    ? null
                    : BoxDecoration(
                        border: Border(
                            bottom: BorderSide(
                                color: AppColors.green.withOpacity(0.07)))),
                child: Row(children: [
                  Expanded(
                      flex: 3,
                      child: Text(_label(e.value.key),
                          style: TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 9,
                              letterSpacing: 1,
                              color: AppColors.textMuted.withOpacity(0.4)))),
                  Text(_fmt(e.value.key, e.value.value),
                      style: TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMuted.withOpacity(0.85))),
                ]),
              );
            }).toList(),
          ),
        ),
    ]);
  }
}

// Allocation result — renders equity/debt split visually with a bar
class _AllocationResultCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _AllocationResultCard({required this.data});

  @override
  Widget build(BuildContext context) {
    // Try to find equity_pct and debt_pct in result
    double equityPct = 0;
    double debtPct = 0;

    data.forEach((k, v) {
      final lk = k.toLowerCase();
      final n = num.tryParse(v?.toString() ?? '')?.toDouble() ?? 0;
      if (lk.contains('equity')) equityPct = n > 1 ? n : n * 100;
      if (lk.contains('debt') || lk.contains('bond') || lk.contains('fixed')) {
        debtPct = n > 1 ? n : n * 100;
      }
    });

    // Fallback: if only equity found, infer debt
    if (equityPct > 0 && debtPct == 0) debtPct = 100 - equityPct;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Visual bar
      if (equityPct > 0) ...[
        Row(children: [
          Expanded(
            flex: equityPct.round(),
            child: Container(
              height: 10,
              color: AppColors.green,
            ),
          ),
          Expanded(
            flex: debtPct.round(),
            child: Container(
              height: 10,
              color: AppColors.textMuted.withOpacity(0.2),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _AllocLegend(color: AppColors.green, label: 'EQUITY', pct: equityPct),
          const SizedBox(width: 24),
          _AllocLegend(
              color: AppColors.textMuted.withOpacity(0.4),
              label: 'DEBT / BONDS',
              pct: debtPct),
        ]),
        const SizedBox(height: 16),
      ],

      // All raw fields
      Container(
        decoration: BoxDecoration(
            color: AppColors.blackCard,
            border: Border.all(color: AppColors.green.withOpacity(0.12))),
        child: Column(
          children: data.entries
              .where((e) => e.value != null && e.value.toString().isNotEmpty)
              .toList()
              .asMap()
              .entries
              .map((e) {
            final isLast = e.key == data.entries.length - 1;
            final key = e.value.key.replaceAll('_', ' ').toUpperCase();
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: isLast
                  ? null
                  : BoxDecoration(
                      border: Border(
                          bottom: BorderSide(
                              color: AppColors.green.withOpacity(0.07)))),
              child: Row(children: [
                Expanded(
                    flex: 3,
                    child: Text(key,
                        style: TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 9,
                            letterSpacing: 1,
                            color: AppColors.textMuted.withOpacity(0.4)))),
                Text(e.value.value.toString(),
                    style: const TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.green)),
              ]),
            );
          }).toList(),
        ),
      ),
    ]);
  }
}

class _AllocLegend extends StatelessWidget {
  final Color color;
  final String label;
  final double pct;
  const _AllocLegend(
      {required this.color, required this.label, required this.pct});

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(width: 10, height: 10, color: color),
        const SizedBox(width: 8),
        Text('$label  ${pct.toStringAsFixed(0)}%',
            style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 10,
                letterSpacing: 1,
                color: AppColors.textMuted.withOpacity(0.6))),
      ]);
}

class _HeroTile extends StatelessWidget {
  final String label, value;
  const _HeroTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.blackCard,
          border: Border.all(color: AppColors.green.withOpacity(0.35)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 8,
                  letterSpacing: 2,
                  color: AppColors.textMuted.withOpacity(0.45))),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Courier',
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.green,
              shadows: [
                Shadow(color: AppColors.green.withOpacity(0.4), blurRadius: 8)
              ],
            ),
          ),
        ]),
      );
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
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.error, size: 16),
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
  final bool required;
  const _PlannerField(
      {required this.label,
      required this.ctrl,
      required this.hint,
      this.validator,
      this.required = true});

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
                (v) =>
                    (required && (v == null || v.isEmpty)) ? 'Required' : null,
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
              focusedErrorBorder: const OutlineInputBorder(
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
