// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'app_theme.dart';

// ══════════════════════════════════════════════════════════════════════════════
// ── GlidePathWidget ────────────────────────────────────────────────────────────
//
// Usage:
//   import 'widget_glide_path.dart';
//   GlidePathWidget(raw: plan['glide_path'])
//
// Accepts any backend shape:
//   • List<Map>  [{year, age, equity_pct, debt_pct}, ...]
//   • List<Map>  [{year, age, equity_percent, debt_percent}, ...]
//   • List<Map>  [{year, age, equity_allocation, debt_allocation}, ...]
//   • Map        {'glide_path': List<Map>}
//   • Map        {age: {equity, debt}, ...}  (age-keyed)
//   • null       → renders nothing
// ══════════════════════════════════════════════════════════════════════════════

class GlidePathWidget extends StatefulWidget {
  /// The raw value of plan['glide_path'] — List, Map, or null.
  final dynamic raw;

  /// Optional title override. Defaults to 'EQUITY GLIDE PATH'.
  final String? title;

  const GlidePathWidget({super.key, required this.raw, this.title});

  @override
  State<GlidePathWidget> createState() => _GlidePathWidgetState();
}

class _GlidePathWidgetState extends State<GlidePathWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _progress;
  bool _showTable = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _progress = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ── Parse any backend shape ───────────────────────────────────────────────
  List<GlideRow> _parse() {
    final raw = widget.raw;
    if (raw == null) return [];

    if (raw is List) {
      return _fromList(raw);
    }
    if (raw is Map) {
      final m = Map<String, dynamic>.from(raw);
      // Shape: {'glide_path': [...]}
      if (m['glide_path'] is List) return _fromList(m['glide_path'] as List);
      // Shape: {30: {equity: 80, debt: 20}, 31: ...}  (age-keyed)
      final rows = <GlideRow>[];
      m.forEach((k, v) {
        if (v is Map) {
          final vm = Map<String, dynamic>.from(v);
          final keyNum = num.tryParse(k.toString());
          if (keyNum != null) vm['_age_key'] = keyNum.toInt();
          rows.add(GlideRow.fromMap(vm));
        }
      });
      return rows.where((r) => r.equity > 0 || r.debt > 0).toList();
    }
    return [];
  }

  List<GlideRow> _fromList(List raw) => raw
      .whereType<Map>()
      .map((m) => GlideRow.fromMap(Map<String, dynamic>.from(m)))
      .where((r) => r.equity > 0 || r.debt > 0)
      .toList();

  @override
  Widget build(BuildContext context) {
    final rows = _parse();
    if (rows.isEmpty) return const SizedBox();

    final first = rows.first;
    final last = rows.last;
    final mid = rows[rows.length ~/ 2];
    final equityDrop = (first.equity - last.equity).abs();
    final debtRise = (last.debt - first.debt).abs();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // ── Header ─────────────────────────────────────────────────────────────
      _GpSectionHeader(
        title: widget.title ?? 'EQUITY GLIDE PATH',
        badge: '${rows.length} YRS',
      ),
      const SizedBox(height: 14),

      // ── Start → Mid → End pill row ─────────────────────────────────────────
      _MilestonePills(first: first, mid: mid, last: last),
      const SizedBox(height: 16),

      // ── Animated stacked bar chart ─────────────────────────────────────────
      _AnimatedBarChart(rows: rows, progress: _progress),
      const SizedBox(height: 14),

      // ── Shift summary strip ────────────────────────────────────────────────
      _ShiftSummaryStrip(
        equityDrop: equityDrop,
        debtRise: debtRise,
        years: rows.length,
      ),
      const SizedBox(height: 12),

      // ── Blended return estimate ────────────────────────────────────────────
      _BlendedReturnEstimate(first: first, last: last),
      const SizedBox(height: 12),

      // ── Toggle table ───────────────────────────────────────────────────────
      GestureDetector(
        onTap: () => setState(() => _showTable = !_showTable),
        child: Row(children: [
          Icon(_showTable ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: AppColors.green.withOpacity(0.4), size: 14),
          const SizedBox(width: 6),
          Text(
              _showTable
                  ? 'HIDE YEAR-BY-YEAR TABLE'
                  : 'VIEW YEAR-BY-YEAR TABLE',
              style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 8,
                  letterSpacing: 2,
                  color: AppColors.green.withOpacity(0.45))),
        ]),
      ),

      // ── Full year-by-year table ────────────────────────────────────────────
      if (_showTable) ...[
        const SizedBox(height: 10),
        _GlideTable(rows: rows),
      ],
    ]);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ── Sub-widgets ────────────────────────────────────────────────────────────────
// ══════════════════════════════════════════════════════════════════════════════

