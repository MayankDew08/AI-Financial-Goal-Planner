import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../screens/goal_details_screen.dart';
import 'portfolio_helpers.dart';

class RecurringGoalCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onDelete;
  const RecurringGoalCard({super.key, required this.data, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final plan = (data['plan'] as Map<String, dynamic>?) ?? data;
    final status = (plan['status'] as String? ?? '').toLowerCase();
    final isFeasible = status == 'feasible';
    final statusColor = isFeasible ? AppColors.green : AppColors.error;

    final summary = plan['goal_summary'] as Map<String, dynamic>? ?? {};
    final sipPlan = plan['sip_plan'] as Map<String, dynamic>? ?? {};
    final goalName = plan['goal_name'] ??
        summary['goal_name'] ??
        data['goal_name'] ??
        'RECURRING GOAL';

    final totalSip =
        fmtCurrency(sipPlan['total_monthly_sip'] ?? sipPlan['monthly_sip']);
    final occurrences = sipPlan['num_occurrences']?.toString() ??
        summary['num_occurrences']?.toString() ??
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
              child: Icon(Icons.repeat_rounded, color: statusColor, size: 20),
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
                  Text('$occurrences occurrences',
                      style: TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 9,
                          color: AppColors.textMuted.withOpacity(0.35))),
                ])),
            GestureDetector(
              onTap: onDelete,
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
          child: MetricMini(
              label: 'TOTAL MONTHLY SIP',
              value: totalSip,
              valueColor: AppColors.green),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GoalDetailsScreen(
                  title: goalName.toString(),
                  subtitle: '$occurrences occurrences',
                  icon: Icons.repeat_rounded,
                  status: status,
                  statusColor: statusColor,
                  previewMetrics: MetricMini(
                      label: 'TOTAL MONTHLY SIP',
                      value: totalSip,
                      valueColor: AppColors.green),
                  detailWidget: RecurringDetail(plan: plan),
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
                color: AppColors.green.withOpacity(0.04),
                border: Border(
                    top: BorderSide(color: AppColors.green.withOpacity(0.08)))),
            child: Row(children: [
              Text('VIEW DETAILS',
                  style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: AppColors.green.withOpacity(0.8))),
              const Spacer(),
              Icon(Icons.arrow_forward,
                  color: AppColors.green.withOpacity(0.6), size: 16),
            ]),
          ),
        ),
      ]),
    );
  }
}

class RecurringDetail extends StatelessWidget {
  final Map<String, dynamic> plan;
  const RecurringDetail({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    final summary = plan['goal_summary'] as Map<String, dynamic>? ?? {};
    final sipPlan = plan['sip_plan'] as Map<String, dynamic>? ?? {};
    final feasibility = plan['feasibility'] as Map<String, dynamic>? ?? {};
    final occurrencePlans = sipPlan['occurrence_plans'] as List? ?? [];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (summary.isNotEmpty)
        DetailSection(title: 'GOAL SUMMARY', data: summary),
      if (feasibility.isNotEmpty)
        DetailSection(title: 'FEASIBILITY', data: feasibility),
      if (occurrencePlans.isNotEmpty) OccurrenceTable(items: occurrencePlans),
    ]);
  }
}
