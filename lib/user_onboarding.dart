import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'app_theme.dart';

class UserOnboardingPage extends StatefulWidget {
  const UserOnboardingPage({super.key});

  @override
  State<UserOnboardingPage> createState() => _UserOnboardingPageState();
}

class _UserOnboardingPageState extends State<UserOnboardingPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  // ── Form state ──────────────────────────────────────────────────────────────
  String _maritalStatus = 'single';
  final _ageCtrl = TextEditingController();
  final _incomeCtrl = TextEditingController();
  final _incomeRaiseCtrl = TextEditingController();
  final _spouseAgeCtrl = TextEditingController();
  final _spouseIncomeCtrl = TextEditingController();
  final _spouseIncomeRaiseCtrl = TextEditingController();

  bool _isLoading = false;
  String? _errorMsg;

  bool get _isMarried => _maritalStatus == 'married';

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _ageCtrl.dispose();
    _incomeCtrl.dispose();
    _incomeRaiseCtrl.dispose();
    _spouseAgeCtrl.dispose();
    _spouseIncomeCtrl.dispose();
    _spouseIncomeRaiseCtrl.dispose();
    super.dispose();
  }

  // ── API call ────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      final uri = Uri.parse('https://your-api-domain.com/users/');

      final body = {
        'marital_status': _maritalStatus,
        'age': _ageCtrl.text.trim(),
        'current_income': _incomeCtrl.text.trim(),
        'income_raise_pct': _incomeRaiseCtrl.text.trim(),
        if (_isMarried && _spouseAgeCtrl.text.isNotEmpty)
          'spouse_age': _spouseAgeCtrl.text.trim(),
        if (_isMarried && _spouseIncomeCtrl.text.isNotEmpty)
          'spouse_income': _spouseIncomeCtrl.text.trim(),
        if (_isMarried && _spouseIncomeRaiseCtrl.text.isNotEmpty)
          'spouse_income_raise_pct': _spouseIncomeRaiseCtrl.text.trim(),
      };

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) _showSuccessDialog();
      } else {
        setState(
          () => _errorMsg =
              'Server error ${response.statusCode}. Please try again.',
        );
      }
    } catch (e) {
      setState(() => _errorMsg = 'Connection failed. Check your network.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppColors.blackCard,
        shape: const RoundedRectangleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_outline,
                color: AppColors.green,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'PROFILE CREATED',
                style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 16,
                  letterSpacing: 4,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Welcome to VerdeX.',
                style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 12,
                  color: AppColors.textMuted.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 28),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 12,
                  ),
                  color: AppColors.green,
                  child: const Text(
                    'CONTINUE',
                    style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 11,
                      letterSpacing: 4,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Stack(
          children: [
            // Grid background
            CustomPaint(
              size: MediaQuery.of(context).size,
              painter: _GridPainter(),
            ),

            // Glow top-right
            Positioned(
              top: -60,
              right: -60,
              child: Container(
                width: 320,
                height: 320,
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
              child: Column(
                children: [
                  _buildTopBar(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 20,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(),
                            const SizedBox(height: 32),

                            // ── Section 1: Personal ────────────────────────
                            _SectionLabel(label: '01', title: 'PERSONAL INFO'),
                            const SizedBox(height: 20),

                            _buildMaritalToggle(),
                            const SizedBox(height: 20),

                            Row(
                              children: [
                                Expanded(
                                  child: _GreenField(
                                    label: 'YOUR AGE',
                                    hint: 'e.g. 30',
                                    controller: _ageCtrl,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    validator: (v) {
                                      if (v == null || v.isEmpty) {
                                        return 'Required';
                                      }
                                      final n = int.tryParse(v);
                                      if (n == null || n < 18 || n > 100) {
                                        return '18–100';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),

                            // ── Section 2: Income ──────────────────────────
                            const SizedBox(height: 32),
                            _SectionLabel(label: '02', title: 'YOUR INCOME'),
                            const SizedBox(height: 20),

                            _GreenField(
                              label: 'CURRENT ANNUAL INCOME (\$)',
                              hint: 'e.g. 75000.00',
                              controller: _incomeCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Required';
                                if (double.tryParse(v) == null) {
                                  return 'Enter a valid amount';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            _GreenField(
                              label: 'EXPECTED INCOME RAISE (%)',
                              hint: 'e.g. 5.0',
                              controller: _incomeRaiseCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              suffix: '%',
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Required';
                                final n = double.tryParse(v);
                                if (n == null) return 'Enter a valid %';
                                if (n < 0 || n > 100) return '0–100';
                                return null;
                              },
                            ),

                            // ── Section 3: Spouse (conditional) ───────────
                            if (_isMarried) ...[
                              const SizedBox(height: 32),
                              _SectionLabel(
                                label: '03',
                                title: 'SPOUSE DETAILS',
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Optional — leave blank if not applicable',
                                style: TextStyle(
                                  fontFamily: 'Courier',
                                  fontSize: 10,
                                  letterSpacing: 2,
                                  color: AppColors.textMuted.withOpacity(0.3),
                                ),
                              ),
                              const SizedBox(height: 20),
                              _GreenField(
                                label: "SPOUSE'S AGE",
                                hint: 'e.g. 28',
                                controller: _spouseAgeCtrl,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                validator: (v) {
                                  if (v != null && v.isNotEmpty) {
                                    final n = int.tryParse(v);
                                    if (n == null || n < 18 || n > 100) {
                                      return '18–100';
                                    }
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              _GreenField(
                                label: "SPOUSE'S ANNUAL INCOME (\$)",
                                hint: 'e.g. 60000.00',
                                controller: _spouseIncomeCtrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                validator: (v) {
                                  if (v != null && v.isNotEmpty) {
                                    if (double.tryParse(v) == null) {
                                      return 'Enter a valid amount';
                                    }
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              _GreenField(
                                label: "SPOUSE'S EXPECTED RAISE (%)",
                                hint: 'e.g. 3.5',
                                controller: _spouseIncomeRaiseCtrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                suffix: '%',
                                validator: (v) {
                                  if (v != null && v.isNotEmpty) {
                                    final n = double.tryParse(v);
                                    if (n == null) return 'Enter a valid %';
                                    if (n < 0 || n > 100) return '0–100';
                                  }
                                  return null;
                                },
                              ),
                            ],

                            // ── Error message ──────────────────────────────
                            if (_errorMsg != null) ...[
                              const SizedBox(height: 24),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: AppColors.error.withOpacity(0.4),
                                  ),
                                  color: AppColors.error.withOpacity(0.06),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      color: AppColors.error,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _errorMsg!,
                                        style: TextStyle(
                                          fontFamily: 'Courier',
                                          fontSize: 11,
                                          color: AppColors.error.withOpacity(
                                            0.8,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 36),
                            _buildSubmitButton(),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Sub-widgets ─────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.green.withOpacity(0.08),
            width: 1,
          ),
        ),
      ),
      child: Row(
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
          Text(
            'NEW ACCOUNT',
            style: TextStyle(
              fontFamily: 'Courier',
              fontSize: 9,
              letterSpacing: 4,
              color: AppColors.textMuted.withOpacity(0.3),
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
            Container(width: 28, height: 1, color: AppColors.green),
            const SizedBox(width: 10),
            Text(
              'STEP 01 OF 01',
              style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 9,
                letterSpacing: 4,
                color: AppColors.green.withOpacity(0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'BUILD YOUR\nFINANCIAL\nPROFILE.',
          style: TextStyle(
            fontFamily: 'Courier',
            fontSize: 36,
            fontWeight: FontWeight.w900,
            height: 1.05,
            letterSpacing: 2,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'We use this to personalise your\ninvestment recommendations.',
          style: TextStyle(
            fontFamily: 'Courier',
            fontSize: 12,
            height: 1.7,
            color: AppColors.textMuted.withOpacity(0.4),
          ),
        ),
      ],
    );
  }

  Widget _buildMaritalToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MARITAL STATUS',
          style: TextStyle(
            fontFamily: 'Courier',
            fontSize: 10,
            letterSpacing: 3,
            color: AppColors.green.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _StatusChip(
              label: 'SINGLE',
              value: 'single',
              selected: _maritalStatus == 'single',
              onTap: () => setState(() => _maritalStatus = 'single'),
            ),
            const SizedBox(width: 12),
            _StatusChip(
              label: 'MARRIED',
              value: 'married',
              selected: _maritalStatus == 'married',
              onTap: () => setState(() => _maritalStatus = 'married'),
            ),
            const SizedBox(width: 12),
            _StatusChip(
              label: 'DIVORCED',
              value: 'divorced',
              selected: _maritalStatus == 'divorced',
              onTap: () => setState(() => _maritalStatus = 'divorced'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: _isLoading ? null : _submit,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 18),
          color: _isLoading
              ? AppColors.green.withOpacity(0.5)
              : AppColors.green,
          child: Center(
            child: _isLoading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.black,
                    ),
                  )
                : const Text(
                    'CREATE MY PROFILE  →',
                    style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 12,
                      letterSpacing: 4,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ── Reusable Widgets ──────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final String title;
  const _SectionLabel({required this.label, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Courier',
            fontSize: 11,
            color: AppColors.green.withOpacity(0.4),
            letterSpacing: 2,
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 1,
          height: 16,
          color: AppColors.green.withOpacity(0.3),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Courier',
            fontSize: 11,
            letterSpacing: 4,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.green.withOpacity(0.12)
              : Colors.transparent,
          border: Border.all(
            color: selected
                ? AppColors.green
                : AppColors.textMuted.withOpacity(0.15),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Courier',
            fontSize: 10,
            letterSpacing: 3,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color: selected
                ? AppColors.green
                : AppColors.textMuted.withOpacity(0.4),
          ),
        ),
      ),
    );
  }
}

class _GreenField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? suffix;
  final String? Function(String?)? validator;

  const _GreenField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.validator,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Courier',
            fontSize: 10,
            letterSpacing: 3,
            color: AppColors.green.withOpacity(0.65),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          style: const TextStyle(
            fontFamily: 'Courier',
            fontSize: 14,
            color: Colors.white,
            letterSpacing: 1,
          ),
          cursorColor: AppColors.green,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontFamily: 'Courier',
              fontSize: 13,
              color: AppColors.textMuted.withOpacity(0.2),
            ),
            suffixText: suffix,
            suffixStyle: TextStyle(
              fontFamily: 'Courier',
              fontSize: 13,
              color: AppColors.green.withOpacity(0.5),
            ),
            filled: true,
            fillColor: AppColors.blackCard,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(
                color: AppColors.green.withOpacity(0.15),
                width: 1,
              ),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: AppColors.green, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: AppColors.error.withOpacity(0.6)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: AppColors.error, width: 1.5),
            ),
            errorStyle: TextStyle(
              fontFamily: 'Courier',
              fontSize: 9,
              color: AppColors.error.withOpacity(0.8),
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Grid Background ───────────────────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00FF7F).withOpacity(0.025)
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