class _GpSectionHeader extends StatelessWidget {
  final String title, badge;
  const _GpSectionHeader({required this.title, required this.badge});
  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
            width: 12, height: 1, color: AppColors.green.withOpacity(0.45)),
        const SizedBox(width: 8),
        Text(title,
            style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 9,
                letterSpacing: 3,
                color: AppColors.green.withOpacity(0.6))),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
              border: Border.all(color: AppColors.green.withOpacity(0.2))),
          child: Text(badge,
              style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 7,
                  color: AppColors.green.withOpacity(0.5))),
        ),
      ]);
}

// ── Three milestone pills: START → MID → END ──────────────────────────────────
class _MilestonePills extends StatelessWidget {
  final GlideRow first, mid, last;
  const _MilestonePills(
      {required this.first, required this.mid, required this.last});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
            color: AppColors.blackCard,
            border: Border.all(color: AppColors.green.withOpacity(0.12))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          _Pill(
              ageLabel: first.ageLabel,
              equityPct: first.equity,
              debtPct: first.debt,
              subLabel: 'START',
              color: AppColors.green),
          _PillArrow(),
          _Pill(
              ageLabel: mid.ageLabel,
              equityPct: mid.equity,
              debtPct: mid.debt,
              subLabel: 'MID',
              color: AppColors.green.withOpacity(0.6)),
          _PillArrow(),
          _Pill(
              ageLabel: last.ageLabel,
              equityPct: last.equity,
              debtPct: last.debt,
              subLabel: 'END',
              color: AppColors.textMuted.withOpacity(0.55)),
        ]),
      );
}

class _Pill extends StatelessWidget {
  final String ageLabel, subLabel;
  final double equityPct, debtPct;
  final Color color;
  const _Pill({
    required this.ageLabel,
    required this.equityPct,
    required this.debtPct,
    required this.subLabel,
    required this.color,
  });

  @override
  Widget build(BuildContext context) =>
      Column(mainAxisSize: MainAxisSize.min, children: [
        Text(ageLabel,
            style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 7,
                color: AppColors.textMuted.withOpacity(0.35))),
        const SizedBox(height: 6),
        // Mini donut-like segmented bar
        SizedBox(
          width: 48,
          child: Column(children: [
            Row(children: [
              Expanded(
                flex: equityPct.round().clamp(1, 99),
                child: Container(height: 8, color: color),
              ),
              Expanded(
                flex: debtPct.round().clamp(1, 99),
                child: Container(
                    height: 8, color: AppColors.textMuted.withOpacity(0.2)),
              ),
            ]),
            const SizedBox(height: 5),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('E ${equityPct.toStringAsFixed(0)}%',
                  style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 7,
                      fontWeight: FontWeight.bold,
                      color: color)),
              Text('D ${debtPct.toStringAsFixed(0)}%',
                  style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 7,
                      color: AppColors.textMuted.withOpacity(0.4))),
            ]),
          ]),
        ),
        const SizedBox(height: 4),
        Text(subLabel,
            style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 7,
                letterSpacing: 2,
                color: AppColors.textMuted.withOpacity(0.3))),
      ]);
}

class _PillArrow extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          Container(height: 1, color: AppColors.textMuted.withOpacity(0.12)),
          const SizedBox(height: 3),
          Text('→',
              style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 9,
                  color: AppColors.textMuted.withOpacity(0.15))),
        ]),
      );
}

// ── Animated stacked bar chart ─────────────────────────────────────────────────
class _AnimatedBarChart extends StatelessWidget {
  final List<GlideRow> rows;
  final Animation<double> progress;
  const _AnimatedBarChart({required this.rows, required this.progress});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        decoration: BoxDecoration(
            color: AppColors.blackCard,
            border: Border.all(color: AppColors.green.withOpacity(0.1))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Legend
          Row(children: [
            _ChartLegend(color: AppColors.green, label: 'EQUITY'),
            const SizedBox(width: 16),
            _ChartLegend(
                color: AppColors.textMuted.withOpacity(0.3), label: 'DEBT'),
            const Spacer(),
            Text('1 bar = 1 year',
                style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 7,
                    color: AppColors.textMuted.withOpacity(0.2))),
          ]),
          const SizedBox(height: 10),

