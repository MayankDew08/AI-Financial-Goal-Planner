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

  // ── Input field fill ──────────────────────────────────────────────────────
  // blackCard (0x0D1A10) is too dark as a TextFormField background — white
  // input text and hint text disappear against it. inputFill is lighter so
  // both read clearly while staying on-theme.
  static const Color inputFill = Color(0xFF152318);

  // ── Readable label / hint constants ──────────────────────────────────────
  // Replace inline withOpacity() calls that were producing colours too faint
  // to read on the dark backgrounds.
  static const Color fieldLabel =
      Color(0xFF7DC49A); // field labels (EMAIL ADDRESS etc.)
  static const Color hintText =
      Color(0xFF4A7A5A); // placeholder / hint inside inputs
}

// ── Shared TextStyles ─────────────────────────────────────────────────────────
class AppText {
  static const mono = 'Courier';

  static TextStyle label(
          {double size = 11, double spacing = 3, Color? color}) =>
      TextStyle(
        fontFamily: mono,
        fontSize: size,
        letterSpacing: spacing,
        // was textMuted@0.85 — fieldLabel is a solid colour, always readable
        color: color ?? AppColors.fieldLabel,
      );

  static TextStyle heading({double size = 30, Color color = Colors.white}) =>
      TextStyle(
        fontFamily: mono,
        fontSize: size,
        fontWeight: FontWeight.w900,
        letterSpacing: 2,
        color: color,
        height: 1.05,
      );

  static TextStyle body({double size = 13, Color? color}) => TextStyle(
        fontFamily: mono,
        fontSize: size,
        height: 1.7,
        // was textMuted@0.75 — full textMuted colour is legible on dark cards
        color: color ?? AppColors.textMuted,
      );
}

// ── User Model (mock / from onboarding) ──────────────────────────────────────
class UserProfile {
  final String name;
  final String maritalStatus;
  final int age;
  final double currentIncome;
  final double incomeRaisePct;
  final int? spouseAge;
  final double? spouseIncome;
  final double? spouseIncomeRaisePct;

  const UserProfile({
    required this.name,
    required this.maritalStatus,
    required this.age,
    required this.currentIncome,
    required this.incomeRaisePct,
    this.spouseAge,
    this.spouseIncome,
    this.spouseIncomeRaisePct,
  });

  bool get isMarried => maritalStatus.toLowerCase() == 'married';

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
      ..color = AppColors.green.withOpacity(0.025)
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
