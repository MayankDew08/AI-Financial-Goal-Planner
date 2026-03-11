// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_theme.dart';
import 'api_service.dart';

// ── Goals Screen ──────────────────────────────────────────────────────────────
class GoalsScreen extends StatefulWidget {
  final UserProfile user;
  const GoalsScreen({super.key, required this.user});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  Map<String, dynamic>? _retirementResult;
  Map<String, dynamic>? _lastOneTimeResult;
  String? _lastOneTimeGoalName;
  String? _errorMsg;

  static const _goalTemplates = [
    _GoalTemplate(
        icon: Icons.house_outlined, title: 'BUY A HOME', tag: 'PROPERTY'),
    _GoalTemplate(
        icon: Icons.school_outlined, title: 'EDUCATION FUND', tag: 'EDUCATION'),
    _GoalTemplate(
        icon: Icons.directions_car_outlined,
        title: 'BUY A VEHICLE',
        tag: 'LIFESTYLE'),
    _GoalTemplate(
        icon: Icons.flight_outlined, title: 'TRAVEL FUND', tag: 'LIFESTYLE'),
    _GoalTemplate(
        icon: Icons.savings_outlined, title: 'EMERGENCY CORPUS', tag: 'SAFETY'),
    _GoalTemplate(
        icon: Icons.celebration_outlined,
        title: 'WEDDING FUND',
        tag: 'LIFESTYLE'),
  ];

  void _openRetirementSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.blackCard,
      shape: const RoundedRectangleBorder(),
      builder: (_) => _RetirementGoalSheet(
        user: widget.user,
        onSubmit: (result) => setState(() {
          _retirementResult = result;
          _errorMsg = null;
        }),
        onError: (msg) => setState(() => _errorMsg = msg),
      ),
    );
  }

  void _openOneTimeGoalSheet(String goalName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.blackCard,
      shape: const RoundedRectangleBorder(),
      builder: (_) => _OneTimeGoalSheet(
        goalName: goalName,
        user: widget.user,
        onSubmit: (result) => setState(() {
          _lastOneTimeResult = result;
          _lastOneTimeGoalName = goalName;
          _errorMsg = null;
        }),
        onError: (msg) => setState(() => _errorMsg = msg),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          CustomPaint(
              size: MediaQuery.of(context).size, painter: GridPainter()),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_errorMsg != null) ...[
                          _buildErrorBanner(),
                          const SizedBox(height: 16)
                        ],
                        const SizedBox(height: 4),

                        // ── Retirement ─────────────────────────────────────
                        _buildSectionLabel('RETIREMENT GOAL'),
                        const SizedBox(height: 12),
                        _buildRetirementCard(),
                        if (_retirementResult != null) ...[
                          const SizedBox(height: 20),
                          _RetirementResultCard(data: _retirementResult!),
                        ],

                        const SizedBox(height: 28),

                        // ── One-time goals ─────────────────────────────────
                        _buildSectionLabel('ONE-TIME GOALS'),
                        const SizedBox(height: 4),
                        Text(
                          'Tap a goal to set your target & calculate',
                          style: TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 10,
                              letterSpacing: 2,
                              color: AppColors.textMuted.withOpacity(0.3)),
                        ),
                        const SizedBox(height: 16),
                        _buildGoalGrid(),
                        if (_lastOneTimeResult != null) ...[
                          const SizedBox(height: 28),
                          _OneTimeResultCard(
                              data: _lastOneTimeResult!,
                              goalName: _lastOneTimeGoalName ?? 'GOAL'),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() => Container(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 20, height: 1, color: AppColors.green),
            const SizedBox(width: 10),
            Text('FINANCIAL GOALS',
                style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 9,
                    letterSpacing: 4,
                    color: AppColors.green.withOpacity(0.6))),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  border: Border.all(color: AppColors.green.withOpacity(0.3))),
              child: const Text('LIVE',
                  style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 8,
                      letterSpacing: 2,
                      color: AppColors.green)),
            ),
          ]),
          const SizedBox(height: 12),
          const Text('YOUR\nGOALS.',
              style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  height: 1.0,
                  color: Colors.white)),
        ]),
      );

  Widget _buildErrorBanner() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            border: Border.all(color: AppColors.error.withOpacity(0.4)),
            color: AppColors.error.withOpacity(0.06)),
        child: Row(children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.error, size: 16),
          const SizedBox(width: 10),
          Expanded(
              child: Text(_errorMsg!,
                  style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 10,
                      height: 1.5,
                      color: AppColors.error.withOpacity(0.8)))),
          GestureDetector(
              onTap: () => setState(() => _errorMsg = null),
              child: Icon(Icons.close,
                  color: AppColors.error.withOpacity(0.5), size: 16)),
        ]),
      );

  Widget _buildRetirementCard() => GestureDetector(
        onTap: _openRetirementSheet,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: AppColors.blackCard,
              border: Border.all(color: AppColors.green.withOpacity(0.3))),
          child: Row(children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                  border: Border.all(color: AppColors.green.withOpacity(0.4)),
                  color: AppColors.green.withOpacity(0.07)),
              child: const Icon(Icons.beach_access_outlined,
                  color: AppColors.green, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const Text('RETIREMENT PLANNER',
                      style: TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 12,
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(
                    _retirementResult != null
                        ? 'Plan calculated \u2713  \u2014  tap to recalculate'
                        : 'Set your retirement age & corpus target',
                    style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 10,
                        color: AppColors.textMuted.withOpacity(0.4)),
                  ),
                ])),
            Icon(Icons.arrow_forward_ios,
                size: 14, color: AppColors.green.withOpacity(0.5)),
          ]),
        ),
      );

  Widget _buildGoalGrid() => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _goalTemplates.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.35,
        ),
        itemBuilder: (_, i) => _GoalCard(
          template: _goalTemplates[i],
          onTap: () => _openOneTimeGoalSheet(_goalTemplates[i].title),
        ),
      );

  Widget _buildSectionLabel(String title) => Row(children: [
        Container(width: 20, height: 1, color: AppColors.green),
        const SizedBox(width: 10),
        Text(title,
            style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 10,
                letterSpacing: 4,
                color: AppColors.green.withOpacity(0.7))),
      ]);
}