          // Bars
          AnimatedBuilder(
            animation: progress,
            builder: (_, __) => SizedBox(
              height: 90,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: rows.asMap().entries.map((e) {
                  final r = e.value;
                  final eq = (r.equity / 100 * progress.value).clamp(0.0, 1.0);
                  final dt = (r.debt / 100 * progress.value).clamp(0.0, 1.0);
                  final isKey = e.key == 0 ||
                      e.key == rows.length - 1 ||
                      (r.year != null && r.year! % 5 == 0) ||
                      (r.age != null && r.age! % 5 == 0);
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0.5),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                              height: 90 * eq,
                              color: isKey
                                  ? AppColors.green
                                  : AppColors.green.withOpacity(0.5)),
                          Container(
                              height: 90 * dt,
                              color: AppColors.textMuted
                                  .withOpacity(isKey ? 0.35 : 0.18)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 6),

          // X-axis labels
          Row(children: [
            Text(rows.first.ageLabel,
                style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 7,
                    color: AppColors.textMuted.withOpacity(0.35))),
            const Spacer(),
            Text(rows[rows.length ~/ 2].ageLabel,
                style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 7,
                    color: AppColors.textMuted.withOpacity(0.25))),
            const Spacer(),
            Text(rows.last.ageLabel,
                style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 7,
                    color: AppColors.textMuted.withOpacity(0.35))),
          ]),
        ]),
      );
}

class _ChartLegend extends StatelessWidget {
  final Color color;
  final String label;
  const _ChartLegend({required this.color, required this.label});
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 8, height: 8, color: color),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 7,
                letterSpacing: 1,
                color: AppColors.textMuted.withOpacity(0.4))),
      ]);
}

// ── Shift summary strip ────────────────────────────────────────────────────────
class _ShiftSummaryStrip extends StatelessWidget {
  final double equityDrop, debtRise;
  final int years;
  const _ShiftSummaryStrip(
      {required this.equityDrop, required this.debtRise, required this.years});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
            color: AppColors.blackMid,
            border: Border.all(color: AppColors.green.withOpacity(0.08))),
        child: Row(children: [
          _ShiftCell(
              label: 'EQUITY REDUCES BY',
              value: '${equityDrop.toStringAsFixed(0)}%',
              color: AppColors.green),
          Container(
              width: 1, height: 44, color: AppColors.green.withOpacity(0.08)),
          _ShiftCell(
              label: 'DEBT GROWS BY',
              value: '${debtRise.toStringAsFixed(0)}%',
              color: AppColors.textMuted.withOpacity(0.6)),
          Container(
              width: 1, height: 44, color: AppColors.green.withOpacity(0.08)),
          _ShiftCell(
              label: 'INVESTMENT HORIZON',
              value: '$years YRS',
              color: Colors.white),
        ]),
      );
}

class _ShiftCell extends StatelessWidget {
  final String label, value;
  final Color color;
  const _ShiftCell(
      {required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 7,
                    letterSpacing: 0.5,
                    color: AppColors.textMuted.withOpacity(0.3))),
            const SizedBox(height: 5),
            Text(value,
                style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: color)),
          ]),
        ),
      );
}

// ── Blended return estimate ────────────────────────────────────────────────────
// Estimates avg blended return across the glide path assuming
// equity ≈ 12% and debt ≈ 7% (standard Indian market assumptions).
class _BlendedReturnEstimate extends StatelessWidget {
  final GlideRow first, last;
  const _BlendedReturnEstimate({required this.first, required this.last});

  double _blended(double eq) => (eq / 100 * 12) + ((100 - eq) / 100 * 7);

  @override
  Widget build(BuildContext context) {
    final startBlend = _blended(first.equity);
    final endBlend = _blended(last.equity);
    final avgBlend = (startBlend + endBlend) / 2;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: AppColors.green.withOpacity(0.04),
          border: Border.all(color: AppColors.green.withOpacity(0.12))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.info_outline,
              size: 12, color: AppColors.green.withOpacity(0.4)),
          const SizedBox(width: 6),
          Text('ESTIMATED BLENDED RETURNS',
              style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 8,
                  letterSpacing: 2,
                  color: AppColors.green.withOpacity(0.5))),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          _BlendStat(
              label: 'AT START', value: '${startBlend.toStringAsFixed(1)}%'),
          const SizedBox(width: 12),
          _BlendStat(label: 'AT END', value: '${endBlend.toStringAsFixed(1)}%'),
          const SizedBox(width: 12),
          _BlendStat(
              label: 'AVG',
              value: '${avgBlend.toStringAsFixed(1)}%',
              highlight: true),
        ]),
        const SizedBox(height: 8),
        Text('Based on 12% equity / 7% debt assumptions',
            style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 7,
                color: AppColors.textMuted.withOpacity(0.25))),
      ]),
    );
  }
}

class _BlendStat extends StatelessWidget {
  final String label, value;
  final bool highlight;
  const _BlendStat(
      {required this.label, required this.value, this.highlight = false});
  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
              color: highlight
                  ? AppColors.green.withOpacity(0.1)
                  : AppColors.blackMid,
              border: Border.all(
                  color: highlight
                      ? AppColors.green.withOpacity(0.35)
                      : AppColors.green.withOpacity(0.08))),
          child: Column(children: [
            Text(label,
                style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 7,
                    color: AppColors.textMuted.withOpacity(0.35))),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: highlight ? AppColors.green : Colors.white)),
          ]),
        ),
      );
}

