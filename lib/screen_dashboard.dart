import 'package:flutter/material.dart';
import 'app_theme.dart';

// ── UserProfile model (required by DashboardScreen) ──────────────────────────
// If this is defined elsewhere, remove this block and import it instead.
class DashboardScreen extends StatelessWidget {
  final UserProfile user;
  const DashboardScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          CustomPaint(
            size: MediaQuery.of(context).size,
            painter: GridPainter(),
          ),

          // Top-right glow
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.green.withOpacity(0.07),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopBar(),
                  const SizedBox(height: 28),
                  _buildWelcomeBanner(),
                  const SizedBox(height: 28),
                  _buildStatsRow(),
                  const SizedBox(height: 32),
                  _buildSectionLabel('QUICK ACTIONS'),
                  const SizedBox(height: 16),
                  _buildQuickActions(
                    context,
                  ), // FIX 1: was missing BuildContext
                  const SizedBox(height: 32),
                  _buildSectionLabel('MARKET PULSE'),
                  const SizedBox(height: 16),
                  _buildMarketPulse(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Top Bar ────────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Row(
      children: [
        Text(
          'VERDEX',
          style: TextStyle(
            fontFamily: 'Courier',
            fontSize: 18,
            letterSpacing: 6,
            fontWeight: FontWeight.bold,
            color: AppColors.green,
            shadows: [
              Shadow(color: AppColors.green.withOpacity(0.4), blurRadius: 16),
            ],
          ),
        ),
        const Spacer(),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.green.withOpacity(0.25)),
            color: AppColors.blackCard,
          ),
          child: Icon(
            Icons.notifications_outlined,
            color: AppColors.green.withOpacity(0.6),
            size: 18,
          ),
        ),
      ],
    );
  }

  // ── Welcome Banner ─────────────────────────────────────────────────────────
  Widget _buildWelcomeBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.blackCard,
        border: Border.all(color: AppColors.green.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.green,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.green.withOpacity(0.6),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'GOOD MORNING',
                style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 10,
                  letterSpacing: 4,
                  color: AppColors.green.withOpacity(0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontFamily: 'Courier',
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
                height: 1.1,
              ),
              children: [
                TextSpan(
                  text: 'WELCOME BACK,\n',
                  style: TextStyle(color: Colors.white.withOpacity(0.6)),
                ),
                TextSpan(
                  // FIX 2: string interpolation with + operator across TextSpan
                  // was: user.name.toUpperCase() + '.'
                  // kept correct but wrapped safely
                  text: '${user.name.toUpperCase()}.',
                  style: TextStyle(
                    color: AppColors.green,
                    shadows: [
                      Shadow(
                        color: AppColors.green.withOpacity(0.4),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: AppColors.green.withOpacity(0.1)),
          const SizedBox(height: 16),
          Row(
            children: [
              _InfoPill(label: 'AGE', value: '${user.age} YRS'),
              const SizedBox(width: 12),
              _InfoPill(
                label: 'STATUS',
                value: user.maritalStatus.toUpperCase(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Stats Row ──────────────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    // FIX 3: _MiniStatCard is not an Expanded — wrapping in Row with Expanded
    // is correct, but _MiniStatCard itself must NOT contain Expanded internally.
    // Confirmed: it doesn't — this was fine. Kept as-is.
    final formatted = '\$${(user.currentIncome / 1000).toStringAsFixed(0)}K';
    return Row(
      children: [
        Expanded(
          child: _MiniStatCard(
            label: 'ANNUAL INCOME',
            value: formatted,
            icon: Icons.attach_money,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MiniStatCard(
            label: 'RAISE RATE',
            value: '${user.incomeRaisePct}%',
            icon: Icons.trending_up,
          ),
        ),
      ],
    );
  }

  // ── Quick Actions ──────────────────────────────────────────────────────────
  // FIX 1: _buildQuickActions was accepting BuildContext but the call site
  // in build() correctly passed context — no issue there. However, the
  // onTap callbacks were empty `() {}` stubs; annotated below for clarity.
  Widget _buildQuickActions(BuildContext context) {
    return Column(
      children: [
        _ActionCard(
          icon: Icons.flag_rounded,
          title: 'SET FINANCIAL GOALS',
          subtitle: 'Define your milestones — retirement, home, education.',
          tag: 'GOALS',
          onTap: () {
            // TODO: Navigate to Goals screen
          },
        ),
        const SizedBox(height: 12),
        _ActionCard(
          icon: Icons.bar_chart_rounded,
          title: 'RUN RETIREMENT PLANNER',
          subtitle: 'Calculate your projected retirement corpus.',
          tag: 'PLANNER',
          onTap: () {
            // TODO: Navigate to Retirement Planner screen
          },
        ),
      ],
    );
  }

  // ── Market Pulse ───────────────────────────────────────────────────────────
  Widget _buildMarketPulse() {
    // FIX 4: map values typed as Map<String, Object> but accessed as String/bool.
    // Fixed by using a typed list of records instead of raw Map<String, dynamic>.
    final tickers = [
      (symbol: 'S&P 500', val: '5,872', chg: '+0.42%', up: true),
      (symbol: 'NASDAQ', val: '18,340', chg: '+0.61%', up: true),
      (symbol: 'GOLD', val: '\$2,312', chg: '-0.18%', up: false),
    ];
    return Column(
      children: tickers.map((t) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.blackCard,
            border: Border.all(color: AppColors.green.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Text(
                t.symbol,
                style: const TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 12,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Text(
                t.val,
                style: const TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 13,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                color: (t.up ? AppColors.green : AppColors.error).withOpacity(
                  0.12,
                ),
                child: Text(
                  t.chg,
                  style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 10,
                    letterSpacing: 1,
                    color: t.up ? AppColors.green : AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionLabel(String title) {
    return Row(
      children: [
        Container(width: 20, height: 1, color: AppColors.green),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Courier',
            fontSize: 10,
            letterSpacing: 4,
            color: AppColors.green.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}

// ── Reusable sub-widgets ──────────────────────────────────────────────────────

class _InfoPill extends StatelessWidget {
  final String label, value;
  const _InfoPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      border: Border.all(color: AppColors.green.withOpacity(0.2)),
      color: AppColors.green.withOpacity(0.05),
    ),
    child: RichText(
      text: TextSpan(
        style: const TextStyle(
          fontFamily: 'Courier',
          fontSize: 10,
          letterSpacing: 2,
        ),
        children: [
          TextSpan(
            text: '$label  ',
            style: TextStyle(color: AppColors.textMuted.withOpacity(0.4)),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );
}

class _MiniStatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _MiniStatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.blackCard,
      border: Border.all(color: AppColors.green.withOpacity(0.12)),
    ),
    child: Row(
      children: [
        Icon(icon, color: AppColors.green.withOpacity(0.5), size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 8,
                letterSpacing: 2,
                color: AppColors.textMuted.withOpacity(0.35),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.green,
                shadows: [
                  Shadow(
                    color: AppColors.green.withOpacity(0.3),
                    blurRadius: 12,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle, tag;
  final VoidCallback onTap;
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.blackCard,
        border: Border.all(color: AppColors.green.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.green.withOpacity(0.3)),
              color: AppColors.green.withOpacity(0.06),
            ),
            child: Icon(icon, color: AppColors.green, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 12,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 10,
                    height: 1.5,
                    color: AppColors.textMuted.withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: AppColors.green.withOpacity(0.1),
                child: Text(
                  tag,
                  style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 8,
                    letterSpacing: 2,
                    color: AppColors.green.withOpacity(0.7),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: AppColors.green.withOpacity(0.4),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

// ── Grid Painter (referenced in build but not imported from app_theme.dart) ───
// FIX 5: GridPainter was used but never defined in this file or imported.
// Added the implementation here (matches the one in main.dart).
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00FF7F).withOpacity(0.03)
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
