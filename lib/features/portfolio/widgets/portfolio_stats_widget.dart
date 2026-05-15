// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_theme.dart';

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

class _PortfolioStatsWidgetState extends State<PortfolioStatsWidget> {
  int _pieTouchedIndex = -1;

  List<_GoalStats> _aggregateGoals() {
    final goals = <_GoalStats>[];

    if (widget.retirement != null) {
      goals.add(_GoalStats.fromGoalMap(
        widget.retirement!,
        defaultName: "RETIREMENT",
        icon: Icons.beach_access_outlined,
      ));
    }

    for (var g in widget.oneTimeGoals) {
      goals.add(_GoalStats.fromGoalMap(
        g,
        defaultName: "ONE TIME GOAL",
        icon: Icons.flag_outlined,
      ));
    }

    for (var g in widget.recurringGoals) {
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

    final monthlyIncome = widget.user.currentIncome / 12;

    final expenses = widget.user.monthlyExpenses;

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
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        _pieTouchedIndex = -1;
                        return;
                      }
                      _pieTouchedIndex =
                          pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                centerSpaceRadius: 45,
                sectionsSpace: 3,
                sections: [
                  if (monthlyIncome > 0)
                    PieChartSectionData(
                      value: totalSip,
                      color: AppColors.green,
                      title: "SIP\n${((totalSip / monthlyIncome) * 100).toStringAsFixed(0)}%",
                      radius: _pieTouchedIndex == 0 ? 80 : 70,
                      titleStyle: AppText.label(size: _pieTouchedIndex == 0 ? 14 : 12, color: AppColors.blackMid),
                    ),
                  if (monthlyIncome > 0)
                    PieChartSectionData(
                      value: expenses,
                      color: Colors.redAccent,
                      title: "EXP\n${((expenses / monthlyIncome) * 100).toStringAsFixed(0)}%",
                      radius: _pieTouchedIndex == 1 ? 80 : 70,
                      titleStyle: AppText.label(size: _pieTouchedIndex == 1 ? 14 : 12, color: Colors.white),
                    ),
                  if (monthlyIncome > 0)
                    PieChartSectionData(
                      value: savings.toDouble(),
                      color: Colors.blueGrey,
                      title: "SAVE\n${((savings / monthlyIncome) * 100).toStringAsFixed(0)}%",
                      radius: _pieTouchedIndex == 2 ? 80 : 70,
                      titleStyle: AppText.label(size: _pieTouchedIndex == 2 ? 14 : 12, color: Colors.white),
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
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: AppColors.blackCard.withOpacity(0.9),
                    tooltipBorder: BorderSide(color: AppColors.green.withOpacity(0.5)),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        "${goals[groupIndex].name}\n",
                        AppText.label(color: AppColors.textMuted),
                        children: [
                          TextSpan(
                            text: _fmt(rod.toY),
                            style: AppText.data(size: 16),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppColors.green.withOpacity(0.05),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        if (value.toInt() >= goals.length) return const SizedBox();
                        final name = goals[value.toInt()].name;
                        final abbrev = name.length > 5 ? name.substring(0, 5) : name;
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            abbrev,
                            style: AppText.label(size: 10),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      getTitlesWidget: (value, meta) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            _fmt(value),
                            style: AppText.label(size: 10),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: goals.asMap().entries.map((entry) {
                  int index = entry.key;
                  final goal = entry.value;

                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: goal.monthlySip,
                        width: 22,
                        gradient: LinearGradient(
                          colors: goal.isFeasible
                              ? [AppColors.greenDim.withOpacity(0.6), AppColors.green]
                              : [Colors.red.withOpacity(0.6), Colors.redAccent],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: goals.isEmpty ? 0 : goals.map((e) => e.monthlySip).reduce((a, b) => a > b ? a : b) * 1.1,
                          color: AppColors.green.withOpacity(0.05),
                        ),
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
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: AppColors.blackCard.withOpacity(0.9),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          _fmt(spot.y),
                          AppText.data(size: 14),
                        );
                      }).toList();
                    },
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppColors.green.withOpacity(0.05),
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            "Yr ${value.toInt()}",
                            style: AppText.label(size: 10),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 55,
                      getTitlesWidget: (value, meta) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            _fmt(value),
                            style: AppText.label(size: 10),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    color: AppColors.green,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                        radius: 4,
                        color: AppColors.blackCard,
                        strokeWidth: 2,
                        strokeColor: AppColors.green,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.green.withOpacity(0.3),
                          AppColors.green.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    spots: List.generate(5, (index) {
                      final year = index + 1;

                      final projected = totalSip *
                          powValue(
                            (1 + widget.user.incomeRaisePct / 100),
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
              "Conflict Status: ${widget.conflict['overall_status'] ?? 'N/A'}",
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
    print(plan);
    double sip = 0;
    double corpus = 0;

    // 🟢 RETIREMENT
    if (plan.containsKey('corpus')) {
      final c = plan['corpus'] ?? {};

      sip = (c['monthly_sip'] ??
              c['starting_monthly_sip'] ??
              c['required_sip'] ??
              0)
          .toDouble();

      corpus = (c['required_corpus'] ?? 0).toDouble();
    }

    // 🟡 ONE-TIME GOAL
    else if (plan.containsKey('goal_summary')) {
      final sipPlan = plan['sip_plan'] ?? {};
      final summary = plan['goal_summary'] ?? {};

      sip = (sipPlan['starting_monthly_sip'] ??
              sipPlan['monthly_sip'] ??
              sipPlan['total_monthly_sip'] ??
              0)
          .toDouble();

      corpus = (summary['goal_amount_at_target'] ??
              summary['goal_amount_today'] ??
              0)
          .toDouble();
    }

    // 🔵 RECURRING GOAL
    else if (plan.containsKey('sip_plan')) {
      final sipPlan = plan['sip_plan'] ?? {};

      sip = (sipPlan['total_monthly_sip'] ?? 0).toDouble();

      // recurring usually doesn’t have corpus → keep 0
      corpus = 0;
    }

    return _GoalStats(
      name: plan['goal_name'] ?? defaultName,
      icon: icon,
      monthlySip: sip,
      targetCorpus: corpus,
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
