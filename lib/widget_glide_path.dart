// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'package:flutter/material.dart';
import 'app_theme.dart';

// ══════════════════════════════════════════════════════════════════════════════
// ── GlidePathWidget ────────────────────────────────────────────────────────────
//
// Usage:  GlidePathWidget(raw: plan['glide_path'])
//
// Handles ALL backend shapes:
//   • List<Map>  [{year, age, equity_pct, debt_pct}, ...]
//   • Map        {'glide_path': [...]}
//   • Map        {30: {equity:80, debt:20}, ...}   (age-keyed)
//   • String     JSON-encoded version of any of the above
//   • null       → renders nothing
// ══════════════════════════════════════════════════════════════════════════════

class GlidePathWidget extends StatefulWidget {
  final dynamic raw;
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
  List<GlideRow> _rows = [];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _progress = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _rows = _parse(widget.raw);
    // Animate after a short delay so the card expand finishes first
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) _ctrl.forward(from: 0);
    });
  }

  @override
  void didUpdateWidget(GlidePathWidget old) {
    super.didUpdateWidget(old);
    if (old.raw != widget.raw) {
      _rows = _parse(widget.raw);
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ── Universal parser — handles every known backend shape ──────────────────
  static List<GlideRow> _parse(dynamic raw) {
    if (raw == null) return [];

    // Unwrap JSON strings (backend stores plan_data as a JSON string)
    if (raw is String) {
      try {
        raw = jsonDecode(raw);
      } catch (_) {
        return [];
      }
    }

    if (raw is List) return _fromList(raw);

    if (raw is Map) {
      final m = Map<String, dynamic>.from(raw);

      // Shape: {'glide_path': [...]}
      if (m['glide_path'] is List) return _fromList(m['glide_path'] as List);
      if (m['glide_path'] is String) {
        try {
          final decoded = jsonDecode(m['glide_path'] as String);
          if (decoded is List) return _fromList(decoded);
        } catch (_) {}
      }

      // Shape: {30: {equity:80, debt:20}, 31: ...}  (age-keyed map)
      final rows = <GlideRow>[];
      m.forEach((k, v) {
        if (v is Map) {
          final vm = Map<String, dynamic>.from(v);
          final keyNum = num.tryParse(k.toString());
          if (keyNum != null) vm['_age_key'] = keyNum.toInt();
          final r = GlideRow.fromMap(vm);
          if (r.equity > 0 || r.debt > 0) rows.add(r);
        }
      });
      return rows;
    }

    return [];
  }

  static List<GlideRow> _fromList(List raw) => raw
      .whereType<Map>()
      .map((m) => GlideRow.fromMap(Map<String, dynamic>.from(m)))
      .where((r) => r.equity > 0 || r.debt > 0)
      .toList();

  double _blended(double eq) => (eq / 100 * 12) + ((100 - eq) / 100 * 7);

  @override
  Widget build(BuildContext context) {
    if (_rows.isEmpty) return const SizedBox();

    final rows = _rows;
    final first = rows.first;
    final last = rows.last;
    final equityDrop = (first.equity - last.equity).abs();
    final retStart = _blended(first.equity);
    final retEnd = _blended(last.equity);
    final retAvg = (retStart + retEnd) / 2;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // ── Header ─────────────────────────────────────────────────────────────
      _SectionHeader(
        title: widget.title ?? 'Equity glide path',
        badge: '${rows.length - 1} yrs',
      ),
      const SizedBox(height: 16),

      // ── 3 metric cards ─────────────────────────────────────────────────────
      Row(children: [
        _MetricCard(
          label: 'Starting allocation',
          value: '${first.equity.toStringAsFixed(0)}%',
          sub: 'equity at ${first.ageLabel.toLowerCase()}',
          valueColor: AppColors.green,
        ),
        const SizedBox(width: 10),
        _MetricCard(
          label: 'Equity reduction',
          value: '${equityDrop.toStringAsFixed(0)}%',
          sub: 'over the period',
        ),
        const SizedBox(width: 10),
        _MetricCard(
          label: 'Final allocation',
          value: '${last.equity.toStringAsFixed(0)}%',
          sub: 'equity at ${last.ageLabel.toLowerCase()}',
          valueColor: AppColors.textMuted.withOpacity(0.7),
        ),
      ]),
      const SizedBox(height: 16),

      // ── Legend ─────────────────────────────────────────────────────────────
      Row(children: [
        _LegendDot(color: AppColors.green, label: 'Equity'),
        const SizedBox(width: 16),
        _LegendDot(
            color: AppColors.textMuted.withOpacity(0.4),
            label: 'Debt',
            dashed: true),
      ]),
      const SizedBox(height: 10),

      // ── Animated stacked area chart ────────────────────────────────────────
      // FIX: Use LayoutBuilder so CustomPaint gets bounded constraints
      Container(
        decoration: BoxDecoration(
          color: AppColors.blackCard,
          border: Border.all(color: AppColors.green.withOpacity(0.1)),
        ),
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // FIX: LayoutBuilder gives CustomPaint a real bounded width
          LayoutBuilder(
            builder: (context, constraints) => AnimatedBuilder(
              animation: _progress,
              builder: (_, __) => SizedBox(
                width: constraints.maxWidth,
                height: 180,
                child: CustomPaint(
                  painter: _AreaChartPainter(
                    rows: rows,
                    progress: _progress.value,
                    equityColor: AppColors.green,
                    debtColor: AppColors.textMuted,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // X-axis labels
          Row(children: [
            Text(rows.first.ageLabel,
                style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 8,
                    color: AppColors.textMuted.withOpacity(0.4))),
            const Spacer(),
            Text(rows[rows.length ~/ 2].ageLabel,
                style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 8,
                    color: AppColors.textMuted.withOpacity(0.3))),
            const Spacer(),
            Text(rows.last.ageLabel,
                style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 8,
                    color: AppColors.textMuted.withOpacity(0.4))),
          ]),
        ]),
      ),
      const SizedBox(height: 16),

      // ── Blended return cards ───────────────────────────────────────────────
      Row(children: [
        _ReturnCard(
            label: 'Blended return\nat start',
            value: '${retStart.toStringAsFixed(1)}%'),
        const SizedBox(width: 10),
        _ReturnCard(
            label: 'Blended return\nat end',
            value: '${retEnd.toStringAsFixed(1)}%'),
        const SizedBox(width: 10),
        _ReturnCard(
            label: 'Avg blended\nreturn',
            value: '${retAvg.toStringAsFixed(1)}%',
            highlight: true),
      ]),
      const SizedBox(height: 6),
      Text('Based on 12% equity / 7% debt (Indian market assumptions)',
          style: TextStyle(
              fontFamily: 'Courier',
              fontSize: 8,
              color: AppColors.textMuted.withOpacity(0.28))),
      const SizedBox(height: 14),

      // ── Toggle table ───────────────────────────────────────────────────────
      GestureDetector(
        onTap: () => setState(() => _showTable = !_showTable),
        child: Row(children: [
          Icon(_showTable ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: AppColors.green.withOpacity(0.4), size: 14),
          const SizedBox(width: 6),
          Text(
              _showTable
                  ? 'Hide year-by-year table'
                  : 'View year-by-year table',
              style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 9,
                  letterSpacing: 1.5,
                  color: AppColors.green.withOpacity(0.45))),
        ]),
      ),

      if (_showTable) ...[
        const SizedBox(height: 10),
        _GlideTable(rows: rows),
      ],
    ]);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ── Custom Painter ─────────────────────────────────────────────────────────────