// ── Goal Template & Card ───────────────────────────────────────────────────────
class _GoalTemplate {
  final IconData icon;
  final String title, tag;
  const _GoalTemplate(
      {required this.icon, required this.title, required this.tag});
}

class _GoalCard extends StatelessWidget {
  final _GoalTemplate template;
  final VoidCallback onTap;
  const _GoalCard({required this.template, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: AppColors.blackCard,
              border: Border.all(color: AppColors.green.withOpacity(0.12))),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Icon(template.icon, color: AppColors.green, size: 22),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                color: AppColors.green.withOpacity(0.08),
                child: Text(template.tag,
                    style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 7,
                        letterSpacing: 1,
                        color: AppColors.green.withOpacity(0.6))),
              ),
            ]),
            const Spacer(),
            Text(template.title,
                style: const TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 11,
                    letterSpacing: 1,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.3)),
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.add,
                  color: AppColors.green.withOpacity(0.6), size: 12),
              const SizedBox(width: 4),
              Text('SET GOAL',
                  style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 9,
                      letterSpacing: 2,
                      color: AppColors.green.withOpacity(0.5))),
            ]),
          ]),
        ),
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// ── Smart Result Cards ─────────────────────────────────────────────────────────
// ══════════════════════════════════════════════════════════════════════════════

