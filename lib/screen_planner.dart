import 'package:flutter/material.dart';
import 'app_theme.dart';

class PlannerScreen extends StatelessWidget {
  final UserProfile user;
  const PlannerScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          CustomPaint(size: MediaQuery.of(context).size, painter: GridPainter()),

          // Bottom-left glow
          Positioned(
            bottom: -60, left: -60,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.green.withOpacity(0.06),
                  Colors.transparent,
                ]),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 28),
                  _buildApiBadge(),
                  const SizedBox(height: 28),
                  _buildSectionLabel('RETIREMENT PLANNING'),
                  const SizedBox(height: 16),
                  _buildRetirementCard(),
                  const SizedBox(height: 20),
                  _buildSectionLabel('INVESTMENT PROJECTION'),
                  const SizedBox(height: 16),
                  _buildInvestmentCard(),
                  const SizedBox(height: 20),
                  _buildSectionLabel('PROJECTION SUMMARY'),
                  const SizedBox(height: 16),
                  _buildProjectionSummaryRow(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 20, height: 1, color: AppColors.green),
            const SizedBox(width: 10),
            Text('FINANCIAL PLANNER', style: TextStyle(fontFamily: 'Courier', fontSize: 9, letterSpacing: 4, color: AppColors.green.withOpacity(0.6))),
          ],
        ),
        const SizedBox(height: 12),
        const Text('PLAN YOUR\nFUTURE.', style: TextStyle(fontFamily: 'Courier', fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 2, height: 1.0, color: Colors.white)),
        const SizedBox(height: 10),
        Text(
          'Powered by the /calculation API.\nInputs pre-filled from your profile.',
          style: TextStyle(fontFamily: 'Courier', fontSize: 11, height: 1.7, color: AppColors.textMuted.withOpacity(0.4)),
        ),
      ],
    );
  }

  Widget _buildApiBadge() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.green.withOpacity(0.15)),
        color: AppColors.green.withOpacity(0.04),
      ),
      child: Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              color: AppColors.green.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '/calculation  API — not yet connected. Run buttons will trigger calculations once linked.',
              style: TextStyle(fontFamily: 'Courier', fontSize: 10, height: 1.6, color: AppColors.textMuted.withOpacity(0.4)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Retirement Card ────────────────────────────────────────────────────────
  Widget _buildRetirementCard() {
    final yearsToRetire = 60 - user.age;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.blackCard,
        border: Border.all(color: AppColors.green.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.green.withOpacity(0.1))),
            ),
            child: Row(
              children: [
                Icon(Icons.self_improvement_outlined, color: AppColors.green, size: 20),
                const SizedBox(width: 12),
                const Text('RETIREMENT PLANNER', style: TextStyle(fontFamily: 'Courier', fontSize: 12, letterSpacing: 3, fontWeight: FontWeight.bold, color: Colors.white)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  color: AppColors.green.withOpacity(0.1),
                  child: Text('AGE 60 TARGET', style: TextStyle(fontFamily: 'Courier', fontSize: 8, letterSpacing: 2, color: AppColors.green.withOpacity(0.7))),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Key figures
                Row(
                  children: [
                    Expanded(child: _PlannerStat(label: 'CURRENT AGE',    value: '${user.age}')),
                    Expanded(child: _PlannerStat(label: 'TARGET AGE',     value: '60')),
                    Expanded(child: _PlannerStat(label: 'YEARS LEFT',     value: '$yearsToRetire')),
                  ],
                ),
                const SizedBox(height: 20),
                // Fake progress bar
                Text('RETIREMENT READINESS', style: TextStyle(fontFamily: 'Courier', fontSize: 9, letterSpacing: 3, color: AppColors.textMuted.withOpacity(0.4))),
                const SizedBox(height: 8),
                Stack(
                  children: [
                    Container(height: 6, color: AppColors.green.withOpacity(0.1)),
                    FractionallySizedBox(
                      widthFactor: 0.28, // placeholder %
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppColors.green,
                          boxShadow: [BoxShadow(color: AppColors.green.withOpacity(0.5), blurRadius: 6)],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('28% — connect API for live calculation', style: TextStyle(fontFamily: 'Courier', fontSize: 9, letterSpacing: 1, color: AppColors.textMuted.withOpacity(0.3))),
                const SizedBox(height: 20),
                _buildRunButton('RUN RETIREMENT CALCULATION', Icons.play_arrow_rounded),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Investment Card ────────────────────────────────────────────────────────
  Widget _buildInvestmentCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.blackCard,
        border: Border.all(color: AppColors.green.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.green.withOpacity(0.1))),
            ),
            child: Row(
              children: [
                Icon(Icons.show_chart, color: AppColors.green, size: 20),
                const SizedBox(width: 12),
                const Text('INVESTMENT PROJECTION', style: TextStyle(fontFamily: 'Courier', fontSize: 12, letterSpacing: 3, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Projection scenarios
                _ScenarioRow(label: 'CONSERVATIVE  (6% p.a.)', multiplier: '2.8x', color: AppColors.textMuted.withOpacity(0.6)),
                const SizedBox(height: 10),
                _ScenarioRow(label: 'MODERATE      (9% p.a.)', multiplier: '4.2x', color: AppColors.green),
                const SizedBox(height: 10),
                _ScenarioRow(label: 'AGGRESSIVE   (12% p.a.)', multiplier: '6.7x', color: AppColors.greenDim),
                const SizedBox(height: 8),
                Text('*Corpus multiplier over ${60 - user.age} years. For illustration only.',
                    style: TextStyle(fontFamily: 'Courier', fontSize: 8, letterSpacing: 1, color: AppColors.textMuted.withOpacity(0.25))),
                const SizedBox(height: 20),
                _buildRunButton('RUN INVESTMENT PROJECTION', Icons.play_arrow_rounded),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Summary Row ────────────────────────────────────────────────────────────
  Widget _buildProjectionSummaryRow() {
    return Row(
      children: [
        Expanded(child: _SummaryBox(label: 'EST. CORPUS', value: '—', note: 'API pending')),
        const SizedBox(width: 12),
        Expanded(child: _SummaryBox(label: 'MONTHLY SIP', value: '—', note: 'API pending')),
      ],
    );
  }

  Widget _buildRunButton(String label, IconData icon) => GestureDetector(
        onTap: () {},
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          color: AppColors.green,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.black, size: 16),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontFamily: 'Courier', fontSize: 11, letterSpacing: 3, fontWeight: FontWeight.bold, color: AppColors.black)),
            ],
          ),
        ),
      );

  Widget _buildSectionLabel(String title) => Row(
        children: [
          Container(width: 20, height: 1, color: AppColors.green),
          const SizedBox(width: 10),
          Text(title, style: TextStyle(fontFamily: 'Courier', fontSize: 10, letterSpacing: 4, color: AppColors.green.withOpacity(0.7))),
        ],
      );
}

class _PlannerStat extends StatelessWidget {
  final String label, value;
  const _PlannerStat({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontFamily: 'Courier', fontSize: 8, letterSpacing: 2, color: AppColors.textMuted.withOpacity(0.35))),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontFamily: 'Courier', fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.green, shadows: [Shadow(color: AppColors.green.withOpacity(0.3), blurRadius: 10)])),
        ],
      );
}

class _ScenarioRow extends StatelessWidget {
  final String label, multiplier;
  final Color color;
  const _ScenarioRow({required this.label, required this.multiplier, required this.color});
  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(width: 3, height: 32, color: color),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: TextStyle(fontFamily: 'Courier', fontSize: 10, letterSpacing: 1, color: AppColors.textMuted.withOpacity(0.5)))),
          Text(multiplier, style: TextStyle(fontFamily: 'Courier', fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      );
}

class _SummaryBox extends StatelessWidget {
  final String label, value, note;
  const _SummaryBox({required this.label, required this.value, required this.note});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.blackCard,
          border: Border.all(color: AppColors.green.withOpacity(0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontFamily: 'Courier', fontSize: 8, letterSpacing: 2, color: AppColors.textMuted.withOpacity(0.35))),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontFamily: 'Courier', fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 4),
            Text(note, style: TextStyle(fontFamily: 'Courier', fontSize: 8, letterSpacing: 2, color: AppColors.textMuted.withOpacity(0.25))),
          ],
        ),
      );
}
