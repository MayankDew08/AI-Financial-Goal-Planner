import 'package:flutter/material.dart';
import '../../../core/api/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/sheet_components.dart';

class OneTimeGoalSheet extends StatefulWidget {
  final String goalName;
  final UserProfile user;
  final Function(Map<String, dynamic>) onSubmit;
  final Function(String) onError;
  const OneTimeGoalSheet(
      {super.key,
      required this.goalName,
      required this.user,
      required this.onSubmit,
      required this.onError});

  @override
  State<OneTimeGoalSheet> createState() => _OneTimeGoalSheetState();
}

class _OneTimeGoalSheetState extends State<OneTimeGoalSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _yearsCtrl = TextEditingController();
  final _returnCtrl = TextEditingController(text: '10.0');
  final _corpusCtrl = TextEditingController(text: '0');
  final _sipCtrl = TextEditingController(text: '0');
  String _risk = 'moderate';
  bool _showAdvanced = false;
  bool _loading = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _yearsCtrl.dispose();
    _returnCtrl.dispose();
    _corpusCtrl.dispose();
    _sipCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final result = await ApiService.instance.postOneTimeGoal(
        goalName: widget.goalName,
        goalAmount: double.parse(_amountCtrl.text),
        yearsToGoal: double.parse(_yearsCtrl.text),
        preRetReturn: double.tryParse(_returnCtrl.text) ?? 10.0,
        existingCorpus: double.tryParse(_corpusCtrl.text) ?? 0,
        existingMonthlySip: double.tryParse(_sipCtrl.text) ?? 0,
        riskTolerance: _risk,
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
                SheetHeader(title: widget.goalName, icon: Icons.flag_outlined),
                const SizedBox(height: 24),

                SheetField(
                    label: 'GOAL AMOUNT IN TODAY\'S VALUE',
                    ctrl: _amountCtrl,
                    hint: 'e.g. 5000000',
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      return (n == null || n <= 0)
                          ? 'Enter a valid amount'
                          : null;
                    }),
                const SizedBox(height: 12),
                SheetField(
                    label: 'YEARS TO GOAL',
                    ctrl: _yearsCtrl,
                    hint: 'e.g. 5',
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      return (n == null || n <= 0 || n > 50)
                          ? '1–50 years'
                          : null;
                    }),
                const SizedBox(height: 20),

                const SheetSectionDivider(label: 'EXISTING SAVINGS'),
                const SizedBox(height: 12),
                SheetField(
                    label: 'EXISTING SAVINGS FOR THIS GOAL',
                    ctrl: _corpusCtrl,
                    hint: '0',
                    isRequired: false),
                const SizedBox(height: 12),
                SheetField(
                    label: 'EXISTING MONTHLY SIP FOR THIS GOAL',
                    ctrl: _sipCtrl,
                    hint: '0',
                    isRequired: false),
                const SizedBox(height: 20),

                // Risk tolerance selector
                Text('RISK TOLERANCE',
                    style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 9,
                        letterSpacing: 3,
                        color: AppColors.green.withOpacity(0.6))),
                const SizedBox(height: 10),
                Row(
                  children: ['low', 'moderate', 'high'].map((r) {
                    final sel = _risk == r;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _risk = r),
                        child: Container(
                          margin: EdgeInsets.only(right: r != 'high' ? 8 : 0),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: sel
                                ? AppColors.green.withOpacity(0.12)
                                : Colors.transparent,
                            border: Border.all(
                                color: sel
                                    ? AppColors.green
                                    : AppColors.textMuted.withOpacity(0.15)),
                          ),
                          child: Center(
                              child: Text(r.toUpperCase(),
                                  style: TextStyle(
                                      fontFamily: 'Courier',
                                      fontSize: 9,
                                      letterSpacing: 2,
                                      color: sel
                                          ? AppColors.green
                                          : AppColors.textMuted
                                              .withOpacity(0.4),
                                      fontWeight: sel
                                          ? FontWeight.bold
                                          : FontWeight.normal))),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Advanced
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
                      label: 'EXPECTED RETURN (% p.a.)',
                      ctrl: _returnCtrl,
                      hint: '10.0',
                      validator: (v) {
                        final n = double.tryParse(v ?? '');
                        return (n == null || n <= 0 || n > 20)
                            ? '0.1–20'
                            : null;
                      }),
                ],

                const SizedBox(height: 24),
                SheetSubmitButton(
                    label: 'CALCULATE GOAL PLAN',
                    loading: _loading,
                    onTap: _submit),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      );
}