// Formats a raw value intelligently: currency, percent, plain number, or string
String _formatValue(String key, dynamic raw) {
  if (raw == null) return '—';
  final str = raw.toString().trim();
  if (str.isEmpty || str == 'null') return '—';

  // Already formatted (starts with currency symbol etc.)
  if (str.startsWith('\$') || str.startsWith('₹') || str.startsWith('€'))
    return str;

  // Try numeric formatting
  final num? n = num.tryParse(str);
  if (n != null) {
    final lk = key.toLowerCase();
    // Percentage keys
    if (lk.contains('pct') ||
        lk.contains('rate') ||
        lk.contains('return') ||
        lk.contains('raise') ||
        lk.contains('yield') ||
        lk.contains('percent')) {
      return '${n.toStringAsFixed(1)}%';
    }
    // Large currency values
    if (lk.contains('corpus') ||
        lk.contains('amount') ||
        lk.contains('income') ||
        lk.contains('sip') ||
        lk.contains('value') ||
        lk.contains('savings') ||
        lk.contains('expense') ||
        lk.contains('cost') ||
        lk.contains('fund') ||
        lk.contains('target') ||
        lk.contains('shortfall') ||
        lk.contains('surplus')) {
      if (n.abs() >= 10000000) {
        return '\$${(n / 10000000).toStringAsFixed(2)}Cr';
      } else if (n.abs() >= 100000) {
        return '\$${(n / 100000).toStringAsFixed(2)}L';
      } else if (n.abs() >= 1000) {
        return '\$${(n / 1000).toStringAsFixed(1)}K';
      }
      return '\$${n.toStringAsFixed(0)}';
    }
    // Age / year keys
    if (lk.contains('age') || lk.contains('year') || lk.contains('duration')) {
      return n.toInt().toString();
    }
    // Generic number
    return n % 1 == 0 ? n.toInt().toString() : n.toStringAsFixed(2);
  }

  // Boolean-style
  if (str.toLowerCase() == 'true') return 'YES';
  if (str.toLowerCase() == 'false') return 'NO';

  return str;
}

// Converts snake_case key to readable label
String _labelFor(String key) => key.replaceAll('_', ' ').toUpperCase();

// Determines if a result row should be highlighted (primary outputs)
bool _isHighlightKey(String key) {
  final lk = key.toLowerCase();
  return lk.contains('required') ||
      lk.contains('monthly_sip') ||
      lk.contains('target') ||
      lk.contains('corpus') ||
      lk.contains('shortfall') ||
      lk.contains('surplus') ||
      lk.contains('recommended') ||
      lk == 'sip' ||
      lk == 'result' ||
      lk == 'status';
}

// ── Retirement Result Card ─────────────────────────────────────────────────────
class _RetirementResultCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _RetirementResultCard({required this.data});

  @override
  Widget build(BuildContext context) {
    // Separate highlighted (key outputs) from supporting rows
    final highlighted =
        data.entries.where((e) => _isHighlightKey(e.key)).toList();
    final supporting = data.entries
        .where((e) =>
            !_isHighlightKey(e.key) &&
            e.value != null &&
            e.value.toString().isNotEmpty)
        .toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Section label
      Row(children: [
        Container(width: 20, height: 1, color: AppColors.green),
        const SizedBox(width: 10),
        Text('RETIREMENT PLAN RESULT',
            style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 10,
                letterSpacing: 4,
                color: AppColors.green.withOpacity(0.7))),
      ]),
      const SizedBox(height: 12),

      // ── Hero metrics (highlighted keys) ───────────────────────────────────
      if (highlighted.isNotEmpty) ...[
        _buildHeroMetrics(highlighted),
        const SizedBox(height: 12),
      ],

      // ── Supporting details ─────────────────────────────────────────────────
      if (supporting.isNotEmpty)
        Container(
          decoration: BoxDecoration(
              color: AppColors.blackCard,
              border: Border.all(color: AppColors.green.withOpacity(0.12))),
          child: Column(
            children: supporting.asMap().entries.map((e) {
              final isLast = e.key == supporting.length - 1;
              return _ResultRow(
                label: _labelFor(e.value.key),
                value: _formatValue(e.value.key, e.value.value),
                isLast: isLast,
                highlight: false,
              );
            }).toList(),
          ),
        ),
    ]);
  }

  Widget _buildHeroMetrics(List<MapEntry<String, dynamic>> entries) {
    // Up to 2 per row
    final List<Widget> rows = [];
    for (int i = 0; i < entries.length; i += 2) {
      final left = entries[i];
      final right = i + 1 < entries.length ? entries[i + 1] : null;
      rows.add(Row(children: [
        Expanded(
            child: _HeroMetricTile(
                label: _labelFor(left.key),
                value: _formatValue(left.key, left.value))),
        const SizedBox(width: 12),
        Expanded(
            child: right != null
                ? _HeroMetricTile(
                    label: _labelFor(right.key),
                    value: _formatValue(right.key, right.value))
                : const SizedBox()),
      ]));
      if (i + 2 < entries.length) rows.add(const SizedBox(height: 12));
    }
    return Column(children: rows);
  }
}

