import 'package:flutter/material.dart';
import 'user_onboarding.dart';

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
        fontFamily: 'Courier', // Monospace feel; swap for your preferred font
      ),
      home: const SplashScreen(),
    );
  }
}

// ── Color Palette ─────────────────────────────────────────────────────────────
class AppColors {
  static const Color green = Color(0xFF00FF7F);
  static const Color greenDim = Color(0xFF00C45F);
  static const Color greenDark = Color(0xFF003D20);
  static const Color black = Color(0xFF020805);
  static const Color blackMid = Color(0xFF0A120D);
  static const Color textMuted = Color(0xFFC8F0D5);
}

// ── Splash Screen ─────────────────────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Logo fade + rise
  late final AnimationController _logoController;
  late final Animation<double> _logoOpacity;
  late final Animation<Offset> _logoSlide;

  // Loading bar
  late final AnimationController _barController;
  late final Animation<double> _barProgress;

  // Green wipe — covers screen
  late final AnimationController _wipeInController;
  late final Animation<double> _wipeIn;

  // Green wipe — reveals home
  late final AnimationController _wipeOutController;
  late final Animation<double> _wipeOut;

  bool _showHome = false;

  @override
  void initState() {
    super.initState();

    // 1. Logo animation
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

    // 2. Loading bar
    _barController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _barProgress = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _barController, curve: Curves.easeInOut));

    // 3. Wipe IN (green covers screen)
    _wipeInController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _wipeIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _wipeInController, curve: Curves.easeInOut),
    );

    // 4. Wipe OUT (green retreats, revealing home)
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
    // Step 1: Animate logo in
    await Future.delayed(const Duration(milliseconds: 300));
    _logoController.forward();

    // Step 2: Start loading bar shortly after
    await Future.delayed(const Duration(milliseconds: 500));
    _barController.forward();

    // Step 3: Wait for bar to finish, then trigger wipe
    await _barController.forward();
    await Future.delayed(const Duration(milliseconds: 200));

    // Step 4: Green wipes IN (covers splash)
    await _wipeInController.forward();

    // Step 5: Swap to home underneath
    setState(() => _showHome = true);

    // Step 6: Green wipes OUT (reveals home)
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
          // ── Layer 1: Splash or Home ───────────────────────────────────────
          _showHome ? const HomePage() : _buildSplash(),

          // ── Layer 2: Green Wipe Overlay ───────────────────────────────────
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
                // Wipe IN: green slides in from left
                right = size.width * (1 - _wipeIn.value);
              }

              if (_wipeOutController.isAnimating ||
                  _wipeOutController.isCompleted) {
                // Wipe OUT: green slides out to right
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
                            style: TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 14,
                              color: AppColors.black,
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

          // Center logo
          Center(
            child: SlideTransition(
              position: _logoSlide,
              child: FadeTransition(
                opacity: _logoOpacity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon mark
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

                    // Brand name
                    Text(
                      'VERDEX',
                      style: TextStyle(
                        fontFamily: 'Courier',
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

                    // Tagline
                    Text(
                      'SMART FINANCE • DARK EDGE',
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 10,
                        letterSpacing: 6,
                        color: AppColors.green.withOpacity(0.45),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Loading bar (bottom)
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
                    style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 10,
                      letterSpacing: 5,
                      color: AppColors.green.withOpacity(0.3),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: SizedBox(
                      width: 180,
                      child: AnimatedBuilder(
                        animation: _barProgress,
                        builder: (context, _) {
                          return Stack(
                            children: [
                              // Track
                              Container(
                                height: 2,
                                decoration: BoxDecoration(
                                  color: AppColors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              // Fill
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
                          );
                        },
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

// ── Home Page ─────────────────────────────────────────────────────────────────
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          // Grid overlay
          CustomPaint(
            size: MediaQuery.of(context).size,
            painter: GridPainter(),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                _buildNavBar(),
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

  Widget _buildNavBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.black.withOpacity(0.85),
        border: Border(
          bottom: BorderSide(
            color: AppColors.green.withOpacity(0.08),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Brand — fixed width, won't grow
          Text(
            'VERDEX',
            style: TextStyle(
              fontFamily: 'Courier',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 6,
              color: AppColors.green,
              shadows: [
                Shadow(color: AppColors.green.withOpacity(0.4), blurRadius: 20),
              ],
            ),
          ),

          // Nav links take remaining space, centered
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  _NavChip('PORTFOLIO'),
                  SizedBox(width: 20),
                  _NavChip('MARKETS'),
                  SizedBox(width: 20),
                  _NavChip('TRADE'),
                ],
              ),
            ),
          ),

          // SIGN IN button — fixed, right-aligned
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.green.withOpacity(0.5)),
            ),
            child: const Text(
              'SIGN IN',
              style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 10,
                letterSpacing: 2,
                color: AppColors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── context is now passed in so GestureDetector can navigate ──
  Widget _buildHero(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double maxWidth = constraints.maxWidth;

        double headingSize = maxWidth < 400 ? 28 : 48;
        double subSize = maxWidth < 400 ? 12 : 14;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "GROW YOUR WEALTH SMARTER.",
              style: TextStyle(
                fontSize: headingSize,
                fontWeight: FontWeight.bold,
                color: AppColors.green,
              ),
              softWrap: true,
            ),
            const SizedBox(height: 20),
            Text(
              "Real-time analytics, intelligent portfolio management, and zero-fee trading in one powerful platform.",
              style: TextStyle(
                fontSize: subSize,
                color: AppColors.textMuted.withOpacity(0.7),
              ),
              softWrap: true,
            ),
            const SizedBox(height: 30),

            /// Use Wrap instead of Row (THIS prevents overflow)
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                // ── GET STARTED button ────────────────────────────────────
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const UserOnboardingPage(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    color: AppColors.green,
                    child: const Text(
                      "GET STARTED",
                      style: TextStyle(
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
                    border: Border.all(color: AppColors.green),
                  ),
                  child: const Text("LEARN MORE"),
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
        // On narrow screens, scroll horizontally; on wide screens, use full row
        if (constraints.maxWidth < 400) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                SizedBox(
                  width: 140,
                  child: _StatCard(value: '\$2.4T', label: 'ASSETS MANAGED'),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 140,
                  child: _StatCard(value: '1.2M+', label: 'ACTIVE USERS'),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 140,
                  child: _StatCard(value: '0.0%', label: 'TRADING FEES'),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 140,
                  child: _StatCard(value: '99.9%', label: 'UPTIME SLA'),
                ),
              ],
            ),
          );
        }
        return Row(
          children: [
            Expanded(
              child: _StatCard(value: '\$2.4T', label: 'ASSETS MANAGED'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(value: '1.2M+', label: 'ACTIVE USERS'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(value: '0.0%', label: 'TRADING FEES'),
            ),
            const SizedBox(width: 12),
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
          // Stack vertically on small screens
          return Column(
            children: [
              _FeatureCard(
                icon: Icons.show_chart,
                title: 'LIVE MARKETS',
                body: 'Real-time quotes and depth charts across 5000+ assets.',
              ),
              const SizedBox(height: 12),
              _FeatureCard(
                icon: Icons.account_balance_wallet_outlined,
                title: 'SMART WALLET',
                body: 'AI-optimized allocation tailored to your risk profile.',
              ),
              const SizedBox(height: 12),
              _FeatureCard(
                icon: Icons.shield_outlined,
                title: 'BANK-GRADE SECURITY',
                body: '256-bit encryption and biometric authentication.',
              ),
            ],
          );
        }
        return Row(
          children: [
            Expanded(
              child: _FeatureCard(
                icon: Icons.show_chart,
                title: 'LIVE MARKETS',
                body: 'Real-time quotes and depth charts across 5000+ assets.',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _FeatureCard(
                icon: Icons.account_balance_wallet_outlined,
                title: 'SMART WALLET',
                body: 'AI-optimized allocation tailored to your risk profile.',
              ),
            ),
            const SizedBox(width: 16),
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

// ── Reusable Widgets ──────────────────────────────────────────────────────────

class _NavChip extends StatelessWidget {
  final String label;
  const _NavChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontFamily: 'Courier',
        fontSize: 10,
        letterSpacing: 3,
        color: AppColors.textMuted.withOpacity(0.4),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
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
                fontFamily: 'Courier',
                fontSize: 36,
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
              style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 9,
                letterSpacing: 3,
                color: AppColors.textMuted.withOpacity(0.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            style: const TextStyle(
              fontFamily: 'Courier',
              fontSize: 12,
              letterSpacing: 4,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: TextStyle(
              fontFamily: 'Courier',
              fontSize: 11,
              height: 1.7,
              color: AppColors.textMuted.withOpacity(0.45),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Grid Background Painter ───────────────────────────────────────────────────
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