// ══════════════════════════════════════════════════════════════════════════════
class _AreaChartPainter extends CustomPainter {
  final List<GlideRow> rows;
  final double progress;
  final Color equityColor;
  final Color debtColor;

  _AreaChartPainter({
    required this.rows,
    required this.progress,
    required this.equityColor,
    required this.debtColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (rows.isEmpty || size.width <= 0 || size.height <= 0) return;

    final w = size.width;
    final h = size.height;
    final n = rows.length;
    final leftPad = 28.0;
    final chartW = w - leftPad;

    // ── Y-axis grid + labels ───────────────────────────────────────────────
    final gridPaint = Paint()
      ..color = equityColor.withOpacity(0.07)
      ..strokeWidth = 0.5;
    final labelStyle = TextStyle(
        fontFamily: 'Courier', fontSize: 8, color: debtColor.withOpacity(0.3));

    for (final pct in [0, 25, 50, 75, 100]) {
      final y = h - (pct / 100 * h);
      canvas.drawLine(Offset(leftPad, y), Offset(w, y), gridPaint);
      final tp = TextPainter(
          text: TextSpan(text: '$pct%', style: labelStyle),
          textDirection: TextDirection.ltr)
        ..layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }

    // ── Build equity points ────────────────────────────────────────────────
    List<Offset> eq = [];
    for (int i = 0; i < n; i++) {
      final x = leftPad + (n == 1 ? 0 : (i / (n - 1)) * chartW);
      final y = h - (rows[i].equity / 100 * progress * h);
      eq.add(Offset(x, y));
    }

    // ── Debt fill (from equity line down to bottom) ────────────────────────
    final debtPath = Path()..moveTo(eq.first.dx, h);
    for (int i = 0; i < n; i++) {
      if (i == 0) {
        debtPath.lineTo(eq[i].dx, eq[i].dy);
      } else {
        final cp1 = Offset((eq[i - 1].dx + eq[i].dx) / 2, eq[i - 1].dy);
        final cp2 = Offset((eq[i - 1].dx + eq[i].dx) / 2, eq[i].dy);
        debtPath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, eq[i].dx, eq[i].dy);
      }
    }
    for (int i = n - 1; i >= 0; i--) {
      debtPath.lineTo(eq[i].dx, h);
    }
    debtPath.close();
    canvas.drawPath(debtPath, Paint()..color = debtColor.withOpacity(0.15));

    // ── Equity fill (from equity line up to top) ───────────────────────────
    final eqFill = Path()..moveTo(eq.first.dx, h);
    eq.first.let((p) => eqFill.lineTo(p.dx, p.dy));
    for (int i = 1; i < n; i++) {
      final cp1 = Offset((eq[i - 1].dx + eq[i].dx) / 2, eq[i - 1].dy);
      final cp2 = Offset((eq[i - 1].dx + eq[i].dx) / 2, eq[i].dy);
      eqFill.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, eq[i].dx, eq[i].dy);
    }
    eqFill.lineTo(eq.last.dx, h);
    eqFill.close();
    canvas.drawPath(eqFill, Paint()..color = equityColor.withOpacity(0.28));

