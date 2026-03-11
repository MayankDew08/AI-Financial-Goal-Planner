// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'app_theme.dart';

class ProfileScreen extends StatelessWidget {
  final UserProfile user;
  const ProfileScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          CustomPaint(
              size: MediaQuery.of(context).size, painter: GridPainter()),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 28),
                  _buildAvatar(),
                  const SizedBox(height: 28),
                  _buildSectionLabel('PERSONAL DETAILS'),
                  const SizedBox(height: 16),
                  _buildPersonalCard(),
                  const SizedBox(height: 20),
                  _buildSectionLabel('INCOME DETAILS'),
                  const SizedBox(height: 16),
                  _buildIncomeCard(),
                  if (user.isMarried) ...[
                    const SizedBox(height: 20),
                    _buildSectionLabel('SPOUSE DETAILS'),
                    const SizedBox(height: 16),
                    _buildSpouseCard(),
                  ],
                  const SizedBox(height: 32),
                  _buildEditButton(context),
                  const SizedBox(height: 16),
                  _buildSignOutButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(width: 20, height: 1, color: AppColors.green),
              const SizedBox(width: 10),
              Text('MY PROFILE',
                  style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 9,
                      letterSpacing: 4,
                      color: AppColors.green.withOpacity(0.6))),
            ]),
            const SizedBox(height: 10),
            const Text('ACCOUNT\nOVERVIEW.',
                style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    height: 1.0,
                    color: Colors.white)),
          ],
        ),
      ],
    );
  }

  Widget _buildAvatar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.blackCard,
        border: Border.all(color: AppColors.green.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          // Avatar circle
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.green, width: 1.5),
              color: AppColors.green.withOpacity(0.08),
            ),
            child: Center(
              child: Text(
                user.name[0].toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.green,
                  shadows: [
                    Shadow(
                        color: AppColors.green.withOpacity(0.4), blurRadius: 12)
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.name.toUpperCase(),
                  style: const TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                      color: Colors.white)),
              const SizedBox(height: 6),
              _StatusBadge(status: user.maritalStatus),
              const SizedBox(height: 6),
              Text('MEMBER SINCE 2025',
                  style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 9,
                      letterSpacing: 2,
                      color: AppColors.textMuted.withOpacity(0.3))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalCard() {
    return _InfoCard(
      rows: [
        _InfoRow(label: 'FULL NAME', value: user.name.toUpperCase()),
        _InfoRow(label: 'AGE', value: '${user.age} years'),
        _InfoRow(
            label: 'MARITAL STATUS', value: user.maritalStatus.toUpperCase()),
      ],
    );
  }

  Widget _buildIncomeCard() {
    return _InfoCard(
      rows: [
        _InfoRow(
          label: 'ANNUAL INCOME',
          value: '\$${user.currentIncome.toStringAsFixed(2)}',
          highlight: true,
        ),
        _InfoRow(
          label: 'EXPECTED RAISE',
          value: '${user.incomeRaisePct}% per year',
        ),
        _InfoRow(
          label: 'MONTHLY INCOME',
          value: '\$${(user.currentIncome / 12).toStringAsFixed(2)}',
        ),
      ],
    );
  }

  Widget _buildSpouseCard() {
    return _InfoCard(
      accentColor: AppColors.greenDim,
      rows: [
        _InfoRow(
            label: "SPOUSE'S AGE", value: '${user.spouseAge ?? "—"} years'),
        _InfoRow(
            label: "SPOUSE'S INCOME",
            value: user.spouseIncome != null
                ? '\$${user.spouseIncome!.toStringAsFixed(2)}'
                : '—',
            highlight: true),
        _InfoRow(
            label: "SPOUSE'S RAISE",
            value: user.spouseIncomeRaisePct != null
                ? '${user.spouseIncomeRaisePct}% per year'
                : '—'),
      ],
    );
  }

  Widget _buildEditButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to UserOnboardingPage with pre-filled data
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.blackCard,
            content: Text('Edit profile — connect to UserOnboardingPage',
                style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 11,
                    color: AppColors.green)),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        color: AppColors.green,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit_outlined, color: AppColors.black, size: 16),
            SizedBox(width: 10),
            Text('EDIT PROFILE',
                style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 12,
                    letterSpacing: 4,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black)),
          ],
        ),
      ),
    );
  }

  Widget _buildSignOutButton() {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.textMuted.withOpacity(0.12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout,
                color: AppColors.textMuted.withOpacity(0.35), size: 16),
            const SizedBox(width: 10),
            Text('SIGN OUT',
                style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 12,
                    letterSpacing: 4,
                    color: AppColors.textMuted.withOpacity(0.35))),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String title) => Row(
        children: [
          Container(width: 20, height: 1, color: AppColors.green),
          const SizedBox(width: 10),
          Text(title,
              style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 10,
                  letterSpacing: 4,
                  color: AppColors.green.withOpacity(0.7))),
        ],
      );
}

// ── Reusable Widgets ──────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.green.withOpacity(0.3)),
          color: AppColors.green.withOpacity(0.07),
        ),
        child: Text(status.toUpperCase(),
            style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 9,
                letterSpacing: 3,
                color: AppColors.green.withOpacity(0.7))),
      );
}

class _InfoRow {
  final String label, value;
  final bool highlight;
  const _InfoRow(
      {required this.label, required this.value, this.highlight = false});
}

class _InfoCard extends StatelessWidget {
  final List<_InfoRow> rows;
  final Color? accentColor;
  const _InfoCard({required this.rows, this.accentColor});

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? AppColors.green;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.blackCard,
        border: Border.all(color: accent.withOpacity(0.15)),
      ),
      child: Column(
        children: rows.asMap().entries.map((e) {
          final i = e.key;
          final row = e.value;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              border: i < rows.length - 1
                  ? Border(bottom: BorderSide(color: accent.withOpacity(0.07)))
                  : null,
            ),
            child: Row(
              children: [
                Text(row.label,
                    style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 10,
                        letterSpacing: 2,
                        color: AppColors.textMuted.withOpacity(0.4))),
                const Spacer(),
                Text(
                  row.value,
                  style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 13,
                    fontWeight:
                        row.highlight ? FontWeight.bold : FontWeight.normal,
                    letterSpacing: 1,
                    color: row.highlight ? accent : Colors.white,
                    shadows: row.highlight
                        ? [
                            Shadow(
                                color: accent.withOpacity(0.3), blurRadius: 8)
                          ]
                        : null,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
