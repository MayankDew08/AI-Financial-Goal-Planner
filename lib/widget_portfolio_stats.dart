// ignore_for_file: unused_local_variable, deprecated_member_use

import 'package:flutter/material.dart';
import 'app_theme.dart';

// ══════════════════════════════════════════════════════════════════════════════
// ── PortfolioStatsWidget ───────────────────────────────────────────────────────
//
// Usage:
//   import 'widget_portfolio_stats.dart';
//   PortfolioStatsWidget(
//     user: widget.user,
//     retirement: goals['retirement'],
//     oneTimeGoals: goals['onetime'] ?? [],
//     recurringGoals: goals['recurring'] ?? [],
//     conflict: conflictSummary,
//   )
//
// Shows:
//   • Total monthly SIP committed across all goals
//   • Total corpus target across all goals
//   • Goals on-track vs needs-attention count
//   • Income utilisation % with colour-coded bar
//   • SIP-to-income doughnut ring
//   • Per-goal breakdown table (expandable)
//   • Yearly SIP demand projection (expandable)
// ══════════════════════════════════════════════════════════════════════════════

class PortfolioStatsWidget extends StatefulWidget {
  final UserProfile user;
  final Map<String, dynamic>? retirement;
  final List oneTimeGoals;
  final List recurringGoals;
  final Map<String, dynamic> conflict;

  const PortfolioStatsWidget({
    super.key,
    required this.user,
    required this.retirement,
    required this.oneTimeGoals,
    required this.recurringGoals,
    required this.conflict,
  });

  @override
  State<PortfolioStatsWidget> createState() => _PortfolioStatsWidgetState();
}

