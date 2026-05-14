import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'glide_path_widget.dart';

// Shared small widgets

class SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  const SectionLabel({super.key, required this.label, required this.icon});
  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, color: AppColors.green.withOpacity(0.6), size: 14),
        const SizedBox(width: 10),
        Text(label,
            style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 10,
                letterSpacing: 4,
                color: AppColors.green.withOpacity(0.7))),
      ]);
}

class StatusChip extends StatelessWidget {
  final String status;
  final Color color;
  const StatusChip({super.key, required this.status, required this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.4)),
            color: color.withOpacity(0.07)),
        child: Text(status.isEmpty ? '—' : status.toUpperCase(),
            style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 8,
                letterSpacing: 1,
                fontWeight: FontWeight.bold,
                color: color)),
      );
}

class MetricMini extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  const MetricMini(
      {super.key, required this.label, required this.value, this.valueColor});
  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 8,
                  letterSpacing: 1,
                  color: AppColors.textMuted.withOpacity(0.35))),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: valueColor ?? Colors.white)),
          ),
        ]),
      );
}

class AddGoalButton extends StatelessWidget {
  final VoidCallback onTap;
  const AddGoalButton({super.key, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
              border: Border.all(color: AppColors.green.withOpacity(0.35)),
              color: AppColors.green.withOpacity(0.04)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.add, color: AppColors.green.withOpacity(0.7), size: 16),
            const SizedBox(width: 10),
            Text('CREATE NEW GOAL',
                style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 11,
                    letterSpacing: 3,
                    color: AppColors.green.withOpacity(0.7))),
          ]),
        ),
      );
}

// Plan data decoder
Map<String, dynamic>? decodePlanData(Map<String, dynamic>? raw) {
  if (raw == null) return null;
  final result = Map<String, dynamic>.from(raw);

  final planData = result['plan_data'] ?? result['goal_data'];
  if (planData is String && planData.isNotEmpty) {
    try {
      final decoded = jsonDecode(planData) as Map<String, dynamic>?;
      if (decoded != null) {
        result['plan'] = decoded;
        decoded.forEach((k, v) => result.putIfAbsent(k, () => v));
      }
    } catch (_) {}
  }

  final plan = result['plan'];
  if (plan is String && plan.isNotEmpty) {
    try {
      final decoded = jsonDecode(plan) as Map<String, dynamic>?;
      if (decoded != null) result['plan'] = decoded;
    } catch (_) {}
  }

  final gp = result['glide_path'] ?? (result['plan'] as Map?)?['glide_path'];
  if (gp is String && gp.isNotEmpty) {
    try {
      final decoded = jsonDecode(gp);
      if (result.containsKey('glide_path')) {
        result['glide_path'] = decoded;
      } else if (result['plan'] is Map) {
        (result['plan'] as Map<String, dynamic>)['glide_path'] = decoded;
      }
    } catch (_) {}
  }

  return result;
}

// Formatting helpers
String label(String key) => key.replaceAll('_', ' ').trim().toUpperCase();

String fmt(String key, dynamic raw) {
  if (raw == null) return '—';
  final s = raw.toString().trim();
  if (s.isEmpty || s == 'null' || s == 'None') return '—';
  if (s.toLowerCase() == 'true') return 'YES';
  if (s.toLowerCase() == 'false') return 'NO';
  final n = num.tryParse(s);
  if (n == null) return s.length > 40 ? '${s.substring(0, 40)}…' : s;
  final lk = key.toLowerCase();
  if (lk.contains('pct') ||
      lk.contains('rate') ||
      lk.contains('return') ||
      lk.contains('percent') ||
      lk.contains('raise') ||
      lk.contains('yield') ||
      lk.contains('allocation') ||
      lk.contains('equity') ||
      lk.contains('debt')) {
    final isRatio = n.abs() <= 1.0;
    return isRatio
        ? '${(n * 100).toStringAsFixed(1)}%'
        : '${n.toStringAsFixed(1)}%';
  }
  if (lk.contains('age') ||
      lk.contains('year') ||
      lk.contains('duration') ||
      lk.contains('period') ||
      lk.contains('count') ||
      lk.contains('occurrence')) {
    return n.toInt().toString();
  }
  return fmtCurrency(raw);
}

