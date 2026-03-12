// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'api_service.dart';
import 'main_nav.dart';
import 'user_onboarding.dart';

// ══════════════════════════════════════════════════════════════════════════════
// ── Auth Gate — Login or Register choice ──────────────────────────────────────
// ══════════════════════════════════════════════════════════════════════════════
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate>
    with SingleTickerProviderStateMixin {
  String _mode = 'choose'; // 'choose' | 'login'

  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _errorMsg;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _switchMode(String mode) {
    _fadeCtrl.reset();
    setState(() {
      _mode = mode;
      _errorMsg = null;
    });
    _fadeCtrl.forward();
  }

  // ── POST /auth/login ──────────────────────────────────────────────────────
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    // FIX 1: mounted guard added before every post-async setState
    if (!mounted) return;
    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    try {
      final email = _emailCtrl.text.trim();

      // Step 1: Login → get JWT token
      final jwt = await ApiService.instance.login(
        email: email,
        password: _passCtrl.text.trim(),
      );

      // Step 2: Decode JWT payload to extract user_id
      String? userId;
      try {
        final parts = jwt.split('.');
        if (parts.length == 3) {
          String payload = parts[1];
          while (payload.length % 4 != 0) {
            payload += '=';
          }
          final decoded = String.fromCharCodes(
            base64Url.decode(payload.replaceAll('-', '+').replaceAll('_', '/')),
          );
          final Map<String, dynamic> claims = jsonDecode(decoded);
          userId = claims['sub']?.toString() ??
              claims['user_id']?.toString() ??
              claims['id']?.toString();
          ApiService.debugLog('JWT claims: $claims');
          ApiService.debugLog('Extracted userId: $userId');
        }
      } catch (e) {
        ApiService.debugLog('JWT decode failed: $e');
      }

      // Step 3: Fetch profile
      if (userId != null && userId.isNotEmpty) {
        await ApiService.instance.fetchProfileById(userId);
      } else {
        await ApiService.instance.fetchProfile();
      }

      final profile = ApiService.instance.buildUserProfile();

      final user = UserProfile(
        name: profile.name,
        maritalStatus: profile.maritalStatus,
        age: profile.age,
        currentIncome: profile.currentIncome,
        incomeRaisePct: profile.incomeRaisePct,
        spouseAge: profile.spouseAge,
        spouseIncome: profile.spouseIncome,
        spouseIncomeRaisePct: profile.spouseIncomeRaisePct,
      );

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => MainNav(user: user)),
          (route) => false,
        );
      }
    } on ApiException catch (e) {
      // FIX 2: was bare setState — now guarded
      if (mounted) setState(() => _errorMsg = e.message);
    } catch (e) {
      // FIX 3: was bare setState — now guarded
      if (mounted) {
        setState(() => _errorMsg = 'Unexpected error: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          CustomPaint(
              size: MediaQuery.of(context).size, painter: GridPainter()),

          // Top-right glow
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.green.withOpacity(0.07),
                  Colors.transparent
                ]),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── Top bar ──────────────────────────────────────────────
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(children: [
                    GestureDetector(
                      onTap: () {
                        if (_mode == 'login') {
                          _switchMode('choose');
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      child: Row(children: [
                        Icon(Icons.arrow_back_ios,
                            color: AppColors.green.withOpacity(0.6), size: 14),
                        const SizedBox(width: 6),
                        Text('BACK',
                            style: TextStyle(
                                fontFamily: 'Courier',
                                fontSize: 10,
                                letterSpacing: 3,
                                color: AppColors.green.withOpacity(0.6))),
                      ]),
                    ),
                    const Spacer(),
                    Row(children: [
                      Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                              shape: BoxShape.circle, color: AppColors.green)),
                      const SizedBox(width: 8),
                      const Text('VERDEX',
                          style: TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 13,
                              letterSpacing: 4,
                              fontWeight: FontWeight.w900,
                              color: Colors.white)),
                    ]),
                  ]),
                ),

                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                      child: _mode == 'choose'
                          ? _buildChooseMode()
                          : _buildLoginMode(),
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

  // ══════════════════════════════════════════════════════════════════════════
  // ── MODE: CHOOSE ──────────────────────────────────────────────────────────
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildChooseMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),

        Row(children: [
          Container(width: 20, height: 1, color: AppColors.green),
          const SizedBox(width: 10),
          Text('WELCOME BACK',
              style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 9,
                  letterSpacing: 4,
                  color: AppColors.green.withOpacity(0.6))),
        ]),
        const SizedBox(height: 16),
        const Text('HOW WOULD\nYOU LIKE TO\nCONTINUE?',
            style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 34,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                height: 1.05,
                color: Colors.white)),
        const SizedBox(height: 10),
        Text('Sign in to your account or create a new one.',
            style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 11,
                height: 1.7,
                color: AppColors.textMuted.withOpacity(0.4))),

        const SizedBox(height: 48),

        // ── New User card ────────────────────────────────────────────────
        GestureDetector(
          onTap: () => Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const UserOnboardingPage())),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.blackCard,
              border: Border.all(color: AppColors.green.withOpacity(0.2)),
            ),
            child: Row(children: [
              Container(
                width: 48,
                height: 48,
                color: AppColors.green,
                child: const Icon(Icons.person_add_outlined,
                    color: AppColors.black, size: 22),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('NEW USER',
                          style: TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 14,
                              letterSpacing: 3,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      const SizedBox(height: 5),
                      Text(
                          'Create your VerdeX profile and start planning your financial future.',
                          style: TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 10,
                              height: 1.6,
                              color: AppColors.textMuted.withOpacity(0.4))),
                    ]),
              ),
              const SizedBox(width: 12),
              Icon(Icons.arrow_forward_ios,
                  size: 14, color: AppColors.green.withOpacity(0.5)),
            ]),
          ),
        ),

        const SizedBox(height: 16),

        // ── OR divider ───────────────────────────────────────────────────
        Row(children: [
          Expanded(
              child: Container(
                  height: 1, color: AppColors.green.withOpacity(0.08))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text('OR',
                style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 9,
                    letterSpacing: 3,
                    color: AppColors.textMuted.withOpacity(0.25))),
          ),
          Expanded(
              child: Container(
                  height: 1, color: AppColors.green.withOpacity(0.08))),
        ]),

        const SizedBox(height: 16),

        // ── Returning User card ──────────────────────────────────────────
        GestureDetector(
          onTap: () => _switchMode('login'),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.blackCard,
              border: Border.all(color: AppColors.green.withOpacity(0.12)),
            ),
            child: Row(children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.green.withOpacity(0.4)),
                  color: AppColors.green.withOpacity(0.07),
                ),
                child: const Icon(Icons.lock_open_outlined,
                    color: AppColors.green, size: 22),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('LOG-IN',
                          style: TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 14,
                              letterSpacing: 3,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      const SizedBox(height: 5),
                      Text(
                          'Sign in with your email and password to access your dashboard.',
                          style: TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 10,
                              height: 1.6,
                              color: AppColors.textMuted.withOpacity(0.4))),
                    ]),
              ),
              const SizedBox(width: 12),
              Icon(Icons.arrow_forward_ios,
                  size: 14, color: AppColors.green.withOpacity(0.4)),
            ]),
          ),
        ),

        const SizedBox(height: 48),

        const Center(
          child: Text('Your data is encrypted and never shared.',
              style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 9,
                  letterSpacing: 2,
                  color: AppColors.hintText)),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── MODE: LOGIN ───────────────────────────────────────────────────────────
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildLoginMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Row(children: [
          Container(width: 20, height: 1, color: AppColors.green),
          const SizedBox(width: 10),
          Text('RETURNING USER',
              style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 9,
                  letterSpacing: 4,
                  color: AppColors.green.withOpacity(0.6))),
        ]),
        const SizedBox(height: 16),
        const Text('SIGN IN\nTO YOUR\nACCOUNT.',
            style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 34,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                height: 1.05,
                color: Colors.white)),
        const SizedBox(height: 40),
        Form(
          key: _formKey,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Email
            _AuthField(
              label: 'EMAIL ADDRESS',
              hint: 'you@email.com',
              ctrl: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Password
            _AuthField(
              label: 'PASSWORD',
              hint: '••••••••',
              ctrl: _passCtrl,
              obscureText: _obscure,
              suffixIcon: GestureDetector(
                onTap: () => setState(() => _obscure = !_obscure),
                child: Icon(
                  _obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.green.withOpacity(0.45),
                  size: 18,
                ),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 32),

            // Error banner
            if (_errorMsg != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.error.withOpacity(0.4)),
                  color: AppColors.error.withOpacity(0.06),
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: AppColors.error, size: 16),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(_errorMsg!,
                              style: TextStyle(
                                  fontFamily: 'Courier',
                                  fontSize: 11,
                                  height: 1.5,
                                  color: AppColors.error.withOpacity(0.85))),
                        ),
                      ]),
                      // Retry button for cold start errors
                      if (_errorMsg!.contains('starting up') ||
                          _errorMsg!.contains('cold start')) ...[
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: _loading ? null : _login,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                                border: Border.all(
                                    color: AppColors.error.withOpacity(0.5))),
                            child:
                                Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.refresh,
                                  color: AppColors.error.withOpacity(0.7),
                                  size: 13),
                              const SizedBox(width: 6),
                              Text('RETRY',
                                  style: TextStyle(
                                      fontFamily: 'Courier',
                                      fontSize: 10,
                                      letterSpacing: 2,
                                      color: AppColors.error.withOpacity(0.7))),
                            ]),
                          ),
                        ),
                      ],
                    ]),
              ),
              const SizedBox(height: 20),
            ],

            // Sign In button
            GestureDetector(
              onTap: _loading ? null : _login,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                color: _loading
                    ? AppColors.green.withOpacity(0.5)
                    : AppColors.green,
                child: Center(
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.black))
                      : const Text('SIGN IN',
                          style: TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 13,
                              letterSpacing: 4,
                              fontWeight: FontWeight.bold,
                              color: AppColors.black)),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Switch to register
            Center(
              child: GestureDetector(
                onTap: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const UserOnboardingPage())),
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 11,
                        color: AppColors.textMuted.withOpacity(0.4)),
                    children: const [
                      TextSpan(text: "Don't have an account?  "),
                      TextSpan(
                        text: 'CREATE ONE',
                        style: TextStyle(
                            color: AppColors.green,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ]),
        ),
      ],
    );
  }
}

// ── Auth Field ────────────────────────────────────────────────────────────────
class _AuthField extends StatelessWidget {
  final String label, hint;
  final TextEditingController ctrl;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const _AuthField({
    required this.label,
    required this.hint,
    required this.ctrl,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 10,
                  letterSpacing: 3,
                  color: AppColors.fieldLabel)),
          const SizedBox(height: 8),
          TextFormField(
            controller: ctrl,
            keyboardType: keyboardType,
            obscureText: obscureText,
            validator: validator,
            style: const TextStyle(
                fontFamily: 'Courier',
                fontSize: 14,
                color: Colors.white,
                letterSpacing: 1),
            cursorColor: AppColors.green,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 13,
                  color: AppColors.hintText),
              suffixIcon: suffixIcon,
              filled: true,
              fillColor: AppColors.inputFill,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide:
                      BorderSide(color: AppColors.green.withOpacity(0.15))),
              focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: AppColors.green, width: 1.5)),
              errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide:
                      BorderSide(color: AppColors.error.withOpacity(0.6))),
              focusedErrorBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: AppColors.error, width: 1.5)),
              errorStyle: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 9,
                  color: AppColors.error.withOpacity(0.8),
                  letterSpacing: 1),
            ),
          ),
        ],
      );
}
