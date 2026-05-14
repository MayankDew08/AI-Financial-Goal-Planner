import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';

class SheetHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const SheetHeader({super.key, required this.title, required this.icon});

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, color: AppColors.green, size: 22),
        const SizedBox(width: 12),
        Expanded(
            child: Text(title,
                style: const TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 14,
                    letterSpacing: 3,
                    fontWeight: FontWeight.bold,
                    color: Colors.white))),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Icon(Icons.close,
              color: AppColors.textMuted.withOpacity(0.3), size: 20),
        ),
      ]);
}

class SheetSectionDivider extends StatelessWidget {
  final String label;
  const SheetSectionDivider({super.key, required this.label});

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
            width: 12, height: 1, color: AppColors.green.withOpacity(0.3)),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 8,
                letterSpacing: 3,
                color: AppColors.textMuted.withOpacity(0.35))),
        const SizedBox(width: 8),
        Expanded(
            child:
                Container(height: 1, color: AppColors.green.withOpacity(0.08))),
      ]);
}

class SheetField extends StatelessWidget {
  final String label, hint;
  final TextEditingController ctrl;
  final String? Function(String?)? validator;
  final bool isRequired;
  
  const SheetField(
      {super.key,
      required this.label,
      required this.ctrl,
      required this.hint,
      this.validator,
      this.isRequired = true});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 9,
                  letterSpacing: 3,
                  color: AppColors.green.withOpacity(0.6))),
          const SizedBox(height: 6),
          TextFormField(
            controller: ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
            ],
            validator: validator ??
                (v) => (isRequired && (v == null || v.isEmpty))
                    ? 'Required'
                    : null,
            style: const TextStyle(
                fontFamily: 'Courier', fontSize: 13, color: Colors.white),
            cursorColor: AppColors.green,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 12,
                  color: AppColors.textMuted.withOpacity(0.2)),
              filled: true,
              fillColor: AppColors.blackMid,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
              focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: AppColors.error)),
              errorStyle: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 9,
                  color: AppColors.error.withOpacity(0.8)),
            ),
          ),
        ],
      );
}

class SheetSubmitButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onTap;
  
  const SheetSubmitButton(
      {super.key, required this.label, required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: loading ? null : onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          color: loading ? AppColors.green.withOpacity(0.5) : AppColors.green,
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.black))
                : Text(label,
                    style: const TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 11,
                        letterSpacing: 3,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black)),
          ),
        ),
      );
}
