import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_typography.dart';
import '../../../widgets/circle_icon_button.dart';
import '../../../widgets/custom_text_field.dart';

class ProfileStepAuth extends StatefulWidget {
  final Function(String email, String password)? onNext;

  const ProfileStepAuth({super.key, this.onNext});

  @override
  State<ProfileStepAuth> createState() => _ProfileStepAuthState();
}

class _ProfileStepAuthState extends State<ProfileStepAuth> {
  String email = "";
  String password = "";

  bool get _hasMinLength => password.length >= 6;
  bool get _hasLetters => RegExp(r'[a-zA-Z]').hasMatch(password);
  bool get _hasNumbers => RegExp(r'[0-9]').hasMatch(password);

  bool get _isPasswordValid => _hasMinLength && _hasLetters && _hasNumbers;

  Widget _buildCriteriaRow(String text, bool isMet) {
    return Row(
      children: [
        Icon(
          isMet ? LucideIcons.checkCircle2 : LucideIcons.circle,
          size: 14,
          color: isMet ? AppColors.emerald500 : AppColors.gray400,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: isMet ? AppColors.emerald700 : AppColors.gray500,
            fontWeight: isMet ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ZoomIn(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                      gradient: AppColors.logoGradient, shape: BoxShape.circle),
                  child: const Icon(LucideIcons.lock,
                      color: Colors.white, size: 40),
                ),
              ),
              const SizedBox(height: 32),
              FadeInUp(
                child: Text("Hesabınızı Oluşturun",
                    style: AppTypography.h2, textAlign: TextAlign.center),
              ),
              const SizedBox(height: 12),
              FadeInUp(
                delay: const Duration(milliseconds: 100),
                child: Text(
                    "Giriş yapabilmek için e-posta ve şifre belirleyin",
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.mutedForeground),
                    textAlign: TextAlign.center),
              ),
              const SizedBox(height: 24),
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomTextField(
                        placeholder: "E-posta Adresiniz",
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (v) => setState(() => email = v),
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        placeholder: "Şifreniz",
                        obscureText: true,
                        onChanged: (v) => setState(() => password = v),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Şifre Kriterleri:",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.foreground,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildCriteriaRow("En az 6 karakter uzunluğunda olmalı", _hasMinLength),
                            const SizedBox(height: 6),
                            _buildCriteriaRow("En az bir harf (a-z, A-Z) içermeli", _hasLetters),
                            const SizedBox(height: 6),
                            _buildCriteriaRow("En az bir rakam (0-9) içermeli", _hasNumbers),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FadeInUp(
                delay: const Duration(milliseconds: 300),
                child: CircleIconButton(
                  icon:
                      const Icon(LucideIcons.chevronRight, color: Colors.white),
                  onPressed: (email.isNotEmpty && _isPasswordValid)
                      ? () => widget.onNext?.call(email, password)
                      : null,
                ),
              ),
            ],
          ),
        )
      ],
    );
  }
}