class _PortfolioStatsWidgetState extends State<PortfolioStatsWidget>
    with SingleTickerProviderStateMixin {
  bool _showBreakdown = false;
  bool _showProjection = false;
  late AnimationController _barCtrl;
  late Animation<double> _barProgress;

  @override
  void initState() {
    super.initState();
    _barCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _barProgress =
        CurvedAnimation(parent: _barCtrl, curve: Curves.easeOutCubic);
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _barCtrl.forward();
    });
  }

  @override
  void dispose() {
    _barCtrl.dispose();
    super.dispose();
  }

  // ── Goal data aggregation ─────────────────────────────────────────────────

  List<_GoalStats> _aggregateGoals() {
    final out = <_GoalStats>[];

    if (widget.retirement != null) {
      out.add(_GoalStats.fromGoalMap(
        widget.retirement!,
        defaultName: 'RETIREMENT',
        icon: Icons.beach_access_outlined,
        type: GoalType.retirement,
      ));
    }
    for (final g in widget.oneTimeGoals) {
      out.add(_GoalStats.fromGoalMap(
        g as Map<String, dynamic>,
        defaultName: 'ONE-TIME GOAL',
        icon: Icons.flag_outlined,
        type: GoalType.oneTime,
      ));
    }
    for (final g in widget.recurringGoals) {
      out.add(_GoalStats.fromGoalMap(
        g as Map<String, dynamic>,
        defaultName: 'RECURRING GOAL',
        icon: Icons.repeat_rounded,
        type: GoalType.recurring,
      ));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final goals = _aggregateGoals();
    final totalSip = goals.fold(0.0, (s, g) => s + g.monthlySip);
    final totalCorpus = goals.fold(0.0, (s, g) => s + g.targetCorpus);
    final feasible = goals.where((g) => g.isFeasible).length;
    final monthlyInc = widget.user.currentIncome / 12;
    final utilPct =
        monthlyInc > 0 ? (totalSip / monthlyInc * 100).clamp(0.0, 100.0) : 0.0;
    final savingsPct = monthlyInc > 0
        ? ((monthlyInc - totalSip - widget.user.monthlyExpenses) /
                monthlyInc *
                100)
            .clamp(0.0, 100.0)
        : 0.0;
    final expPct = monthlyInc > 0
        ? (widget.user.monthlyExpenses / monthlyInc * 100).clamp(0.0, 100.0)
        : 0.0;

    final conflictStatus =
        (widget.conflict['overall_status'] as String? ?? '').toLowerCase();
    final healthColor = conflictStatus == 'all_clear'
        ? AppColors.green
        : conflictStatus.contains('warning') || conflictStatus.contains('under')
            ? const Color(0xFFFFA500)
            : AppColors.error;

    final utilColor = utilPct < 30
        ? AppColors.green
        : utilPct < 50
            ? const Color(0xFFFFA500)
            : AppColors.error;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.blackCard,
        border: Border.all(color: AppColors.green.withOpacity(0.22)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Header bar ────────────────────────────────────────────────────────
        _StatsHeader(conflictStatus: conflictStatus, healthColor: healthColor),

        // ── Big 4 metrics ─────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Row(children: [
              _BigMetric(
                label: 'TOTAL MONTHLY SIP',
                value: _fmt(totalSip),
                valueColor: AppColors.green,
                sub:
                    'across ${goals.length} goal${goals.length == 1 ? '' : 's'}',
              ),
              const SizedBox(width: 12),
              _BigMetric(
                label: 'TOTAL CORPUS TARGET',
                value: _fmt(totalCorpus),
                valueColor: Colors.white,
                sub: 'combined target',
              ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              _BigMetric(
                label: 'GOALS ON TRACK',
                value: '$feasible / ${goals.length}',
                valueColor: feasible == goals.length
                    ? AppColors.green
                    : const Color(0xFFFFA500),
                sub: goals.length - feasible > 0
                    ? '${goals.length - feasible} need attention'
                    : 'all feasible ✓',
              ),
              const SizedBox(width: 12),
              _BigMetric(
                label: 'INCOME USED FOR SIPs',
                value: '${utilPct.toStringAsFixed(1)}%',
                valueColor: utilColor,
                sub: '₹${_fmt(monthlyInc)}/mo income',
              ),
            ]),
          ]),
        ),

        // ── Income breakdown bar ───────────────────────────────────────────────
        _IncomeBreakdownBar(
          sipPct: utilPct,
          expPct: expPct,
          savingsPct: savingsPct,
          totalSip: totalSip,
          monthlyInc: monthlyInc,
          expenses: widget.user.monthlyExpenses,
          barProgress: _barProgress,
        ),

        const SizedBox(height: 4),

        // ── Conflict detail strip ──────────────────────────────────────────────
        _ConflictDetailStrip(conflict: widget.conflict),

        // ── Per-goal breakdown toggle ──────────────────────────────────────────
        _ExpandToggle(
          label: _showBreakdown ? 'HIDE GOAL BREAKDOWN' : 'VIEW GOAL BREAKDOWN',
          onTap: () => setState(() => _showBreakdown = !_showBreakdown),
          expanded: _showBreakdown,
        ),

        if (_showBreakdown)
          _GoalBreakdownTable(
              goals: goals, totalSip: totalSip, totalCorpus: totalCorpus),

        // ── Yearly projection toggle ───────────────────────────────────────────
        _ExpandToggle(
          label: _showProjection
              ? 'HIDE SIP PROJECTION'
              : 'VIEW 5-YEAR SIP PROJECTION',
          onTap: () => setState(() => _showProjection = !_showProjection),
          expanded: _showProjection,
        ),

        if (_showProjection)
          _SipProjectionTable(
            totalSip: totalSip,
            incomeRaisePct: widget.user.incomeRaisePct,
            monthlyIncome: monthlyInc,
          ),

        const SizedBox(height: 4),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ── Sub-widgets ────────────────────────────────────────────────────────────────
// ══════════════════════════════════════════════════════════════════════════════

class _StatsHeader extends StatelessWidget {
  final String conflictStatus;
  final Color healthColor;
  const _StatsHeader({required this.conflictStatus, required this.healthColor});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
        decoration: BoxDecoration(
          color: AppColors.green.withOpacity(0.04),
          border: Border(
              bottom: BorderSide(color: AppColors.green.withOpacity(0.1))),
        ),
        child: Row(children: [
          Container(
              width: 16, height: 1, color: AppColors.green.withOpacity(0.5)),
          const SizedBox(width: 10),
          const Text('COMBINED PORTFOLIO STATS',
              style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 9,
                  letterSpacing: 3,
                  color: AppColors.green)),
          const Spacer(),
          Container(
            width: 7,
            height: 7,
            decoration:
                BoxDecoration(shape: BoxShape.circle, color: healthColor),
          ),
          const SizedBox(width: 6),
          Text(
            conflictStatus.isEmpty
                ? 'NO DATA'
                : conflictStatus.replaceAll('_', ' ').toUpperCase(),
            style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 8,
                letterSpacing: 1,
                fontWeight: FontWeight.bold,
                color: healthColor),
          ),
        ]),
      );
}

