// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'auth_gate.dart';

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
            primary: AppColors.green, surface: AppColors.blackMid),
        fontFamily: 'Courier',
      ),
      home: const SplashScreen(),
    );
  }
}

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
        vsync: this, duration: const Duration(milliseconds: 800));
    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _logoController, curve: Curves.easeOut));
    _logoSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _logoController, curve: Curves.easeOut));
    _barController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800));
    _barProgress = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _barController, curve: Curves.easeInOut));
    _wipeInController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 550));
    _wipeIn = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _wipeInController, curve: Curves.easeInOut));
    _wipeOutController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 550));
    _wipeOut = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _wipeOutController, curve: Curves.easeInOut));
    _runSequence();
  }

  // FIX: All post-await code is now guarded with `if (!mounted) return`.
  // Without this, if the user navigates away mid-animation the orphaned
  // setState() throws: "setState() called after dispose()".
  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _logoController.forward();

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    await _barController.forward();

    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    await _wipeInController.forward();

    if (!mounted) return;
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
          _showHome ? const WelcomePage() : _buildSplash(),
          AnimatedBuilder(
            animation:
                Listenable.merge([_wipeInController, _wipeOutController]),
            builder: (context, _) {
              double left = 0, right = 0;
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
                  child: _wipeInController.isCompleted &&
                          _wipeOutController.isDismissed
                      ? const Center(
                          child: Text('VERDEX',
                              style: TextStyle(
                                  fontFamily: 'Courier',
                                  fontSize: 36,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 14,
                                  color: AppColors.black)))
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
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.green.withOpacity(0.08),
                  Colors.transparent
                ]),
              ),
            ),
          ),
          Center(
            child: SlideTransition(
              position: _logoSlide,
              child: FadeTransition(
                opacity: _logoOpacity,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 64,
                    height: 64,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                        border: Border.all(
                            color: AppColors.green.withOpacity(0.4), width: 1)),
                    child: const Icon(Icons.trending_up,
                        color: AppColors.green, size: 32),
                  ),
                  Text('VERDEX',
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 52,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 16,
                        color: AppColors.green,
                        shadows: [
                          Shadow(
                              color: AppColors.green.withOpacity(0.5),
                              blurRadius: 40),
                          Shadow(
                              color: AppColors.green.withOpacity(0.2),
                              blurRadius: 80)
                        ],
                      )),
                  const SizedBox(height: 10),
                  Text('SMART FINANCE • DARK EDGE',
                      style: TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 10,
                          letterSpacing: 6,
                          color: AppColors.green.withOpacity(0.45))),
                ]),
              ),
            ),
          ),
          Positioned(
            bottom: 64,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _logoOpacity,
              child: Column(children: [
                Text('INITIALIZING',
                    style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 10,
                        letterSpacing: 5,
                        color: AppColors.green.withOpacity(0.3))),
                const SizedBox(height: 12),
                Center(
                  child: SizedBox(
                    width: 180,
                    child: AnimatedBuilder(
                      animation: _barProgress,
                      builder: (context, _) => Stack(children: [
                        Container(
                            height: 2,
                            decoration: BoxDecoration(
                                color: AppColors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(2))),
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
                                      blurRadius: 8)
                                ],
                              )),
                        ),
                      ]),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          CustomPaint(
              size: MediaQuery.of(context).size, painter: GridPainter()),
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
    // LayoutBuilder lets us measure available width and conditionally show
    // the nav links. On narrow screens (< 420 px) they are hidden so the
    // VERDEX logo and SIGN IN button always fit without overflowing.
    return LayoutBuilder(builder: (context, constraints) {
      final showLinks = constraints.maxWidth >= 420;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.black.withOpacity(0.85),
          border: Border(
              bottom: BorderSide(color: AppColors.green.withOpacity(0.08))),
        ),
        child: Row(
          children: [
            Text('VERDEX',
                style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 6,
                  color: AppColors.green,
                  shadows: [
                    Shadow(
                        color: AppColors.green.withOpacity(0.4), blurRadius: 20)
                  ],
                )),
            if (showLinks)
              const Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _NavChip('PORTFOLIO'),
                    SizedBox(width: 20),
                    _NavChip('MARKETS'),
                    SizedBox(width: 20),
                    _NavChip('TRADE'),
                  ],
                ),
              )
            else
              const Spacer(),
            GestureDetector(
              onTap: () => Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (_) => const AuthGate())),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                    border:
                        Border.all(color: AppColors.green.withOpacity(0.5))),
                child: const Text('SIGN IN',
                    style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 10,
                        letterSpacing: 2,
                        color: AppColors.green,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildHero(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final narrow = constraints.maxWidth < 400;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('GROW YOUR\nWEALTH\nSMARTER.',
              style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: narrow ? 36 : 56,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                  letterSpacing: 2,
                  color: Colors.white)),
          const SizedBox(height: 20),
          Text(
              'Real-time analytics, intelligent portfolio\nmanagement, and zero-fee trading.',
              style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: narrow ? 12 : 14,
                  height: 1.7,
                  color: AppColors.textMuted.withOpacity(0.5))),
          const SizedBox(height: 30),
          Wrap(spacing: 16, runSpacing: 12, children: [
            GestureDetector(
              onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const AuthGate())),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                color: AppColors.green,
                child: const Text('GET STARTED',
                    style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 12,
                        letterSpacing: 3,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black)),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                  border: Border.all(color: AppColors.green.withOpacity(0.4))),
              child: Text('LEARN MORE',
                  style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 12,
                      letterSpacing: 3,
                      color: AppColors.textMuted.withOpacity(0.6))),
            ),
          ]),
        ],
      );
    });
  }

  Widget _buildStatsRow() {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < 400) {
        return const SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            _StatCard(value: '\$2.4T', label: 'ASSETS MANAGED', width: 140),
            SizedBox(width: 12),
            _StatCard(value: '1.2M+', label: 'ACTIVE USERS', width: 140),
            SizedBox(width: 12),
            _StatCard(value: '0.0%', label: 'TRADING FEES', width: 140),
            SizedBox(width: 12),
            _StatCard(value: '99.9%', label: 'UPTIME SLA', width: 140),
          ]),
        );
      }
      return const Row(children: [
        Expanded(child: _StatCard(value: '\$2.4T', label: 'ASSETS MANAGED')),
        SizedBox(width: 12),
        Expanded(child: _StatCard(value: '1.2M+', label: 'ACTIVE USERS')),
        SizedBox(width: 12),
        Expanded(child: _StatCard(value: '0.0%', label: 'TRADING FEES')),
        SizedBox(width: 12),
        Expanded(child: _StatCard(value: '99.9%', label: 'UPTIME SLA')),
      ]);
    });
  }

  Widget _buildCardRow() {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < 500) {
        return const Column(children: [
          _FeatureCard(
              icon: Icons.show_chart,
              title: 'LIVE MARKETS',
              body: 'Real-time quotes and depth charts across 5000+ assets.'),
          SizedBox(height: 12),
          _FeatureCard(
              icon: Icons.account_balance_wallet_outlined,
              title: 'SMART WALLET',
              body: 'AI-optimized allocation tailored to your risk profile.'),
          SizedBox(height: 12),
          _FeatureCard(
              icon: Icons.shield_outlined,
              title: 'BANK-GRADE SECURITY',
              body: '256-bit encryption and biometric authentication.'),
        ]);
      }
      return const Row(children: [
        Expanded(
            child: _FeatureCard(
                icon: Icons.show_chart,
                title: 'LIVE MARKETS',
                body:
                    'Real-time quotes and depth charts across 5000+ assets.')),
        SizedBox(width: 16),
        Expanded(
            child: _FeatureCard(
                icon: Icons.account_balance_wallet_outlined,
                title: 'SMART WALLET',
                body:
                    'AI-optimized allocation tailored to your risk profile.')),
        SizedBox(width: 16),
        Expanded(
            child: _FeatureCard(
                icon: Icons.shield_outlined,
                title: 'BANK-GRADE SECURITY',
                body: '256-bit encryption and biometric authentication.')),
      ]);
    });
  }
}