String fmtCurrency(dynamic raw) {
  if (raw == null) return '—';
  final s = raw.toString().trim();
  final n = num.tryParse(s);
  if (n == null) return s.length > 30 ? '${s.substring(0, 30)}…' : s;
  final abs = n.abs();
  if (abs >= 10000000) return '₹${(n / 10000000).toStringAsFixed(2)} Cr';
  if (abs >= 100000) return '₹${(n / 100000).toStringAsFixed(2)} L';
  if (abs >= 1000) return '₹${(n / 1000).toStringAsFixed(1)} K';
  if (abs == 0) return '₹0';
  return '₹${n.toStringAsFixed(0)}';
}

// Generic key-value detail section
class DetailSection extends StatelessWidget {
  final String title;
  final Map<String, dynamic> data;
  const DetailSection({super.key, required this.title, required this.data});

  @override
  Widget build(BuildContext context) {
    final rows = data.entries
        .where((e) =>
            e.value != null &&
            e.value is! List &&
            e.value is! Map &&
            e.value.toString().isNotEmpty &&
            e.value.toString() != 'null')
        .toList();

    if (rows.isEmpty) return const SizedBox();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Text(title,
            style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 8,
                letterSpacing: 3,
                color: AppColors.green.withOpacity(0.45))),
      ),
      ...rows.asMap().entries.map((e) {
        final isLast = e.key == rows.length - 1;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: AppColors.green.withOpacity(0.05)),
              bottom: isLast
                  ? BorderSide.none
                  : BorderSide(color: AppColors.green.withOpacity(0.05)),
            ),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
                flex: 2,
                child: Text(label(e.value.key),
                    style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 9,
                        letterSpacing: 1,
                        color: AppColors.textMuted.withOpacity(0.35)))),
            const SizedBox(width: 8),
            Expanded(
                flex: 3,
                child: Text(fmt(e.value.key, e.value.value),
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMuted.withOpacity(0.75)))),
          ]),
        );
      }),
    ]);
  }
}

// Bucket strategy display
class BucketsSection extends StatelessWidget {
  final Map<String, dynamic> data;
  const BucketsSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Text('BUCKET STRATEGY',
            style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 8,
                letterSpacing: 3,
                color: AppColors.green.withOpacity(0.45))),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: Column(
          children: data.entries.map((bucket) {
            final bm = bucket.value is Map
                ? Map<String, dynamic>.from(bucket.value as Map)
                : <String, dynamic>{};
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.blackMid,
                border: Border.all(color: AppColors.green.withOpacity(0.1)),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bucket.key.toUpperCase().replaceAll('_', ' '),
                        style: TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 9,
                            letterSpacing: 2,
                            color: AppColors.green.withOpacity(0.65),
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...bm.entries
                        .where((e) =>
                            e.value != null &&
                            e.value is! List &&
                            e.value is! Map)
                        .map((e) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(children: [
                                Expanded(
                                    flex: 2,
                                    child: Text(label(e.key),
                                        style: TextStyle(
                                            fontFamily: 'Courier',
                                            fontSize: 9,
                                            color: AppColors.textMuted
                                                .withOpacity(0.35)))),
                                Text(fmt(e.key, e.value),
                                    style: TextStyle(
                                        fontFamily: 'Courier',
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textMuted
                                            .withOpacity(0.75))),
                              ]),
                            )),
                  ]),
            );
          }).toList(),
        ),
      ),
    ]);
  }
}

