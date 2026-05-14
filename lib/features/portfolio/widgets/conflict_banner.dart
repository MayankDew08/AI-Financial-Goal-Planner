import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class ConflictBanner extends StatelessWidget {
  final Map<String, dynamic> data;
  const ConflictBanner({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final status = (data['overall_status'] as String? ?? '').toLowerCase();
    final isGood = status == 'all_clear';
    final isWarn =
        status.contains('warning') || status.contains('under_saving');

    final color = isGood
        ? AppColors.green
        : isWarn
            ? const Color(0xFFFFA500)
            : AppColors.error;

    final label = isGood
        ? 'ALL CLEAR'
        : isWarn
            ? 'UNDER SAVING'
            : 'CONFLICT DETECTED';

    final icon = isGood
        ? Icons.check_circle_outline
        : isWarn
            ? Icons.warning_amber_rounded
            : Icons.error_outline;

    final desc = isGood
        ? 'Your goals are on track. Keep investing consistently.'
        : isWarn
            ? 'Your current savings may not cover all goals.'
            : 'Your goals are competing. Review priorities.';

    final waterfall = data['surplus_waterfall'] as Map<String, dynamic>?;
    final funded = waterfall?['funded'] as List? ?? [];
    final deferred = waterfall?['deferred'] as List? ?? [];

    return Container(
      decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          border: Border.all(color: color.withOpacity(0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 10),
            Expanded(
                child: Text(label,
                    style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 11,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                        color: color))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  border: Border.all(color: color.withOpacity(0.3))),
              child: Text('PORTFOLIO HEALTH',
                  style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 7,
                      letterSpacing: 2,
                      color: color.withOpacity(0.6))),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: Text(desc,
              style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 10,
                  height: 1.6,
                  color: AppColors.textMuted.withOpacity(0.45))),
        ),

        if (funded.isNotEmpty || deferred.isNotEmpty) ...[
          Container(height: 1, color: color.withOpacity(0.1)),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (funded.isNotEmpty)
                Expanded(
                    child: WaterfallCol(
                        label: 'FUNDED',
                        items: funded,
                        color: AppColors.green)),
              if (funded.isNotEmpty && deferred.isNotEmpty)
                const SizedBox(width: 12),
              if (deferred.isNotEmpty)
                Expanded(
                    child: WaterfallCol(
                        label: 'DEFERRED',
                        items: deferred,
                        color: AppColors.error.withOpacity(0.7))),
            ]),
          ),
        ],
      ]),
    );
  }
}

class WaterfallCol extends StatelessWidget {
  final String label;
  final List items;
  final Color color;
  const WaterfallCol(
      {super.key, required this.label, required this.items, required this.color});

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 8,
                letterSpacing: 2,
                color: color.withOpacity(0.7))),
        const SizedBox(height: 6),
        ...items.map((item) {
          final name = item is Map
              ? (item['goal_name'] ?? item['name'] ?? item.toString())
              : item.toString();
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(children: [
              Container(
                  width: 5,
                  height: 5,
                  decoration:
                      BoxDecoration(shape: BoxShape.circle, color: color)),
              const SizedBox(width: 7),
              Expanded(
                  child: Text(name.toString(),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 9,
                          color: AppColors.textMuted.withOpacity(0.55)))),
            ]),
          );
        }),
      ]);
}