// ── One-Time Goal Result Card ──────────────────────────────────────────────────
class _OneTimeResultCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String goalName;
  const _OneTimeResultCard({required this.data, required this.goalName});

  @override
  Widget build(BuildContext context) {
    final highlighted =
        data.entries.where((e) => _isHighlightKey(e.key)).toList();
    final supporting = data.entries
        .where((e) =>
            !_isHighlightKey(e.key) &&
            e.value != null &&
            e.value.toString().isNotEmpty)
        .toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 20, height: 1, color: AppColors.green),
        const SizedBox(width: 10),
        Expanded(
            child: Text('${goalName.toUpperCase()} — RESULT',
                style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 10,
                    letterSpacing: 4,
                    color: AppColors.green.withOpacity(0.7)))),
      ]),
      const SizedBox(height: 12),
      if (highlighted.isNotEmpty) ...[
        Column(
          children: [
            for (int i = 0; i < highlighted.length; i += 2)
              Padding(
                padding: EdgeInsets.only(
                    bottom: i + 2 < highlighted.length ? 12 : 0),
                child: Row(children: [
                  Expanded(
                      child: _HeroMetricTile(
                          label: _labelFor(highlighted[i].key),
                          value: _formatValue(
                              highlighted[i].key, highlighted[i].value))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: i + 1 < highlighted.length
                          ? _HeroMetricTile(
                              label: _labelFor(highlighted[i + 1].key),
                              value: _formatValue(highlighted[i + 1].key,
                                  highlighted[i + 1].value))
                          : const SizedBox()),
                ]),
              ),
          ],
        ),
        const SizedBox(height: 12),
      ],
      if (supporting.isNotEmpty)
        Container(
          decoration: BoxDecoration(
              color: AppColors.blackCard,
              border: Border.all(color: AppColors.green.withOpacity(0.12))),
          child: Column(
            children: supporting
                .asMap()
                .entries
                .map((e) => _ResultRow(
                      label: _labelFor(e.value.key),
                      value: _formatValue(e.value.key, e.value.value),
                      isLast: e.key == supporting.length - 1,
                      highlight: false,
                    ))
                .toList(),
          ),
        ),
    ]);
  }
}

// ── Hero Metric Tile ───────────────────────────────────────────────────────────
class _HeroMetricTile extends StatelessWidget {
  final String label, value;
  const _HeroMetricTile({required this.label, required this.value});

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
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.green,
                shadows: [
                  Shadow(color: AppColors.green.withOpacity(0.4), blurRadius: 8)
                ]),
          ),
        ]),
      );
}

// ── Result Row ─────────────────────────────────────────────────────────────────
class _ResultRow extends StatelessWidget {
  final String label, value;
  final bool isLast, highlight;
  const _ResultRow(
      {required this.label,
      required this.value,
      required this.isLast,
      this.highlight = false});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: isLast
            ? null
            : BoxDecoration(
                border: Border(
                    bottom:
                        BorderSide(color: AppColors.green.withOpacity(0.07)))),
        child: Row(children: [
          Expanded(
              flex: 3,
              child: Text(label,
                  style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 9,
                      letterSpacing: 1,
                      color: AppColors.textMuted.withOpacity(0.4)))),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Courier',
              fontSize: highlight ? 13 : 11,
              fontWeight: highlight ? FontWeight.w900 : FontWeight.bold,
              color: highlight
                  ? AppColors.green
                  : AppColors.textMuted.withOpacity(0.8),
            ),
          ),
        ]),
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// ── Retirement Goal Bottom Sheet ───────────────────────────────────────────────
// ══════════════════════════════════════════════════════════════════════════════
class _RetirementGoalSheet extends StatefulWidget {
  final UserProfile user;
  final Function(Map<String, dynamic>) onSubmit;
  final Function(String) onError;
  const _RetirementGoalSheet(
      {required this.user, required this.onSubmit, required this.onError});

  @override
  State<_RetirementGoalSheet> createState() => _RetirementGoalSheetState();
}