// Allocation equity/debt bar
class AllocationBar extends StatelessWidget {
  final Map<String, dynamic> data;
  const AllocationBar({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    double equity = 0;
    double debt = 0;
    data.forEach((k, v) {
      final lk = k.toLowerCase();
      final n = num.tryParse(v?.toString() ?? '')?.toDouble() ?? 0;
      if (lk.contains('equity')) equity = n > 1 ? n : n * 100;
      if (lk.contains('debt') || lk.contains('bond')) {
        debt = n > 1 ? n : n * 100;
      }
    });
    if (equity > 0 && debt == 0) debt = 100 - equity;
    if (equity == 0 && debt == 0) return const SizedBox();

    final eqI = equity.round().clamp(1, 99);
    final dtI = (100 - eqI).clamp(1, 99);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('ALLOCATION',
            style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 8,
                letterSpacing: 3,
                color: AppColors.green.withOpacity(0.45))),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
              flex: eqI, child: Container(height: 8, color: AppColors.green)),
          Expanded(
              flex: dtI,
              child: Container(
                  height: 8, color: AppColors.textMuted.withOpacity(0.18))),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          AllocLeg(color: AppColors.green, label: 'EQUITY', pct: eqI),
          const SizedBox(width: 20),
          AllocLeg(
              color: AppColors.textMuted.withOpacity(0.5),
              label: 'DEBT',
              pct: dtI),
        ]),
      ]),
    );
  }
}

class AllocLeg extends StatelessWidget {
  final Color color;
  final String label;
  final int pct;
  const AllocLeg(
      {super.key, required this.color, required this.label, required this.pct});
  @override
  Widget build(BuildContext context) => Row(children: [
        Container(width: 8, height: 8, color: color),
        const SizedBox(width: 6),
        Text('$label  $pct%',
            style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 9,
                color: AppColors.textMuted.withOpacity(0.5))),
      ]);
}

class OccHdr extends StatelessWidget {
  final String text;
  const OccHdr(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Expanded(
      child: Text(text,
          style: TextStyle(
              fontFamily: 'Courier',
              fontSize: 7,
              letterSpacing: 1,
              color: AppColors.green.withOpacity(0.5))));
}

class OccCell extends StatelessWidget {
  final String text;
  final Color? color;
  const OccCell(this.text, {super.key, this.color});
  @override
  Widget build(BuildContext context) => Expanded(
      child: Text(text,
          style: TextStyle(
              fontFamily: 'Courier',
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color ?? AppColors.textMuted.withOpacity(0.65))));
}

class OccurrenceTable extends StatelessWidget {
  final List items;
  const OccurrenceTable({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final rows = items.take(6).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Text('OCCURRENCE PLANS',
            style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 8,
                letterSpacing: 3,
                color: AppColors.green.withOpacity(0.45))),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: Container(
          decoration: BoxDecoration(
              border: Border.all(color: AppColors.green.withOpacity(0.1))),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: AppColors.green.withOpacity(0.05),
              child: const Row(children: [
                OccHdr('OCC.'),
                OccHdr('COST'),
                OccHdr('SIP'),
              ]),
            ),
            ...rows.asMap().entries.map((e) {
              final row = e.value is Map
                  ? Map<String, dynamic>.from(e.value as Map)
                  : <String, dynamic>{};
              final isLast = e.key == rows.length - 1;
              final occ =
                  row['occurrence']?.toString() ?? (e.key + 1).toString();
              final cost = fmtCurrency(
                  row['cost'] ?? row['inflated_cost'] ?? row['goal_cost']);
              final sip = fmtCurrency(row['monthly_sip'] ?? row['sip']);
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: isLast
                    ? null
                    : BoxDecoration(
                        border: Border(
                            bottom: BorderSide(
                                color: AppColors.green.withOpacity(0.05)))),
                child: Row(children: [
                  OccCell(occ),
                  OccCell(cost),
                  OccCell(sip, color: AppColors.green.withOpacity(0.8)),
                ]),
              );
            }),
          ]),
        ),
      ),
    ]);
  }
}
