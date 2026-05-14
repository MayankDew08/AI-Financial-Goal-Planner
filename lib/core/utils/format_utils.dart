// lib/core/utils/format_utils.dart
// Utility functions for formatting API results

// Flattens one level of nesting; skips arrays and deeply nested maps (rendered separately)
Map<String, dynamic> flattenResult(Map<String, dynamic> raw) {
  final out = <String, dynamic>{};
  raw.forEach((k, v) {
    if (v is Map<String, dynamic>) {
      v.forEach((ik, iv) {
        if (iv is! List && iv is! Map) out[ik] = iv;
      });
    } else if (v is! List) {
      out[k] = v;
    }
  });
  return out;
}

// Collects array/list fields separately for table rendering
List<MapEntry<String, List>> extractLists(Map<String, dynamic> raw) {
  final out = <MapEntry<String, List>>[];
  raw.forEach((k, v) {
    if (v is List && v.isNotEmpty) out.add(MapEntry(k, v));
  });
  return out;
}

String smartFmt(String key, dynamic raw) {
  if (raw == null) return '—';
  final s = raw.toString().trim();
  if (s.isEmpty || s == 'null' || s == 'None') return '—';
  final n = num.tryParse(s);
  if (n == null) {
    if (s.toLowerCase() == 'true') return 'YES';
    if (s.toLowerCase() == 'false') return 'NO';
    // Truncate very long strings
    return s.length > 40 ? '${s.substring(0, 40)}…' : s;
  }
  final lk = key.toLowerCase();
  if (lk.contains('pct') ||
      lk.contains('rate') ||
      lk.contains('return') ||
      lk.contains('percent') ||
      lk.contains('raise') ||
      lk.contains('yield')) {
    return '${n.toStringAsFixed(1)}%';
  }
  if (lk.contains('age') ||
      lk.contains('year') ||
      lk.contains('duration') ||
      lk.contains('period') ||
      lk.contains('count')) {
    return n.toInt().toString();
  }
  final abs = n.abs();
  if (abs >= 10000000) return '₹${(n / 10000000).toStringAsFixed(2)} Cr';
  if (abs >= 100000) return '₹${(n / 100000).toStringAsFixed(2)} L';
  if (abs >= 1000) return '₹${(n / 1000).toStringAsFixed(1)} K';
  if (abs > 0 && abs < 1) return n.toStringAsFixed(4);
  return n % 1 == 0 ? n.toInt().toString() : n.toStringAsFixed(2);
}

String labelFor(String key) => key.replaceAll('_', ' ').trim().toUpperCase();

bool isPrimaryKey(String key, dynamic value) {
  final lk = key.toLowerCase();
  final n = num.tryParse(value?.toString() ?? '');
  if (n == null) return false;
  if (lk.contains('inflation') ||
      lk.contains('raise') ||
      lk.contains('input') ||
      lk == 'years' ||
      lk == 'age') return false;
  if (lk.contains('sip') ||
      lk.contains('corpus') ||
      lk.contains('required') ||
      lk.contains('monthly') ||
      lk.contains('future') ||
      lk.contains('value') ||
      lk.contains('maturity') ||
      lk.contains('target') ||
      lk.contains('shortfall') ||
      lk.contains('surplus') ||
      lk.contains('saving') ||
      lk.contains('result') ||
      lk.contains('amount') ||
      lk.contains('fund')) return true;
  return n.abs() >= 1000;
}