class _RetirementGoalSheetState extends State<_RetirementGoalSheet> {
  final _formKey = GlobalKey<FormState>();
  // Required fields (Form(...) in backend)
  final _retAgeCtrl = TextEditingController(text: '60');
  final _expPctCtrl = TextEditingController(text: '80');
  final _lifeCtrl = TextEditingController(text: '85');
  // Optional fields with backend defaults
  final _postRetReturnCtrl = TextEditingController(text: '7.0');
  final _preRetReturnCtrl = TextEditingController(text: '10.0');
  final _annualIncomeCtrl = TextEditingController(text: '0');
  final _corpusCtrl = TextEditingController(text: '0');
  final _sipCtrl = TextEditingController(text: '0');
  final _sipRaiseCtrl = TextEditingController(text: '0');

  bool _showAdvanced = false;
  bool _loading = false;

  @override
  void dispose() {
    _retAgeCtrl.dispose();
    _expPctCtrl.dispose();
    _lifeCtrl.dispose();
    _postRetReturnCtrl.dispose();
    _preRetReturnCtrl.dispose();
    _annualIncomeCtrl.dispose();
    _corpusCtrl.dispose();
    _sipCtrl.dispose();
    _sipRaiseCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final result = await ApiService.instance.postRetirementGoal(
        // Required
        retirementAge: int.parse(_retAgeCtrl.text),
        postRetirementExpensePct: double.parse(_expPctCtrl.text),
        lifeExpectancy: int.parse(_lifeCtrl.text),
        // Optional — map to backend defaults if blank
        postRetirementReturn: double.tryParse(_postRetReturnCtrl.text) ?? 7.0,
        preRetirementReturn: double.tryParse(_preRetReturnCtrl.text) ?? 10.0,
        annualPostRetirementIncome:
            double.tryParse(_annualIncomeCtrl.text) ?? 0,
        existingCorpus: double.tryParse(_corpusCtrl.text) ?? 0,
        existingMonthlySip: double.tryParse(_sipCtrl.text) ?? 0,
        sipRaisePct: double.tryParse(_sipRaiseCtrl.text) ?? 0,
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onSubmit(result);
      }
    } on ApiException catch (e) {
      if (mounted) {
        Navigator.pop(context);
        widget.onError(e.message);
      }
    } catch (_) {
      if (mounted) {
        Navigator.pop(context);
        widget.onError('Network error. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _SheetHeader(
                    title: 'RETIREMENT GOAL',
                    icon: Icons.beach_access_outlined),
                const SizedBox(height: 24),

                // ── Required fields ──────────────────────────────────────
                _SheetField(
                    label: 'RETIREMENT AGE',
                    ctrl: _retAgeCtrl,
                    hint: '60',
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      return (n == null || n < 35 || n > 80) ? '35–80' : null;
                    }),
                const SizedBox(height: 12),
                _SheetField(
                    label: 'POST-RETIREMENT EXPENSES (% of pre-retirement)',
                    ctrl: _expPctCtrl,
                    hint: '80',
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      return (n == null || n <= 0 || n > 100) ? '1–100' : null;
                    }),
                const SizedBox(height: 12),
                _SheetField(
                    label: 'LIFE EXPECTANCY',
                    ctrl: _lifeCtrl,
                    hint: '85',
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      return (n == null || n < 60 || n > 100) ? '60–100' : null;
                    }),
                const SizedBox(height: 20),

                // ── Existing savings ─────────────────────────────────────
                _SheetSectionDivider(label: 'EXISTING SAVINGS'),
                const SizedBox(height: 12),
                _SheetField(
                    label: 'EXISTING CORPUS',
                    ctrl: _corpusCtrl,
                    hint: '0',
                    required: false),
                const SizedBox(height: 12),
                _SheetField(
                    label: 'EXISTING MONTHLY SIP',
                    ctrl: _sipCtrl,
                    hint: '0',
                    required: false),
                const SizedBox(height: 12),
                _SheetField(
                    label: 'ANNUAL SIP STEP-UP (%)',
                    ctrl: _sipRaiseCtrl,
                    hint: '0',
                    required: false),
                const SizedBox(height: 20),

                // ── Advanced toggle ──────────────────────────────────────
                GestureDetector(
                  onTap: () => setState(() => _showAdvanced = !_showAdvanced),
                  child: Row(children: [
                    Icon(
                        _showAdvanced
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: AppColors.green.withOpacity(0.5),
                        size: 16),
                    const SizedBox(width: 8),
                    Text('ADVANCED ASSUMPTIONS',
                        style: TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 9,
                            letterSpacing: 3,
                            color: AppColors.green.withOpacity(0.5))),
                  ]),
                ),
                if (_showAdvanced) ...[
                  const SizedBox(height: 16),
                  _SheetField(
                      label: 'PRE-RETIREMENT RETURN (% p.a.)',
                      ctrl: _preRetReturnCtrl,
                      hint: '10.0',
                      validator: (v) {
                        final n = double.tryParse(v ?? '');
                        return (n == null || n <= 0 || n > 20)
                            ? '0.1–20'
                            : null;
                      }),
                  const SizedBox(height: 12),
                  _SheetField(
                      label: 'POST-RETIREMENT RETURN (% p.a.)',
                      ctrl: _postRetReturnCtrl,
                      hint: '7.0',
                      validator: (v) {
                        final n = double.tryParse(v ?? '');
                        return (n == null || n <= 0 || n > 20)
                            ? '0.1–20'
                            : null;
                      }),
                  const SizedBox(height: 12),
                  _SheetField(
                      label: 'ANNUAL POST-RETIREMENT INCOME (pension, rent...)',
                      ctrl: _annualIncomeCtrl,
                      hint: '0',
                      required: false),
                ],

                const SizedBox(height: 24),
                _SheetSubmitButton(
                    label: 'CALCULATE RETIREMENT PLAN',
                    loading: _loading,
                    onTap: _submit),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// ── One-Time Goal Bottom Sheet ─────────────────────────────────────────────────