// ── Full scrollable year-by-year table ────────────────────────────────────────
class _GlideTable extends StatelessWidget {
  final List<GlideRow> rows;
  const _GlideTable({required this.rows});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
            border: Border.all(color: AppColors.green.withOpacity(0.1))),
        child: Column(children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: AppColors.green.withOpacity(0.05),
            child: Row(children: [
              _TH('YR', flex: 2),
              _TH('AGE', flex: 2),
              _TH('EQUITY', flex: 3),
              _TH('DEBT', flex: 3),
              _TH('SPLIT', flex: 5),
            ]),
          ),
          // Data rows
          ...rows.asMap().entries.map((e) {
            final r = e.value;
            final isLast = e.key == rows.length - 1;
            final eq = r.equity.round().clamp(1, 99);
            final dt = (100 - eq).clamp(1, 99);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: isLast
                  ? null
                  : BoxDecoration(
                      border: Border(
                          bottom: BorderSide(
                              color: AppColors.green.withOpacity(0.05)))),
              child: Row(children: [
                _TD(r.year?.toString() ?? '—', flex: 2),
                _TD(r.age != null ? '${r.age}' : '—',
                    flex: 2, color: AppColors.textMuted.withOpacity(0.5)),
                _TD('${r.equity.toStringAsFixed(0)}%',
                    flex: 3, color: AppColors.green.withOpacity(0.85)),
                _TD('${r.debt.toStringAsFixed(0)}%',
                    flex: 3, color: AppColors.textMuted.withOpacity(0.55)),
                // Inline mini bar
                Expanded(
                    flex: 5,
                    child: Row(children: [
                      Expanded(
                        flex: eq,
                        child: Container(
                            height: 6, color: AppColors.green.withOpacity(0.7)),
                      ),
                      Expanded(
                        flex: dt,
                        child: Container(
                            height: 6,
                            color: AppColors.textMuted.withOpacity(0.2)),
                      ),
                    ])),
              ]),
            );
          }),
        ]),
      );
}

class _TH extends StatelessWidget {
  final String text;
  final int flex;
  const _TH(this.text, {this.flex = 1});
  @override
  Widget build(BuildContext context) => Expanded(
      flex: flex,
      child: Text(text,
          style: TextStyle(
              fontFamily: 'Courier',
              fontSize: 7,
              letterSpacing: 1,
              color: AppColors.green.withOpacity(0.45))));
}

class _TD extends StatelessWidget {
  final String text;
  final int flex;
  final Color? color;
  const _TD(this.text, {this.flex = 1, this.color});
  @override
  Widget build(BuildContext context) => Expanded(
      flex: flex,
      child: Text(text,
          style: TextStyle(
              fontFamily: 'Courier',
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: color ?? AppColors.textMuted.withOpacity(0.7))));
}

// ══════════════════════════════════════════════════════════════════════════════
// ── GlideRow data model ────────────────────────────────────────────────────────
// ══════════════════════════════════════════════════════════════════════════════
class GlideRow {
  final int? year;
  final int? age;
  final double equity; // 0–100
  final double debt; // 0–100

  const GlideRow(
      {this.year, this.age, required this.equity, required this.debt});

  String get ageLabel {
    if (age != null) return 'AGE $age';
    if (year != null) return 'YR $year';
    return '—';
  }

  factory GlideRow.fromMap(Map<String, dynamic> m) {
    int? year;
    int? age;
    double equity = 0;
    double debt = 0;

    m.forEach((k, v) {
      final lk = k.toLowerCase().trim();
      final n = num.tryParse(v?.toString() ?? '')?.toDouble() ?? 0;

      if (lk == 'year' || lk == 'yr') year = n.toInt();
      if (lk == 'age') age = n.toInt();
      if (lk == '_age_key') age = (v as int?) ?? n.toInt();

      // Equity keys — handle both pct (0–100) and ratio (0–1)
      if (lk == 'equity_pct' ||
          lk == 'equity_percent' ||
          lk == 'equity_allocation' ||
          lk == 'equity_ratio' ||
          lk == 'equity') {
        equity = n > 1 ? n : n * 100;
      }

      // Debt keys
      if (lk == 'debt_pct' ||
          lk == 'debt_percent' ||
          lk == 'debt_allocation' ||
          lk == 'debt_ratio' ||
          lk == 'debt' ||
          lk == 'bond_pct' ||
          lk == 'bonds') {
        debt = n > 1 ? n : n * 100;
      }
    });

    // Infer debt from equity if missing
    if (debt == 0 && equity > 0) debt = 100 - equity;
    // Infer equity from debt if missing
    if (equity == 0 && debt > 0) equity = 100 - debt;

    return GlideRow(year: year, age: age, equity: equity, debt: debt);
  }
}
