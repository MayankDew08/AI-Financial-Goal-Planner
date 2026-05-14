// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

// ── App Colors ────────────────────────────────────────────────────────────────
class AppColors {
  static const Color green = Color(0xFF00FF7F);
  static const Color greenDim = Color(0xFF00C45F);
  static const Color black = Color(0xFF020805);
  static const Color blackMid = Color(0xFF0A120D);
  static const Color blackCard = Color(0xFF0D1A10);
  static const Color blackBorder = Color(0xFF162318);
  static const Color textMuted = Color(0xFFC8F0D5);
  static const Color error = Color(0xFFFF4F4F);

  // Filled in — previously null, which caused invisible inputs
  static Color get inputFill => blackCard;
  static Color get hintText => textMuted.withOpacity(0.45);
}

// ── Shared TextStyles ─────────────────────────────────────────────────────────
class AppText {
  static const mono = 'Courier';

  /// Uppercase label / caption text (e.g. section headers, tags)
  /// Size bumped 10 → 13, opacity 0.65 → 0.80 for legibility
  static TextStyle label(
          {double size = 13, double spacing = 2.5, Color? color}) =>
      TextStyle(
        fontFamily: mono,
        fontSize: size,
        letterSpacing: spacing,
        color: color ?? AppColors.green.withOpacity(0.80),
      );

  /// Primary headings — size bumped 28 → 32
  static TextStyle heading({double size = 32, Color color = Colors.white}) =>
      TextStyle(
        fontFamily: mono,
        fontSize: size,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5, // slightly tighter — less gap between letters
        color: color,
        height: 1.1,
      );

  /// Body / paragraph text
  /// Size bumped 12 → 15, opacity lifted 0.5 → 0.85 — the biggest readability win
  static TextStyle body({double size = 15, Color? color}) => TextStyle(
        fontFamily: mono,
        fontSize: size,
        height: 1.65,
        color: color ?? AppColors.textMuted.withOpacity(0.85),
      );

  /// New: small numeric / data value style (dashboards, stats)
  static TextStyle data({double size = 22, Color? color}) => TextStyle(
        fontFamily: mono,
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
        color: color ?? AppColors.green,
        height: 1.2,
      );
}

// ── User Model (mock / from onboarding) ──────────────────────────────────────
class UserProfile {
  final String name;
  final String maritalStatus;
  final int age;
  final double currentIncome;
  final double incomeRaisePct;
  final double inflationRate;
  final double monthlyExpenses;
  final int? spouseAge;
  final double? spouseIncome;
  final double? spouseIncomeRaisePct;

  const UserProfile({
    required this.name,
    required this.maritalStatus,
    required this.age,
    required this.currentIncome,
    required this.incomeRaisePct,
    this.inflationRate = 6.0,
    this.monthlyExpenses = 0.0,
    this.spouseAge,
    this.spouseIncome,
    this.spouseIncomeRaisePct,
  });

  bool get isMarried => maritalStatus.toLowerCase() == 'married';

  // Mock data — replace with SharedPreferences / state management later
  static const UserProfile mock = UserProfile(
    name: 'Alex',
    maritalStatus: 'married',
    age: 32,
    currentIncome: 85000,
    incomeRaisePct: 6.5,
    spouseAge: 29,
    spouseIncome: 62000,
    spouseIncomeRaisePct: 4.0,
  );
}

// ── Grid Background Painter (shared) ─────────────────────────────────────────
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.green.withOpacity(0.03) // slightly more visible
      ..strokeWidth = 1;
    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