// ══════════════════════════════════════════════════════════════════════════════
class _OneTimeGoalSheet extends StatefulWidget {
  final String goalName;
  final UserProfile user;
  final Function(Map<String, dynamic>) onSubmit;
  final Function(String) onError;
  const _OneTimeGoalSheet(
      {required this.goalName,
      required this.user,
      required this.onSubmit,
      required this.onError});

  @override
  State<_OneTimeGoalSheet> createState() => _OneTimeGoalSheetState();
}

class _OneTimeGoalSheetState extends State<_OneTimeGoalSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _yearsCtrl = TextEditingController();
  final _returnCtrl = TextEditingController(text: '10.0');
  final _corpusCtrl = TextEditingController(text: '0');
  final _sipCtrl = TextEditingController(text: '0');
  String _risk = 'moderate';
  bool _showAdvanced = false;
  bool _loading = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _yearsCtrl.dispose();
    _returnCtrl.dispose();
    _corpusCtrl.dispose();
    _sipCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final result = await ApiService.instance.postOneTimeGoal(
        goalName: widget.goalName,
        goalAmount: double.parse(_amountCtrl.text),
        yearsToGoal: double.parse(_yearsCtrl.text),
        preRetReturn: double.tryParse(_returnCtrl.text) ?? 10.0,
        existingCorpus: double.tryParse(_corpusCtrl.text) ?? 0,
        existingMonthlySip: double.tryParse(_sipCtrl.text) ?? 0,
        riskTolerance: _risk,
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onSubmit(result);
      }
    } on ApiException catch (e) {
      if (mounted) {
        Navigator.pop(context);
        widget.onError(e.message);
      }
    } catch (_) {
      if (mounted) {
        Navigator.pop(context);
        widget.onError('Network error. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _SheetHeader(title: widget.goalName, icon: Icons.flag_outlined),
                const SizedBox(height: 24),

                _SheetField(
                    label: 'GOAL AMOUNT IN TODAY\'S VALUE',
                    ctrl: _amountCtrl,
                    hint: 'e.g. 5000000',
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      return (n == null || n <= 0)
                          ? 'Enter a valid amount'
                          : null;
                    }),
                const SizedBox(height: 12),
                _SheetField(
                    label: 'YEARS TO GOAL',
                    ctrl: _yearsCtrl,
                    hint: 'e.g. 5',
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      return (n == null || n <= 0 || n > 50)
                          ? '1–50 years'
                          : null;
                    }),
                const SizedBox(height: 20),

                _SheetSectionDivider(label: 'EXISTING SAVINGS'),
                const SizedBox(height: 12),
                _SheetField(
                    label: 'EXISTING SAVINGS FOR THIS GOAL',
                    ctrl: _corpusCtrl,
                    hint: '0',
                    required: false),
                const SizedBox(height: 12),
                _SheetField(
                    label: 'EXISTING MONTHLY SIP FOR THIS GOAL',
                    ctrl: _sipCtrl,
                    hint: '0',
                    required: false),
                const SizedBox(height: 20),

                // Risk tolerance selector
                Text('RISK TOLERANCE',
                    style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 9,
                        letterSpacing: 3,
                        color: AppColors.green.withOpacity(0.6))),
                const SizedBox(height: 10),
                Row(
                  children: ['low', 'moderate', 'high'].map((r) {
                    final sel = _risk == r;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _risk = r),
                        child: Container(
                          margin: EdgeInsets.only(right: r != 'high' ? 8 : 0),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: sel
                                ? AppColors.green.withOpacity(0.12)
                                : Colors.transparent,
                            border: Border.all(
                                color: sel
                                    ? AppColors.green
                                    : AppColors.textMuted.withOpacity(0.15)),
                          ),
                          child: Center(
                              child: Text(r.toUpperCase(),
                                  style: TextStyle(
                                      fontFamily: 'Courier',
                                      fontSize: 9,
                                      letterSpacing: 2,
                                      color: sel
                                          ? AppColors.green
                                          : AppColors.textMuted
                                              .withOpacity(0.4),
                                      fontWeight: sel
                                          ? FontWeight.bold
                                          : FontWeight.normal))),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Advanced
                GestureDetector(
                  onTap: () => setState(() => _showAdvanced = !_showAdvanced),
                  child: Row(children: [
                    Icon(
                        _showAdvanced
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: AppColors.green.withOpacity(0.5),
                        size: 16),
                    const SizedBox(width: 8),
                    Text('ADVANCED ASSUMPTIONS',
                        style: TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 9,
                            letterSpacing: 3,
                            color: AppColors.green.withOpacity(0.5))),
                  ]),
                ),
                if (_showAdvanced) ...[
                  const SizedBox(height: 16),
                  _SheetField(
                      label: 'EXPECTED RETURN (% p.a.)',
                      ctrl: _returnCtrl,
                      hint: '10.0',
                      validator: (v) {
                        final n = double.tryParse(v ?? '');
                        return (n == null || n <= 0 || n > 20)
                            ? '0.1–20'
                            : null;
                      }),
                ],

                const SizedBox(height: 24),
                _SheetSubmitButton(
                    label: 'CALCULATE GOAL PLAN',
                    loading: _loading,
                    onTap: _submit),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      );
}