    // ── Equity stroke line ─────────────────────────────────────────────────
    final stroke = Path()..moveTo(eq.first.dx, eq.first.dy);
    for (int i = 1; i < n; i++) {
      final cp1 = Offset((eq[i - 1].dx + eq[i].dx) / 2, eq[i - 1].dy);
      final cp2 = Offset((eq[i - 1].dx + eq[i].dx) / 2, eq[i].dy);
      stroke.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, eq[i].dx, eq[i].dy);
    }
    canvas.drawPath(
        stroke,
        Paint()
          ..color = equityColor.withOpacity(0.9)
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round);

    // ── Key data points (every 5 years) ────────────────────────────────────
    for (int i = 0; i < n; i++) {
      final r = rows[i];
      final isKey = i == 0 ||
          i == n - 1 ||
          (r.age != null && r.age! % 5 == 0) ||
          (r.year != null && r.year! % 5 == 0);
      if (!isKey) continue;
      canvas.drawCircle(eq[i], 4.0, Paint()..color = equityColor);
      canvas.drawCircle(eq[i], 2.5, Paint()..color = AppColors.blackCard);
    }
  }

  @override
  bool shouldRepaint(_AreaChartPainter old) =>
      old.progress != progress || old.rows.length != rows.length;
}

// ══════════════════════════════════════════════════════════════════════════════
// ── Sub-widgets ────────────────────────────────────────────────────────────────
// ══════════════════════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  final String title, badge;
  const _SectionHeader({required this.title, required this.badge});
  @override
  Widget build(BuildContext context) => Row(children: [
        Text(title,
            style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: AppColors.green.withOpacity(0.9))),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
              border: Border.all(color: AppColors.green.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(4)),
          child: Text(badge,
              style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 8,
                  color: AppColors.green.withOpacity(0.55))),
        ),
      ]);
}

