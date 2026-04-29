// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'app_theme.dart';

class PortfolioStatsWidget extends StatelessWidget {
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

  List<_GoalStats> _aggregateGoals() {
    final goals = <_GoalStats>[];

    if (retirement != null) {
      goals.add(_GoalStats.fromGoalMap(
        retirement!,
        defaultName: "RETIREMENT",
        icon: Icons.beach_access_outlined,
      ));
    }

    for (var g in oneTimeGoals) {
      goals.add(_GoalStats.fromGoalMap(
        g,
        defaultName: "ONE TIME GOAL",
        icon: Icons.flag_outlined,
      ));
    }

    for (var g in recurringGoals) {
      goals.add(_GoalStats.fromGoalMap(
        g,
        defaultName: "RECURRING GOAL",
        icon: Icons.repeat,
      ));
    }

    return goals;
  }

  @override
  Widget build(BuildContext context) {
    final goals = _aggregateGoals();

    final totalSip = goals.fold<double>(0, (sum, g) => sum + g.monthlySip);

    final totalCorpus = goals.fold<double>(0, (sum, g) => sum + g.targetCorpus);

    final monthlyIncome = user.currentIncome / 12;

    final expenses = user.monthlyExpenses;

    final savings =
        (monthlyIncome - totalSip - expenses).clamp(0, double.infinity);

    final feasibleGoals = goals.where((g) => g.isFeasible).length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.blackCard,
        border: Border.all(
          color: AppColors.green.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// HEADER
          Text(
            "PORTFOLIO ANALYTICS",
            style: TextStyle(
              color: AppColors.green,
              fontSize: 12,
              letterSpacing: 3,
              fontFamily: 'Courier',
            ),
          ),

          const SizedBox(height: 20),

          /// METRICS
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  title: "TOTAL SIP",
                  value: _fmt(totalSip),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  title: "TOTAL CORPUS",
                  value: _fmt(totalCorpus),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  title: "GOALS ON TRACK",
                  value: "$feasibleGoals/${goals.length}",
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  title: "MONTHLY INCOME",
                  value: _fmt(monthlyIncome),
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          /// PIE CHART
          Text(
            "INCOME DISTRIBUTION",
            style: TextStyle(
              color: AppColors.green,
              fontFamily: 'Courier',
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            height: 250,
            child: PieChart(
              PieChartData(
                centerSpaceRadius: 45,
                sectionsSpace: 3,
                sections: [
                  PieChartSectionData(
                    value: totalSip,
                    color: AppColors.green,
                    title: "SIP",
                    radius: 70,
                  ),
                  PieChartSectionData(
                    value: expenses,
                    color: Colors.redAccent,
                    title: "EXP",
                    radius: 70,
                  ),
                  PieChartSectionData(
                    value: savings.toDouble(),
                    color: Colors.blueGrey,
                    title: "SAVE",
                    radius: 70,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 30),

          /// BAR CHART
          Text(
            "GOAL SIP COMPARISON",
            style: TextStyle(
              color: AppColors.green,
              fontFamily: 'Courier',
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                borderData: FlBorderData(show: false),
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                barGroups: goals.asMap().entries.map((entry) {
                  int index = entry.key;
                  final goal = entry.value;

                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: goal.monthlySip,
                        width: 18,
                        color: goal.isFeasible
                            ? AppColors.green
                            : Colors.redAccent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 30),

          /// LINE CHART
          Text(
            "5 YEAR SIP GROWTH",
            style: TextStyle(
              color: AppColors.green,
              fontFamily: 'Courier',
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                borderData: FlBorderData(show: false),
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    color: AppColors.green,
                    barWidth: 4,
                    dotData: FlDotData(show: true),
                    spots: List.generate(5, (index) {
                      final year = index + 1;

                      final projected = totalSip *
                          powValue(
                            (1 + user.incomeRaisePct / 100),
                            year,
                          );

                      return FlSpot(
                        year.toDouble(),
                        projected,
                      );
                    }),
                  )
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          /// CONFLICT STATUS
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.blackMid,
              border: Border.all(
                color: AppColors.green.withOpacity(0.1),
              ),
            ),
            child: Text(
              "Conflict Status: ${conflict['overall_status'] ?? 'N/A'}",
              style: TextStyle(
                color: AppColors.textMuted,
                fontFamily: 'Courier',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;

  const _MetricCard({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.blackMid,
        border: Border.all(
          color: AppColors.green.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontFamily: 'Courier',
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Courier',
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalStats {
  final String name;
  final IconData icon;
  final double monthlySip;
  final double targetCorpus;
  final bool isFeasible;

  _GoalStats({
    required this.name,
    required this.icon,
    required this.monthlySip,
    required this.targetCorpus,
    required this.isFeasible,
  });

  factory _GoalStats.fromGoalMap(
    Map<String, dynamic> data, {
    required String defaultName,
    required IconData icon,
  }) {
    final plan = data['plan'] ?? data;

    return _GoalStats(
      name: plan['goal_name'] ?? defaultName,
      icon: icon,
      monthlySip: (plan['monthly_sip'] ?? 0).toDouble(),
      targetCorpus: (plan['target_corpus'] ?? 0).toDouble(),
      isFeasible: plan['status'] == "feasible",
    );
  }
}

double powValue(double base, int exp) {
  double result = 1;
  for (int i = 0; i < exp; i++) {
    result *= base;
  }
  return result;
}

String _fmt(double value) {
  if (value >= 10000000) {
    return "₹${(value / 10000000).toStringAsFixed(2)} Cr";
  } else if (value >= 100000) {
    return "₹${(value / 100000).toStringAsFixed(2)} L";
  } else if (value >= 1000) {
    return "₹${(value / 1000).toStringAsFixed(1)}K";
  }
  return "₹${value.toStringAsFixed(0)}";
}