// ── Shared Sheet Widgets ───────────────────────────────────────────────────────
class _SheetHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SheetHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, color: AppColors.green, size: 22),
        const SizedBox(width: 12),
        Expanded(
            child: Text(title,
                style: const TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 14,
                    letterSpacing: 3,
                    fontWeight: FontWeight.bold,
                    color: Colors.white))),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Icon(Icons.close,
              color: AppColors.textMuted.withOpacity(0.3), size: 20),
        ),
      ]);
}

class _SheetSectionDivider extends StatelessWidget {
  final String label;
  const _SheetSectionDivider({required this.label});

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
            width: 12, height: 1, color: AppColors.green.withOpacity(0.3)),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 8,
                letterSpacing: 3,
                color: AppColors.textMuted.withOpacity(0.35))),
        const SizedBox(width: 8),
        Expanded(
            child:
                Container(height: 1, color: AppColors.green.withOpacity(0.08))),
      ]);
}

class _SheetField extends StatelessWidget {
  final String label, hint;
  final TextEditingController ctrl;
  final String? Function(String?)? validator;
  final bool required;
  const _SheetField(
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

class _SheetSubmitButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onTap;
  const _SheetSubmitButton(
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
                : Text(label,
                    style: const TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 11,
                        letterSpacing: 3,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black)),
          ),
        ),
      );
}