// ── Big metric tile ────────────────────────────────────────────────────────────
class _BigMetric extends StatelessWidget {
  final String label, value, sub;
  final Color valueColor;
  const _BigMetric({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: AppColors.blackMid,
              border: Border.all(color: AppColors.green.withOpacity(0.1))),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 7,
                    letterSpacing: 1,
                    color: AppColors.textMuted.withOpacity(0.35))),
            const SizedBox(height: 7),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value,
                  style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: valueColor)),
            ),
            const SizedBox(height: 4),
            Text(sub,
                style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 8,
                    color: AppColors.textMuted.withOpacity(0.3))),
          ]),
        ),
      );
}

// ── Income breakdown bar ────────────────────────────────────────────────────────
class _IncomeBreakdownBar extends StatelessWidget {
  final double sipPct, expPct, savingsPct;
  final double totalSip, monthlyInc, expenses;
  final Animation<double> barProgress;

  const _IncomeBreakdownBar({
    required this.sipPct,
    required this.expPct,
    required this.savingsPct,
    required this.totalSip,
    required this.monthlyInc,
    required this.expenses,
    required this.barProgress,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('MONTHLY INCOME BREAKDOWN',
              style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 7,
                  letterSpacing: 2,
                  color: AppColors.textMuted.withOpacity(0.35))),
          const SizedBox(height: 8),

          // Segmented bar
          AnimatedBuilder(
            animation: barProgress,
            builder: (_, __) {
              final p = barProgress.value;
              final sipW = (sipPct * p / 100).clamp(0.0, 1.0);
              final expW = (expPct * p / 100).clamp(0.0, 1.0);
              final savW = ((100 - sipPct - expPct) * p / 100).clamp(0.0, 1.0);
              return Container(
                height: 14,
                clipBehavior: Clip.antiAlias,
                decoration: const BoxDecoration(),
                child: Row(children: [
                  // SIP portion
                  Flexible(
                    flex: (sipW * 1000).toInt(),
                    child: Container(color: AppColors.green),
                  ),
                  // Expenses portion
                  Flexible(
                    flex: (expW * 1000).toInt(),
                    child: Container(color: AppColors.error.withOpacity(0.55)),
                  ),
                  // Savings / surplus
                  Flexible(
                    flex: (savW * 1000).toInt().clamp(1, 1000),
                    child:
                        Container(color: AppColors.textMuted.withOpacity(0.12)),
                  ),
                ]),
              );
            },
          ),
          const SizedBox(height: 8),

          // Legend
          Row(children: [
            _BarLegend(
                color: AppColors.green,
                label: 'SIPs',
                value: '₹${_fmt(totalSip)}'),
            const SizedBox(width: 14),
            _BarLegend(
                color: AppColors.error.withOpacity(0.7),
                label: 'EXPENSES',
                value: '₹${_fmt(expenses)}'),
            const SizedBox(width: 14),
            _BarLegend(
                color: AppColors.textMuted.withOpacity(0.4),
                label: 'SURPLUS',
                value:
                    '₹${_fmt((monthlyInc - totalSip - expenses).clamp(0, double.infinity))}'),
          ]),
        ]),
      );
}

class _BarLegend extends StatelessWidget {
  final Color color;
  final String label, value;
  const _BarLegend(
      {required this.color, required this.label, required this.value});
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 8, height: 8, color: color),
        const SizedBox(width: 5),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 7,
                  color: AppColors.textMuted.withOpacity(0.35))),
          Text(value,
              style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMuted.withOpacity(0.6))),
        ]),
      ]);
}

// ── Conflict detail strip ───────────────────────────────────────────────────────
class _ConflictDetailStrip extends StatelessWidget {
  final Map<String, dynamic> conflict;
  const _ConflictDetailStrip({required this.conflict});