class _NavChip extends StatelessWidget {
  final String label;
  const _NavChip(this.label);
  @override
  Widget build(BuildContext context) => Text(label,
      style: TextStyle(
          fontFamily: 'Courier',
          fontSize: 10,
          letterSpacing: 3,
          color: AppColors.textMuted.withOpacity(0.4)));
}

class _StatCard extends StatelessWidget {
  final String value, label;
  final double? width;
  const _StatCard({required this.value, required this.label, this.width});
  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              border: Border.all(color: AppColors.green.withOpacity(0.1)),
              color: AppColors.blackMid),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value,
                style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: AppColors.green,
                    shadows: [
                      Shadow(
                          color: AppColors.green.withOpacity(0.4),
                          blurRadius: 20)
                    ])),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 9,
                    letterSpacing: 3,
                    color: AppColors.textMuted.withOpacity(0.35))),
          ]),
        ),
      );
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title, body;
  const _FeatureCard(
      {required this.icon, required this.title, required this.body});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            border: Border.all(color: AppColors.green.withOpacity(0.1)),
            color: AppColors.blackMid),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: AppColors.green, size: 28),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 12,
                  letterSpacing: 4,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 10),
          Text(body,
              style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 11,
                  height: 1.7,
                  color: AppColors.textMuted.withOpacity(0.45))),
        ]),
      );
}
