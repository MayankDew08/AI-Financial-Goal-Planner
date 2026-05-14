import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class GoalTemplate {
  final IconData icon;
  final String title, tag;
  const GoalTemplate(
      {required this.icon, required this.title, required this.tag});
}

class GoalCard extends StatelessWidget {
  final GoalTemplate template;
  final VoidCallback onTap;
  const GoalCard({super.key, required this.template, required this.onTap});

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