  @override
  Widget build(BuildContext context) {
    final breachCritical = conflict['critical_breach_count'] as int?;
    final breachWarning = conflict['warning_breach_count'] as int?;
    final advisory = conflict['advisory_count'] as int?;
    final corridor = conflict['corridor_config'] as Map<String, dynamic>?;
    final floorPct = corridor?['floor_pct'] ?? corridor?['savings_floor_pct'];
    final ceilPct = corridor?['ceiling_pct'];

    // Only render if we have meaningful data
    if (breachCritical == null && breachWarning == null && floorPct == null) {
      return const SizedBox();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: AppColors.blackMid,
          border: Border.all(color: AppColors.green.withOpacity(0.08))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('CONFLICT ENGINE DETAILS',
            style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 7,
                letterSpacing: 2,
                color: AppColors.textMuted.withOpacity(0.3))),
        const SizedBox(height: 10),
        Row(children: [
          if (breachCritical != null)
            _ConflictChip(
                label: 'CRITICAL BREACHES',
                value: '$breachCritical',
                color: breachCritical > 0 ? AppColors.error : AppColors.green),
          if (breachWarning != null) ...[
            const SizedBox(width: 8),
            _ConflictChip(
                label: 'WARNINGS',
                value: '$breachWarning',
                color: breachWarning > 0
                    ? const Color(0xFFFFA500)
                    : AppColors.green),
          ],
          if (advisory != null) ...[
            const SizedBox(width: 8),
            _ConflictChip(
                label: 'ADVISORY',
                value: '$advisory',
                color: AppColors.textMuted.withOpacity(0.5)),
          ],
        ]),
        if (floorPct != null || ceilPct != null) ...[
          const SizedBox(height: 10),
          Row(children: [
            if (floorPct != null)
              _CorridorStat(label: 'SAVINGS FLOOR', value: '$floorPct%'),
            if (ceilPct != null) ...[
              const SizedBox(width: 12),
              _CorridorStat(label: 'SAVINGS CEILING', value: '$ceilPct%'),
            ],
          ]),
          const SizedBox(height: 6),
          Text(
            'Your SIP commitments must stay within the floor–ceiling corridor.',
            style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 7,
                height: 1.6,
                color: AppColors.textMuted.withOpacity(0.22)),
          ),
        ],
      ]),
    );
  }
}

class _ConflictChip extends StatelessWidget {
  final String label, value;
  final Color color;
  const _ConflictChip(
      {required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
              border: Border.all(color: color.withOpacity(0.3)),
              color: color.withOpacity(0.06)),
          child: Column(children: [
            Text(value,
                style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: color)),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 6,
                    letterSpacing: 1,
                    color: color.withOpacity(0.6))),
          ]),
        ),
      );
}

class _CorridorStat extends StatelessWidget {
  final String label, value;
  const _CorridorStat({required this.label, required this.value});
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Text('$label: ',
            style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 8,
                color: AppColors.textMuted.withOpacity(0.3))),
        Text(value,
            style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: AppColors.green.withOpacity(0.7))),
      ]);
}

// ── Expand toggle row ───────────────────────────────────────────────────────────
class _ExpandToggle extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool expanded;
  const _ExpandToggle(
      {required this.label, required this.onTap, required this.expanded});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
              border: Border(
                  top: BorderSide(color: AppColors.green.withOpacity(0.08)))),
          child: Row(children: [
            Text(label,
                style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 9,
                    letterSpacing: 2,
                    color: AppColors.green.withOpacity(0.45))),
            const Spacer(),
            Icon(
              expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: AppColors.green.withOpacity(0.35),
              size: 16,
            ),
          ]),
        ),
      );
}

// ── Per-goal breakdown table ────────────────────────────────────────────────────
class _GoalBreakdownTable extends StatelessWidget {
  final List<_GoalStats> goals;
  final double totalSip, totalCorpus;
  const _GoalBreakdownTable({
    required this.goals,
    required this.totalSip,
    required this.totalCorpus,
  });

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
            border: Border(
                top: BorderSide(color: AppColors.green.withOpacity(0.07)))),
        child: Column(children: [
          // Column headers
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: Row(children: [
              _BH('GOAL', flex: 5),
              _BH('SIP/MO', flex: 3, align: TextAlign.right),
              _BH('TARGET', flex: 3, align: TextAlign.right),
              _BH('%  OF  SIP', flex: 3, align: TextAlign.right),
              const SizedBox(width: 18),
            ]),
          ),
          // Goal rows
          ...goals.map((g) {
            final sipShare =
                totalSip > 0 ? (g.monthlySip / totalSip * 100) : 0.0;
            return _GoalRow(goal: g, sipShare: sipShare);
          }),
          // Totals
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            decoration: BoxDecoration(
                color: AppColors.green.withOpacity(0.04),
                border: Border(
                    top: BorderSide(color: AppColors.green.withOpacity(0.12)))),
            child: Row(children: [
              Expanded(
                  flex: 5,
                  child: Text('TOTAL',
                      style: TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 10,
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                          color: AppColors.green.withOpacity(0.7)))),
              Expanded(
                  flex: 3,
                  child: Text(_fmt(totalSip),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: AppColors.green))),
              Expanded(
                  flex: 3,
                  child: Text(_fmt(totalCorpus),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Colors.white))),
              Expanded(
                  flex: 3,
                  child: Text('100%',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMuted.withOpacity(0.5)))),
              const SizedBox(width: 18),
            ]),
          ),
        ]),
      );
}