class _MetricCard extends StatelessWidget {
  final String label, value, sub;
  final Color? valueColor;
  const _MetricCard(
      {required this.label,
      required this.value,
      required this.sub,
      this.valueColor});
  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
              color: AppColors.blackCard,
              border: Border.all(color: AppColors.green.withOpacity(0.1))),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 8,
                    color: AppColors.textMuted.withOpacity(0.45))),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value,
                  style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: valueColor ?? Colors.white)),
            ),
            const SizedBox(height: 3),
            Text(sub,
                style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 7,
                    color: AppColors.textMuted.withOpacity(0.3))),
          ]),
        ),
      );
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final bool dashed;
  const _LegendDot(
      {required this.color, required this.label, this.dashed = false});
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 14,
            height: 3,
            color: dashed ? Colors.transparent : color,
            decoration: dashed
                ? BoxDecoration(border: Border.all(color: color, width: 1))
                : null),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 9,
                color: AppColors.textMuted.withOpacity(0.45))),
      ]);
}

class _ReturnCard extends StatelessWidget {
  final String label, value;
  final bool highlight;
  const _ReturnCard(
      {required this.label, required this.value, this.highlight = false});
  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
              color: highlight
                  ? AppColors.green.withOpacity(0.1)
                  : AppColors.blackCard,
              border: Border.all(
                  color: highlight
                      ? AppColors.green.withOpacity(0.4)
                      : AppColors.green.withOpacity(0.08))),
          child: Column(children: [
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 7,
                    color: AppColors.textMuted.withOpacity(0.35))),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: highlight ? AppColors.green : Colors.white)),
          ]),
        ),
      );
}

// ── Year-by-year table ────────────────────────────────────────────────────────
class _GlideTable extends StatelessWidget {
  final List<GlideRow> rows;
  const _GlideTable({required this.rows});
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
            border: Border.all(color: AppColors.green.withOpacity(0.1))),
        child: Column(children: [
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
                Expanded(
                    flex: 5,
                    child: Row(children: [
                      Expanded(
                          flex: eq,
                          child: Container(
                              height: 6,
                              color: AppColors.green.withOpacity(0.7))),
                      Expanded(
                          flex: dt,
                          child: Container(
                              height: 6,
                              color: AppColors.textMuted.withOpacity(0.2))),
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
    if (age != null) return 'Age $age';
    if (year != null) return 'Yr $year';
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
      if (lk == '_age_key') age = (v is int) ? v : n.toInt();
      if ([
        'equity_pct',
        'equity_percent',
        'equity_allocation',
        'equity_ratio',
        'equity'
      ].contains(lk)) {
        equity = n > 1 ? n : n * 100;
      }
      if ([
        'debt_pct',
        'debt_percent',
        'debt_allocation',
        'debt_ratio',
        'debt',
        'bond_pct',
        'bonds'
      ].contains(lk)) {
        debt = n > 1 ? n : n * 100;
      }
    });
    if (debt == 0 && equity > 0) debt = 100 - equity;
    if (equity == 0 && debt > 0) equity = 100 - debt;
    return GlideRow(year: year, age: age, equity: equity, debt: debt);
  }
}

// Convenience extension to avoid temp variable for let
extension _Let<T> on T {
  R let<R>(R Function(T) block) => block(this);
}
