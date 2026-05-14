import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'portfolio_helpers.dart';
import 'glide_path_widget.dart';

class OneTimeGoalCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final VoidCallback onDelete;
  const OneTimeGoalCard({super.key, required this.data, required this.onDelete});

  @override
  State<OneTimeGoalCard> createState() => _OneTimeGoalCardState();
}

class _OneTimeGoalCardState extends State<OneTimeGoalCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final plan = (widget.data['plan'] as Map<String, dynamic>?) ?? widget.data;
    final status = (plan['status'] as String? ?? '').toLowerCase();
    final isFeasible = status == 'feasible';
    final statusColor = isFeasible ? AppColors.green : AppColors.error;

    final summary = plan['goal_summary'] as Map<String, dynamic>? ?? {};
    final sipPlan = plan['sip_plan'] as Map<String, dynamic>? ?? {};
    final goalName = plan['goal_name'] ??
        summary['goal_name'] ??
        widget.data['goal_name'] ??
        'GOAL';

    final targetAmount = fmtCurrency(summary['target_amount'] ??
        summary['goal_amount'] ??
        plan['goal_amount']);
    final monthlySip = fmtCurrency(sipPlan['starting_monthly_sip'] ??
        sipPlan['monthly_sip'] ??
        plan['monthly_sip']);
    final yearsToGoal = summary['years_to_goal']?.toString() ??
        plan['years_to_goal']?.toString() ??
        '—';

    return Container(
      decoration: BoxDecoration(
          color: AppColors.blackCard,
          border: Border.all(color: AppColors.green.withOpacity(0.15))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  border: Border.all(color: statusColor.withOpacity(0.25)),
                  color: statusColor.withOpacity(0.06)),
              child: Icon(Icons.flag_outlined, color: statusColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(goalName.toString().toUpperCase(),
                      style: const TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 11,
                          letterSpacing: 1,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 3),
                  Text('$yearsToGoal years away',
                      style: TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 9,
                          color: AppColors.textMuted.withOpacity(0.35))),
                ])),
            GestureDetector(
              onTap: widget.onDelete,
              child: Container(
                padding: const EdgeInsets.all(6),
                child: Icon(Icons.delete_outline,
                    color: AppColors.textMuted.withOpacity(0.3), size: 18),
              ),
            ),
            const SizedBox(width: 4),
            StatusChip(status: status, color: statusColor),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(children: [
            MetricMini(label: 'TARGET', value: targetAmount),
            const SizedBox(width: 12),
            MetricMini(
                label: 'MONTHLY SIP',
                value: monthlySip,
                valueColor: AppColors.green),
          ]),
        ),
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
                border: Border(
                    top: BorderSide(color: AppColors.green.withOpacity(0.06)))),
            child: Row(children: [
              Text(_expanded ? 'HIDE DETAILS' : 'VIEW DETAILS',
                  style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 9,
                      letterSpacing: 2,
                      color: AppColors.green.withOpacity(0.5))),
              const Spacer(),
              Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: AppColors.green.withOpacity(0.4),
                  size: 16),
            ]),
          ),
        ),
        if (_expanded) _OneTimeDetail(plan: plan),
      ]),
    );
  }
}

class _OneTimeDetail extends StatelessWidget {
  final Map<String, dynamic> plan;
  const _OneTimeDetail({required this.plan});

  @override
  Widget build(BuildContext context) {
    final summary = plan['goal_summary'] as Map<String, dynamic>? ?? {};
    final sipPlan = plan['sip_plan'] as Map<String, dynamic>? ?? {};
    final feasibility = plan['feasibility'] as Map<String, dynamic>? ?? {};
    final allocation = plan['allocation'] as Map<String, dynamic>?;
    final glideRaw = plan['glide_path'] ?? plan['glide_paths'];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (summary.isNotEmpty)
        DetailSection(title: 'GOAL SUMMARY', data: summary),
      if (sipPlan.isNotEmpty) DetailSection(title: 'SIP PLAN', data: sipPlan),
      if (feasibility.isNotEmpty)
        DetailSection(title: 'FEASIBILITY', data: feasibility),
      if (allocation != null && allocation.isNotEmpty)
        AllocationBar(data: allocation),
      if (glideRaw != null) GlidePathWidget(raw: glideRaw),
    ]);
  }
}