class _GoalRow extends StatelessWidget {
  final _GoalStats goal;
  final double sipShare;
  const _GoalRow({required this.goal, required this.sipShare});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: BoxDecoration(
            border: Border(
                top: BorderSide(color: AppColors.green.withOpacity(0.05)))),
        child: Row(children: [
          Expanded(
              flex: 5,
              child: Row(children: [
                Icon(goal.icon,
                    size: 11,
                    color: goal.isFeasible
                        ? AppColors.green.withOpacity(0.6)
                        : AppColors.error.withOpacity(0.6)),
                const SizedBox(width: 6),
                Expanded(
                    child: Text(goal.name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 9,
                            color: AppColors.textMuted.withOpacity(0.65)))),
              ])),
          Expanded(
              flex: 3,
              child: Text(goal.monthlySip > 0 ? _fmt(goal.monthlySip) : '—',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.green.withOpacity(0.85)))),
          Expanded(
              flex: 3,
              child: Text(goal.targetCorpus > 0 ? _fmt(goal.targetCorpus) : '—',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMuted.withOpacity(0.6)))),
          Expanded(
              flex: 3,
              child: Text(
                  goal.monthlySip > 0 ? '${sipShare.toStringAsFixed(1)}%' : '—',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 9,
                      color: AppColors.textMuted.withOpacity(0.45)))),
          const SizedBox(width: 4),
          Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: goal.isFeasible ? AppColors.green : AppColors.error)),
          const SizedBox(width: 8),
        ]),
      );
}

// ── 5-year SIP projection table ──────────────────────────────────────────────
// Projects how total SIP demand and income evolve over 5 years
// using the user's income raise %.
class _SipProjectionTable extends StatelessWidget {
  final double totalSip, incomeRaisePct, monthlyIncome;
  const _SipProjectionTable({
    required this.totalSip,
    required this.incomeRaisePct,
    required this.monthlyIncome,
  });

  @override
  Widget build(BuildContext context) {
    // Assume SIP grows at 5% per year (standard step-up) and income at raise %
    const sipStepUp = 5.0;
    final rows = List.generate(5, (i) {
      final yr = i + 1;
      final sip = totalSip * (1 + sipStepUp / 100);
      final inc = monthlyIncome * (1 + incomeRaisePct / 100);
      final cumSip = totalSip * (pow1(1 + sipStepUp / 100, yr));
      final cumInc = monthlyIncome * (pow1(1 + incomeRaisePct / 100, yr));
      final util = cumInc > 0 ? (cumSip / cumInc * 100).clamp(0.0, 100.0) : 0.0;
      return _ProjectionRow(
          year: yr, monthlySip: cumSip, monthlyIncome: cumInc, utilPct: util);
    });

    return Container(
      decoration: BoxDecoration(
          border: Border(
              top: BorderSide(color: AppColors.green.withOpacity(0.07)))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            'Assumes ${sipStepUp.toStringAsFixed(0)}% annual SIP step-up'
            ' · ${incomeRaisePct.toStringAsFixed(1)}% income growth',
            style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 7,
                height: 1.6,
                color: AppColors.textMuted.withOpacity(0.25)),
          ),
        ),
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Row(children: [
            _BH('YEAR', flex: 2),
            _BH('MONTHLY SIP', flex: 4, align: TextAlign.right),
            _BH('INCOME', flex: 4, align: TextAlign.right),
            _BH('% UTILISED', flex: 3, align: TextAlign.right),
          ]),
        ),
        // Data rows
        ...rows.map((r) => Container(
              padding: const EdgeInsets.fromLTRB(16, 9, 16, 9),
              decoration: BoxDecoration(
                  border: Border(
                      top: BorderSide(
                          color: AppColors.green.withOpacity(0.05)))),
              child: Row(children: [
                _BD('YR ${r.year}',
                    flex: 2, color: AppColors.textMuted.withOpacity(0.5)),
                _BD(_fmt(r.monthlySip),
                    flex: 4,
                    align: TextAlign.right,
                    color: AppColors.green.withOpacity(0.8)),
                _BD(_fmt(r.monthlyIncome), flex: 4, align: TextAlign.right),
                _BD('${r.utilPct.toStringAsFixed(1)}%',
                    flex: 3,
                    align: TextAlign.right,
                    color: r.utilPct < 30
                        ? AppColors.green
                        : r.utilPct < 50
                            ? const Color(0xFFFFA500)
                            : AppColors.error),
              ]),
            )),
        const SizedBox(height: 8),
      ]),
    );
  }
}

