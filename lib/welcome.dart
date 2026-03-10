import 'package:flutter/material.dart';
import 'main_nav.dart';
import 'user_onboarding.dart';
import 'app_theme.dart'; // AppColors, AppText, UserProfile, GridPainter all live here

// ── App Root ──────────────────────────────────────────────────────────────────
class FinanceApp extends StatelessWidget {
  const FinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VerdeX Finance',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.black,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.green,
          surface: AppColors.blackMid,
        ),
        fontFamily: AppText.mono,
      ),
      home: const SplashScreen(),
    );
  }
}

// ── Splash Screen ─────────────────────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final Animation<double> _logoOpacity;
  late final Animation<Offset> _logoSlide;

  late final AnimationController _barController;
  late final Animation<double> _barProgress;

  late final AnimationController _wipeInController;
  late final Animation<double> _wipeIn;

  late final AnimationController _wipeOutController;
  late final Animation<double> _wipeOut;

  bool _showHome = false;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _logoOpacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeOut));
    _logoSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeOut));

    _barController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _barProgress = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _barController, curve: Curves.easeInOut));

    _wipeInController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _wipeIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _wipeInController, curve: Curves.easeInOut),
    );

    _wipeOutController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _wipeOut = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _wipeOutController, curve: Curves.easeInOut),
    );

    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _logoController.forward();

    await Future.delayed(const Duration(milliseconds: 500));
    await _barController.forward();
    await Future.delayed(const Duration(milliseconds: 200));

    await _wipeInController.forward();
    setState(() => _showHome = true);
    await _wipeOutController.forward();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _barController.dispose();
    _wipeInController.dispose();
    _wipeOutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          // Layer 1: Splash or Welcome page
          _showHome ? const WelcomePage() : _buildSplash(),

          // Layer 2: Green wipe overlay
          AnimatedBuilder(
            animation: Listenable.merge([
              _wipeInController,
              _wipeOutController,
            ]),
            builder: (context, _) {
              double left = 0;
              double right = 0;

              if (_wipeInController.isAnimating ||
                  (!_wipeInController.isDismissed &&
                      _wipeOutController.isDismissed)) {
                right = size.width * (1 - _wipeIn.value);
              }

              if (_wipeOutController.isAnimating ||
                  _wipeOutController.isCompleted) {
                left = size.width * _wipeOut.value;
                right = 0;
              }

              if (_wipeInController.isDismissed) return const SizedBox.shrink();
              if (_wipeOutController.isCompleted) {
                return const SizedBox.shrink();
              }

              return Positioned(
                top: 0,
                bottom: 0,
                left: left,
                right: right,
                child: Container(
                  color: AppColors.green,
                  child:
                      _wipeInController.isCompleted &&
                          _wipeOutController.isDismissed
                      ? Center(
                          child: Text(
                            'VERDEX',
                            style:
                                AppText.heading(
                                  size: 36,
                                  color: AppColors.black,
                                ).copyWith(
                                  letterSpacing: 14,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        )
                      : null,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSplash() {
    return Container(
      color: AppColors.black,
      child: Stack(
        children: [
          // Radial glow
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.green.withOpacity(0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Logo + tagline
          Center(
            child: SlideTransition(
              position: _logoSlide,
              child: FadeTransition(
                opacity: _logoOpacity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.green.withOpacity(0.4),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.trending_up,
                        color: AppColors.green,
                        size: 32,
                      ),
                    ),
                    Text(
                      'VERDEX',
                      style: TextStyle(
                        fontFamily: AppText.mono,
                        fontSize: 52,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 16,
                        color: AppColors.green,
                        shadows: [
                          Shadow(
                            color: AppColors.green.withOpacity(0.5),
                            blurRadius: 40,
                          ),
                          Shadow(
                            color: AppColors.green.withOpacity(0.2),
                            blurRadius: 80,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'SMART FINANCE • DARK EDGE',
                      style: AppText.label(
                        size: 10,
                        spacing: 6,
                      ).copyWith(color: AppColors.green.withOpacity(0.45)),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Loading bar
          Positioned(
            bottom: 64,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _logoOpacity,
              child: Column(
                children: [
                  Text(
                    'INITIALIZING',
                    style: AppText.label(
                      size: 10,
                      spacing: 5,
                    ).copyWith(color: AppColors.green.withOpacity(0.3)),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: SizedBox(
                      width: 180,
                      child: AnimatedBuilder(
                        animation: _barProgress,
                        builder: (context, _) => Stack(
                          children: [
                            Container(
                              height: 2,
                              decoration: BoxDecoration(
                                color: AppColors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: _barProgress.value,
                              child: Container(
                                height: 2,
                                decoration: BoxDecoration(
                                  color: AppColors.green,
                                  borderRadius: BorderRadius.circular(2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.green.withOpacity(0.8),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Welcome / Marketing Page ──────────────────────────────────────────────────
// "GET STARTED" → UserOnboardingPage (new users)
// "SIGN IN"     → MainNav with mock/stored profile (returning users)
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

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
          SafeArea(
            child: Column(
              children: [
                _buildNavBar(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHero(context),
                        const SizedBox(height: 48),
                        _buildStatsRow(),
                        const SizedBox(height: 48),
                        _buildCardRow(),
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

  Widget _buildNavBar(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final isNarrow = constraints.maxWidth < 420;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.black.withOpacity(0.85),
            border: Border(
              bottom: BorderSide(color: AppColors.green.withOpacity(0.08)),
            ),
          ),
          child: Row(
            children: [
              // Brand
              Text(
                'VERDEX',
                style: TextStyle(
                  fontFamily: AppText.mono,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 6,
                  color: AppColors.green,
                  shadows: [
                    Shadow(
                      color: AppColors.green.withOpacity(0.4),
                      blurRadius: 20,
                    ),
                  ],
                ),
              ),

              // Nav links hidden on narrow screens to prevent overflow
              if (!isNarrow) ...[
                const SizedBox(width: 24),
                const _NavChip('PORTFOLIO'),
                const SizedBox(width: 20),
                const _NavChip('MARKETS'),
                const SizedBox(width: 20),
                const _NavChip('TRADE'),
              ],

              const Spacer(),

              // SIGN IN → returning users skip onboarding
              GestureDetector(
                onTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MainNav(user: UserProfile.mock),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.green.withOpacity(0.5)),
                  ),
                  child: Text(
                    'SIGN IN',
                    style: AppText.label(size: 10, spacing: 2).copyWith(
                      color: AppColors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHero(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 400;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'GROW YOUR\nWEALTH\nSMARTER.',
              style: AppText.heading(size: narrow ? 36 : 56),
            ),
            const SizedBox(height: 20),
            Text(
              'Real-time analytics, intelligent portfolio\nmanagement, and zero-fee trading.',
              style: AppText.body(size: narrow ? 12 : 14),
            ),
            const SizedBox(height: 30),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                // GET STARTED → new users go to onboarding
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const UserOnboardingPage(),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    color: AppColors.green,
                    child: Text(
                      'GET STARTED',
                      style: AppText.label(size: 12, spacing: 3).copyWith(
                        color: AppColors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.green.withOpacity(0.4)),
                  ),
                  child: Text(
                    'LEARN MORE',
                    style: AppText.label(
                      size: 12,
                      spacing: 3,
                    ).copyWith(color: AppColors.textMuted.withOpacity(0.6)),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatsRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 420) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: const Row(
              children: [
                _StatCard(value: '\$2.4T', label: 'ASSETS MANAGED', width: 120),
                SizedBox(width: 10),
                _StatCard(value: '1.2M+', label: 'ACTIVE USERS', width: 120),
                SizedBox(width: 10),
                _StatCard(value: '0.0%', label: 'TRADING FEES', width: 120),
                SizedBox(width: 10),
                _StatCard(value: '99.9%', label: 'UPTIME SLA', width: 120),
              ],
            ),
          );
        }
        return const Row(
          children: [
            Expanded(
              child: _StatCard(value: '\$2.4T', label: 'ASSETS MANAGED'),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _StatCard(value: '1.2M+', label: 'ACTIVE USERS'),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _StatCard(value: '0.0%', label: 'TRADING FEES'),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _StatCard(value: '99.9%', label: 'UPTIME SLA'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCardRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 500) {
          return const Column(
            children: [
              _FeatureCard(
                icon: Icons.show_chart,
                title: 'LIVE MARKETS',
                body: 'Real-time quotes and depth charts across 5000+ assets.',
              ),
              SizedBox(height: 12),
              _FeatureCard(
                icon: Icons.account_balance_wallet_outlined,
                title: 'SMART WALLET',
                body: 'AI-optimized allocation tailored to your risk profile.',
              ),
              SizedBox(height: 12),
              _FeatureCard(
                icon: Icons.shield_outlined,
                title: 'BANK-GRADE SECURITY',
                body: '256-bit encryption and biometric authentication.',
              ),
            ],
          );
        }
        return const Row(
          children: [
            Expanded(
              child: _FeatureCard(
                icon: Icons.show_chart,
                title: 'LIVE MARKETS',
                body: 'Real-time quotes and depth charts across 5000+ assets.',
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _FeatureCard(
                icon: Icons.account_balance_wallet_outlined,
                title: 'SMART WALLET',
                body: 'AI-optimized allocation tailored to your risk profile.',
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _FeatureCard(
                icon: Icons.shield_outlined,
                title: 'BANK-GRADE SECURITY',
                body: '256-bit encryption and biometric authentication.',
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Shared Widgets ────────────────────────────────────────────────────────────

class _NavChip extends StatelessWidget {
  final String label;
  const _NavChip(this.label);

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: AppText.label(
      size: 10,
      spacing: 3,
    ).copyWith(color: AppColors.textMuted.withOpacity(0.4)),
  );
}

// No internal Expanded — caller decides sizing via Expanded (wide) or width (narrow scroll)
class _StatCard extends StatelessWidget {
  final String value, label;
  final double? width;
  const _StatCard({required this.value, required this.label, this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.green.withOpacity(0.1)),
          color: AppColors.blackMid,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: AppText.mono,
                // Smaller font when card has a fixed narrow width
                fontSize: width != null ? 22 : 30,
                fontWeight: FontWeight.bold,
                color: AppColors.green,
                shadows: [
                  Shadow(
                    color: AppColors.green.withOpacity(0.4),
                    blurRadius: 20,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppText.label(
                size: 8,
                spacing: 2,
              ).copyWith(color: AppColors.textMuted.withOpacity(0.35)),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title, body;
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      border: Border.all(color: AppColors.green.withOpacity(0.1)),
      color: AppColors.blackMid,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.green, size: 28),
        const SizedBox(height: 16),
        Text(
          title,
          style: AppText.label(
            size: 12,
            spacing: 4,
          ).copyWith(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text(body, style: AppText.body(size: 11)),
      ],
    ),
  );
}
