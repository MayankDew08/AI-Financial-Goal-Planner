import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../screens/goal_details_screen.dart';
import 'portfolio_helpers.dart';
import 'glide_path_widget.dart';

class RetirementCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const RetirementCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final plan = (data['plan'] as Map<String, dynamic>?) ?? data;
    final status = (plan['status'] as String? ?? '').toLowerCase();
    final isFeasible = status == 'feasible';
    final statusColor = isFeasible ? AppColors.green : AppColors.error;

    final corpus = plan['corpus'] as Map<String, dynamic>? ?? {};
    final feasibility = plan['feasibility'] as Map<String, dynamic>? ?? {};

    final requiredCorpus = fmtCurrency(corpus['required_corpus']);
    final monthlyShortfall = fmtCurrency(feasibility['monthly_shortfall']);
    final requiredSip = fmtCurrency(corpus['starting_monthly_sip'] ??
        corpus['required_sip'] ??
        corpus['monthly_sip']);
    final retirementAge = plan['retirement_age']?.toString() ??
        corpus['retirement_age']?.toString() ??
        '—';

    return Container(
      decoration: BoxDecoration(
          color: AppColors.blackCard,
          border: Border.all(color: AppColors.green.withOpacity(0.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                  color: statusColor.withOpacity(0.07)),
              child: Icon(Icons.beach_access_outlined,
                  color: statusColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const Text('RETIREMENT PLAN',
                      style: TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 11,
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 3),
                  Text('Retire at $retirementAge',
                      style: TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 9,
                          color: AppColors.textMuted.withOpacity(0.4))),
                ])),
            StatusChip(status: status, color: statusColor),
          ]),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(children: [
            MetricMini(label: 'CORPUS NEEDED', value: requiredCorpus),
            const SizedBox(width: 12),
            MetricMini(
                label: isFeasible ? 'MONTHLY SIP' : 'MONTHLY SHORTFALL',
                value: isFeasible ? requiredSip : monthlyShortfall,
                valueColor: isFeasible ? AppColors.green : AppColors.error),
          ]),
        ),

        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GoalDetailsScreen(
                  title: 'RETIREMENT PLAN',
                  subtitle: 'Retire at $retirementAge',
                  icon: Icons.beach_access_outlined,
                  status: status,
                  statusColor: statusColor,
                  previewMetrics: Row(
                    children: [
                      MetricMini(label: 'CORPUS NEEDED', value: requiredCorpus),
                      const SizedBox(width: 12),
                      MetricMini(
                          label: isFeasible ? 'MONTHLY SIP' : 'MONTHLY SHORTFALL',
                          value: isFeasible ? requiredSip : monthlyShortfall,
                          valueColor: isFeasible ? AppColors.green : AppColors.error),
                    ],
                  ),
                  detailWidget: RetirementDetail(plan: plan),
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

class RetirementDetail extends StatelessWidget {
  final Map<String, dynamic> plan;
  const RetirementDetail({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    final corpus = plan['corpus'] as Map<String, dynamic>? ?? {};
    final feasibility = plan['feasibility'] as Map<String, dynamic>? ?? {};
    final glideRaw = plan['glide_path'] ?? plan['glide_paths'];
    final buckets = plan['buckets'] as Map<String, dynamic>?;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (corpus.isNotEmpty) DetailSection(title: 'CORPUS', data: corpus),
      if (feasibility.isNotEmpty)
        DetailSection(title: 'FEASIBILITY', data: feasibility),
      if (glideRaw != null) GlidePathWidget(raw: glideRaw),
      if (buckets != null && buckets.isNotEmpty) BucketsSection(data: buckets),
    ]);
  }
}
