import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format_utils.dart';

class ApiResultCard extends StatelessWidget {
  final Map<String, dynamic> rawData;
  final String title;

  const ApiResultCard({super.key, required this.rawData, required this.title});

  @override
  Widget build(BuildContext context) {
    final data = flattenResult(rawData);
    final lists = extractLists(rawData);

    if (data.isEmpty && lists.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: AppColors.blackCard,
            border: Border.all(color: AppColors.green.withOpacity(0.15))),
        child: Text('No result data.',
            style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 11,
                color: AppColors.textMuted.withOpacity(0.4))),
      );
    }

    final primary =
        data.entries.where((e) => isPrimaryKey(e.key, e.value)).toList();
    final secondary =
        data.entries.where((e) => !isPrimaryKey(e.key, e.value)).toList();
    final heroes = primary.isNotEmpty
        ? primary
        : data.entries
            .where((e) => num.tryParse(e.value?.toString() ?? '') != null)
            .toList();
    final details = primary.isNotEmpty
        ? secondary
        : data.entries
            .where((e) => num.tryParse(e.value?.toString() ?? '') == null)
            .toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // ── Section header ───────────────────────────────────────────────────
      Row(children: [
        Container(width: 20, height: 1, color: AppColors.green),
        const SizedBox(width: 10),
        Expanded(
            child: Text(title,
                style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 10,
                    letterSpacing: 4,
                    color: AppColors.green.withOpacity(0.7)))),
      ]),
      const SizedBox(height: 16),

      // ── Hero tiles ───────────────────────────────────────────────────────
      if (heroes.isNotEmpty) ...[
        ...List.generate((heroes.length / 2).ceil(), (i) {
          final left = heroes[i * 2];
          final right = (i * 2 + 1 < heroes.length) ? heroes[i * 2 + 1] : null;
          return Padding(
            padding: EdgeInsets.only(
                bottom: i < (heroes.length / 2).ceil() - 1 ? 10 : 0),
            child: Row(children: [
              Expanded(
                  child: ResultHeroTile(
                      label: labelFor(left.key),
                      value: smartFmt(left.key, left.value))),
              const SizedBox(width: 10),
              Expanded(
                  child: right != null
                      ? ResultHeroTile(
                          label: labelFor(right.key),
                          value: smartFmt(right.key, right.value))
                      : const SizedBox()),
            ]),
          );
        }),
        const SizedBox(height: 12),
      ],

      // ── Detail rows ──────────────────────────────────────────────────────
      if (details.isNotEmpty)
        Container(
          decoration: BoxDecoration(
              color: AppColors.blackCard,
              border: Border.all(color: AppColors.green.withOpacity(0.1))),
          child: Column(
            children: details.asMap().entries.map((e) {
              final isLast = e.key == details.length - 1 && lists.isEmpty;
              final val = e.value.value;
              final fmtVal = smartFmt(e.value.key, val);
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                decoration: isLast
                    ? null
                    : BoxDecoration(
                        border: Border(
                            bottom: BorderSide(
                                color: AppColors.green.withOpacity(0.06)))),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(labelFor(e.value.key),
                          style: TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 9,
                              letterSpacing: 1,
                              color: AppColors.textMuted.withOpacity(0.35))),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: Text(fmtVal,
                          textAlign: TextAlign.right,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textMuted.withOpacity(0.75))),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),

      // ── Array tables (glide_path, buckets, etc.) ─────────────────────────
      for (final listEntry in lists) ...[
        const SizedBox(height: 16),
        ArrayTable(label: labelFor(listEntry.key), items: listEntry.value),
      ],
    ]);
  }
}

class ArrayTable extends StatelessWidget {
  final String label;
  final List items;
  const ArrayTable({super.key, required this.label, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox();
    
    // Extract column headers from first item (if it's a map)
    final firstItem = items.first;
    if (firstItem is! Map) {
      // Simple list of scalars
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _miniLabel(label),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: items
              .take(12)
              .map((item) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.blackCard,
                      border:
                          Border.all(color: AppColors.green.withOpacity(0.15)),
                    ),
                    child: Text(item.toString(),
                        style: TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 10,
                            color: AppColors.textMuted.withOpacity(0.6))),
                  ))
              .toList(),
        ),
      ]);
    }

    // Map list — show as a mini table (max 6 rows to avoid wall of data)
    final mapItems =
        items.take(6).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final cols = mapItems.first.keys.take(4).toList(); // max 4 columns

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _miniLabel(label),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
          color: AppColors.blackCard,
          border: Border.all(color: AppColors.green.withOpacity(0.1)),
        ),
        child: Column(children: [
          // Header row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: AppColors.green.withOpacity(0.12))),
              color: AppColors.green.withOpacity(0.05),
            ),
            child: Row(
                children: cols
                    .map((c) => Expanded(
                          child: Text(labelFor(c.toString()),
                              style: TextStyle(
                                  fontFamily: 'Courier',
                                  fontSize: 7,
                                  letterSpacing: 1,
                                  color: AppColors.green.withOpacity(0.5)),
                              overflow: TextOverflow.ellipsis),
                        ))
                    .toList()),
          ),
          // Data rows
          ...mapItems.asMap().entries.map((e) {
            final isLast = e.key == mapItems.length - 1;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: isLast
                  ? null
                  : BoxDecoration(
                      border: Border(
                          bottom: BorderSide(
                              color: AppColors.green.withOpacity(0.05)))),
              child: Row(
                  children: cols.map((c) {
                final v = e.value[c];
                return Expanded(
                  child: Text(smartFmt(c.toString(), v),
                      style: TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMuted.withOpacity(0.7)),
                      overflow: TextOverflow.ellipsis),
                );
              }).toList()),
            );
          }),
          // "...N more" indicator
          if (items.length > 6)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                  border: Border(
                      top: BorderSide(
                          color: AppColors.green.withOpacity(0.08)))),
              child: Text('+ ${items.length - 6} more rows',
                  style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 9,
                      color: AppColors.textMuted.withOpacity(0.3))),
            ),
        ]),
      ),
    ]);
  }

  Widget _miniLabel(String text) => Row(children: [
        Container(
            width: 12, height: 1, color: AppColors.green.withOpacity(0.4)),
        const SizedBox(width: 8),
        Text(text,
            style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 9,
                letterSpacing: 3,
                color: AppColors.green.withOpacity(0.5))),
      ]);
}

class ResultHeroTile extends StatelessWidget {
  final String label, value;
  const ResultHeroTile({super.key, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.blackCard,
          border: Border.all(color: AppColors.green.withOpacity(0.4)),
          boxShadow: [
            BoxShadow(color: AppColors.green.withOpacity(0.04), blurRadius: 12)
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 8,
                  letterSpacing: 2,
                  color: AppColors.textMuted.withOpacity(0.4))),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.green,
                  shadows: [
                    Shadow(
                        color: AppColors.green.withOpacity(0.35),
                        blurRadius: 10)
                  ],
                )),
          ),
        ]),
      );
}
