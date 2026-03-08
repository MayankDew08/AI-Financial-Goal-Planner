import 'package:flutter/material.dart';
import 'app_theme.dart';

class GoalsScreen extends StatelessWidget {
  final UserProfile user;
  const GoalsScreen({super.key, required this.user});

  // Placeholder goal types — will connect to /goals API later
  static const _goalTemplates = [
    _GoalTemplate(icon: Icons.house_outlined,       title: 'BUY A HOME',          tag: 'PROPERTY'),
    _GoalTemplate(icon: Icons.school_outlined,       title: 'EDUCATION FUND',      tag: 'EDUCATION'),
    _GoalTemplate(icon: Icons.beach_access_outlined, title: 'EARLY RETIREMENT',    tag: 'RETIREMENT'),
    _GoalTemplate(icon: Icons.directions_car_outlined,title: 'BUY A VEHICLE',      tag: 'LIFESTYLE'),
    _GoalTemplate(icon: Icons.flight_outlined,       title: 'TRAVEL FUND',         tag: 'LIFESTYLE'),
    _GoalTemplate(icon: Icons.savings_outlined,      title: 'EMERGENCY CORPUS',    tag: 'SAFETY'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          CustomPaint(size: MediaQuery.of(context).size, painter: GridPainter()),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatusBanner(),
                        const SizedBox(height: 28),
                        _buildSectionLabel('MY GOALS'),
                        const SizedBox(height: 12),
                        _buildViewGoalsPlaceholder(),
                        const SizedBox(height: 28),
                        _buildSectionLabel('ADD A GOAL'),
                        const SizedBox(height: 4),
                        Text(
                          'Choose a goal type to get started',
                          style: TextStyle(fontFamily: 'Courier', fontSize: 10, letterSpacing: 2, color: AppColors.textMuted.withOpacity(0.3)),
                        ),
                        const SizedBox(height: 16),
                        _buildGoalGrid(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 20, height: 1, color: AppColors.green),
              const SizedBox(width: 10),
              Text('FINANCIAL GOALS', style: TextStyle(fontFamily: 'Courier', fontSize: 9, letterSpacing: 4, color: AppColors.green.withOpacity(0.6))),
              const Spacer(),
              // API badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.green.withOpacity(0.2)),
                ),
                child: Text('API READY', style: TextStyle(fontFamily: 'Courier', fontSize: 8, letterSpacing: 2, color: AppColors.green.withOpacity(0.4))),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('YOUR\nGOALS.', style: TextStyle(fontFamily: 'Courier', fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 2, height: 1.0, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildStatusBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.green.withOpacity(0.15)),
        color: AppColors.green.withOpacity(0.04),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.green.withOpacity(0.5), size: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Goals API coming soon. Define your targets and we\'ll calculate the path.',
              style: TextStyle(fontFamily: 'Courier', fontSize: 10, height: 1.6, color: AppColors.textMuted.withOpacity(0.45)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewGoalsPlaceholder() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.blackCard,
        border: Border.all(color: AppColors.green.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(Icons.flag_outlined, color: AppColors.green.withOpacity(0.25), size: 40),
          const SizedBox(height: 14),
          const Text(
            'NO GOALS YET',
            style: TextStyle(fontFamily: 'Courier', fontSize: 14, letterSpacing: 4, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Your active goals will appear here\nonce connected to the /goals API.',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Courier', fontSize: 10, height: 1.7, color: AppColors.textMuted.withOpacity(0.35)),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.green.withOpacity(0.3)),
            ),
            child: Text('VIEW GOALS  →', style: TextStyle(fontFamily: 'Courier', fontSize: 10, letterSpacing: 3, color: AppColors.green.withOpacity(0.6))),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _goalTemplates.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.35,
      ),
      itemBuilder: (_, i) => _GoalCard(template: _goalTemplates[i]),
    );
  }

  Widget _buildSectionLabel(String title) {
    return Row(
      children: [
        Container(width: 20, height: 1, color: AppColors.green),
        const SizedBox(width: 10),
        Text(title, style: TextStyle(fontFamily: 'Courier', fontSize: 10, letterSpacing: 4, color: AppColors.green.withOpacity(0.7))),
      ],
    );
  }
}

// ── Goal Template Model ────────────────────────────────────────────────────────
class _GoalTemplate {
  final IconData icon;
  final String title, tag;
  const _GoalTemplate({required this.icon, required this.title, required this.tag});
}

// ── Goal Card ──────────────────────────────────────────────────────────────────
class _GoalCard extends StatelessWidget {
  final _GoalTemplate template;
  const _GoalCard({super.key, required this.template});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.blackCard,
            border: Border.all(color: AppColors.green.withOpacity(0.12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(template.icon, color: AppColors.green, size: 22),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    color: AppColors.green.withOpacity(0.08),
                    child: Text(template.tag, style: TextStyle(fontFamily: 'Courier', fontSize: 7, letterSpacing: 1, color: AppColors.green.withOpacity(0.6))),
                  ),
                ],
              ),
              const Spacer(),
              Text(template.title, style: const TextStyle(fontFamily: 'Courier', fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.bold, color: Colors.white, height: 1.3)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.add, color: AppColors.green.withOpacity(0.6), size: 12),
                  const SizedBox(width: 4),
                  Text('ADD GOAL', style: TextStyle(fontFamily: 'Courier', fontSize: 9, letterSpacing: 2, color: AppColors.green.withOpacity(0.5))),
                ],
              ),
            ],
          ),
        ),
      );
}