class _ProjectionRow {
  final int year;
  final double monthlySip, monthlyIncome, utilPct;
  const _ProjectionRow({
    required this.year,
    required this.monthlySip,
    required this.monthlyIncome,
    required this.utilPct,
  });
}

// Tiny pow helper to avoid dart:math import
double pow1(double base, int exp) {
  double result = 1.0;
  for (int i = 0; i < exp; i++) {
    result *= base;
  }
  return result;
}

// ── Table cell helpers ─────────────────────────────────────────────────────────
class _BH extends StatelessWidget {
  final String text;
  final int flex;
  final TextAlign align;
  const _BH(this.text, {this.flex = 1, this.align = TextAlign.left});
  @override
  Widget build(BuildContext context) => Expanded(
      flex: flex,
      child: Text(text,
          textAlign: align,
          style: TextStyle(
              fontFamily: 'Courier',
              fontSize: 7,
              letterSpacing: 1,
              color: AppColors.textMuted.withOpacity(0.3))));
}

class _BD extends StatelessWidget {
  final String text;
  final int flex;
  final TextAlign align;
  final Color? color;
  const _BD(this.text,
      {this.flex = 1, this.align = TextAlign.left, this.color});
  @override
  Widget build(BuildContext context) => Expanded(
      flex: flex,
      child: Text(text,
          textAlign: align,
          style: TextStyle(
              fontFamily: 'Courier',
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: color ?? AppColors.textMuted.withOpacity(0.7))));
}

// ══════════════════════════════════════════════════════════════════════════════
// ── _GoalStats data model ──────────────────────────────────────────────────────
// ══════════════════════════════════════════════════════════════════════════════

enum GoalType { retirement, oneTime, recurring }

class _GoalStats {
  final String name;
  final IconData icon;
  final double monthlySip;
  final double targetCorpus;
  final bool isFeasible;
  final GoalType type;

  const _GoalStats({
    required this.name,
    required this.icon,
    required this.monthlySip,
    required this.targetCorpus,
    required this.isFeasible,
    required this.type,
  });

  factory _GoalStats.fromGoalMap(
    Map<String, dynamic> g, {
    required String defaultName,
    required IconData icon,
    required GoalType type,
  }) {
    final plan = (g['plan'] as Map<String, dynamic>?) ?? g;
    final corpus = plan['corpus'] as Map<String, dynamic>?;
    final sipPlan = plan['sip_plan'] as Map<String, dynamic>?;
    final summary = plan['goal_summary'] as Map<String, dynamic>?;

    // SIP — try all known key names
    double sip = 0;
    for (final v in [
      corpus?['starting_monthly_sip'],
      corpus?['required_sip'],
      corpus?['monthly_sip'],
      sipPlan?['starting_monthly_sip'],
      sipPlan?['total_monthly_sip'],
      sipPlan?['monthly_sip'],
      plan['monthly_sip'],
      plan['starting_monthly_sip'],
    ]) {
      final n = num.tryParse(v?.toString() ?? '')?.toDouble();
      if (n != null && n > 0) {
        sip = n;
        break;
      }
    }

    // Target corpus
    double target = 0;
    for (final v in [
      corpus?['required_corpus'],
      corpus?['target_corpus'],
      summary?['target_amount'],
      summary?['goal_amount'],
      plan['goal_amount'],
      plan['target_corpus'],
    ]) {
      final n = num.tryParse(v?.toString() ?? '')?.toDouble();
      if (n != null && n > 0) {
        target = n;
        break;
      }
    }

    final status = (plan['status'] as String? ?? '').toLowerCase();
    final rawName = plan['goal_name'] ??
        summary?['goal_name'] ??
        g['goal_name'] ??
        defaultName;

    return _GoalStats(
      name: rawName.toString().toUpperCase(),
      icon: icon,
      monthlySip: sip,
      targetCorpus: target,
      isFeasible: status == 'feasible',
      type: type,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ── Formatting helpers ─────────────────────────────────────────────────────────
// ══════════════════════════════════════════════════════════════════════════════

String _fmt(double v) {
  if (v == 0) return '₹0';
  if (v >= 10000000) return '₹${(v / 10000000).toStringAsFixed(2)} Cr';
  if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(2)} L';
  if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(1)} K';
  return '₹${v.toStringAsFixed(0)}';
}
