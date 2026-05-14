import 'package:flutter/material.dart';
import '../../../core/api/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/sheet_components.dart';

class RetirementGoalSheet extends StatefulWidget {
  final UserProfile user;
  final Function(Map<String, dynamic>) onSubmit;
  final Function(String) onError;
  const RetirementGoalSheet(
      {super.key, required this.user, required this.onSubmit, required this.onError});

  @override
  State<RetirementGoalSheet> createState() => _RetirementGoalSheetState();
}

class _RetirementGoalSheetState extends State<RetirementGoalSheet> {
  final _formKey = GlobalKey<FormState>();
  // Required fields (Form(...) in backend)
  final _retAgeCtrl = TextEditingController(text: '60');
  final _expPctCtrl = TextEditingController(text: '80');
  final _lifeCtrl = TextEditingController(text: '85');
  // Optional fields with backend defaults
  final _postRetReturnCtrl = TextEditingController(text: '7.0');
  final _preRetReturnCtrl = TextEditingController(text: '10.0');
  final _annualIncomeCtrl = TextEditingController(text: '0');
  final _corpusCtrl = TextEditingController(text: '0');
  final _sipCtrl = TextEditingController(text: '0');
  final _sipRaiseCtrl = TextEditingController(text: '0');

  bool _showAdvanced = false;
  bool _loading = false;

  @override
  void dispose() {
    _retAgeCtrl.dispose();
    _expPctCtrl.dispose();
    _lifeCtrl.dispose();
    _postRetReturnCtrl.dispose();
    _preRetReturnCtrl.dispose();
    _annualIncomeCtrl.dispose();
    _corpusCtrl.dispose();
    _sipCtrl.dispose();
    _sipRaiseCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final result = await ApiService.instance.postRetirementGoal(
        // Required
        retirementAge: int.parse(_retAgeCtrl.text),
        postRetirementExpensePct: double.parse(_expPctCtrl.text),
        lifeExpectancy: int.parse(_lifeCtrl.text),
        // Optional — map to backend defaults if blank
        postRetirementReturn: double.tryParse(_postRetReturnCtrl.text) ?? 7.0,
        preRetirementReturn: double.tryParse(_preRetReturnCtrl.text) ?? 10.0,
        annualPostRetirementIncome:
            double.tryParse(_annualIncomeCtrl.text) ?? 0,
        existingCorpus: double.tryParse(_corpusCtrl.text) ?? 0,
        existingMonthlySip: double.tryParse(_sipCtrl.text) ?? 0,
        sipRaisePct: double.tryParse(_sipRaiseCtrl.text) ?? 0,
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onSubmit(result);
      }
    } on ApiException catch (e) {
      if (mounted) {
        Navigator.pop(context);
        widget.onError(e.message);
      }
    } catch (_) {
      if (mounted) {
        Navigator.pop(context);
        widget.onError('Network error. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SheetHeader(
                    title: 'RETIREMENT GOAL',
                    icon: Icons.beach_access_outlined),
                const SizedBox(height: 24),

                // ── Required fields ──────────────────────────────────────
                SheetField(
                    label: 'RETIREMENT AGE',
                    ctrl: _retAgeCtrl,
                    hint: '60',
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      return (n == null || n < 35 || n > 80) ? '35–80' : null;
                    }),
                const SizedBox(height: 12),
                SheetField(
                    label: 'POST-RETIREMENT EXPENSES (% of pre-retirement)',
                    ctrl: _expPctCtrl,
                    hint: '80',
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      return (n == null || n <= 0 || n > 100) ? '1–100' : null;
                    }),
                const SizedBox(height: 12),
                SheetField(
                    label: 'LIFE EXPECTANCY',
                    ctrl: _lifeCtrl,
                    hint: '85',
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      return (n == null || n < 60 || n > 100) ? '60–100' : null;
                    }),
                const SizedBox(height: 20),

                // ── Existing savings ─────────────────────────────────────
                const SheetSectionDivider(label: 'EXISTING SAVINGS'),
                const SizedBox(height: 12),
                SheetField(
                    label: 'EXISTING CORPUS',
                    ctrl: _corpusCtrl,
                    hint: '0',
                    isRequired: false),
                const SizedBox(height: 12),
                SheetField(
                    label: 'EXISTING MONTHLY SIP',
                    ctrl: _sipCtrl,
                    hint: '0',
                    isRequired: false),
                const SizedBox(height: 12),
                SheetField(
                    label: 'ANNUAL SIP STEP-UP (%)',
                    ctrl: _sipRaiseCtrl,
                    hint: '0',
                    isRequired: false),
                const SizedBox(height: 20),

                // ── Advanced toggle ──────────────────────────────────────
                GestureDetector(
                  onTap: () => setState(() => _showAdvanced = !_showAdvanced),
                  child: Row(children: [
                    Icon(
                        _showAdvanced
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: AppColors.green.withOpacity(0.5),
                        size: 16),
                    const SizedBox(width: 8),
                    Text('ADVANCED ASSUMPTIONS',
                        style: TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 9,
                            letterSpacing: 3,
                            color: AppColors.green.withOpacity(0.5))),
                  ]),
                ),
                if (_showAdvanced) ...[
                  const SizedBox(height: 16),
                  SheetField(
                      label: 'PRE-RETIREMENT RETURN (% p.a.)',
                      ctrl: _preRetReturnCtrl,
                      hint: '10.0',
                      validator: (v) {
                        final n = double.tryParse(v ?? '');
                        return (n == null || n <= 0 || n > 20)
                            ? '0.1–20'
                            : null;
                      }),
                  const SizedBox(height: 12),
                  SheetField(
                      label: 'POST-RETIREMENT RETURN (% p.a.)',
                      ctrl: _postRetReturnCtrl,
                      hint: '7.0',
                      validator: (v) {
                        final n = double.tryParse(v ?? '');
                        return (n == null || n <= 0 || n > 20)
                            ? '0.1–20'
                            : null;
                      }),
                  const SizedBox(height: 12),
                  SheetField(
                      label: 'ANNUAL POST-RETIREMENT INCOME (pension, rent...)',
                      ctrl: _annualIncomeCtrl,
                      hint: '0',
                      isRequired: false),
                ],

                const SizedBox(height: 24),
                SheetSubmitButton(
                    label: 'CALCULATE RETIREMENT PLAN',
                    loading: _loading,
                    onTap: _submit),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      );
}
