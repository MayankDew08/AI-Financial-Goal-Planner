import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/portfolio_helpers.dart';

class GoalDetailsScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String status;
  final Color statusColor;
  final Widget previewMetrics;
  final Widget detailWidget;

  const GoalDetailsScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.status,
    required this.statusColor,
    required this.previewMetrics,
    required this.detailWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        elevation: 0,
        leading: const BackButton(color: AppColors.green),
        title: Text('GOAL DETAILS',
            style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
                color: AppColors.green.withOpacity(0.8))),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          CustomPaint(
              size: MediaQuery.of(context).size, painter: GridPainter()),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.blackCard,
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: statusColor.withOpacity(0.3)),
                                  color: statusColor.withOpacity(0.08),
                                ),
                                child: Icon(icon, color: statusColor, size: 24),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title.toUpperCase(),
                                      style: const TextStyle(
                                          fontFamily: 'Courier',
                                          fontSize: 13,
                                          letterSpacing: 1.5,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      subtitle,
                                      style: TextStyle(
                                          fontFamily: 'Courier',
                                          fontSize: 10,
                                          color: AppColors.textMuted
                                              .withOpacity(0.5)),
                                    ),
                                  ],
                                ),
                              ),
                              StatusChip(status: status, color: statusColor),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: previewMetrics,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  detailWidget,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
