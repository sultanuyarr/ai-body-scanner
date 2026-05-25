import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_app/config/app_colors.dart';
import 'package:flutter_app/config/app_typography.dart';
import 'package:flutter_app/widgets/primary_button.dart';
import 'package:flutter_app/widgets/custom_text_field.dart';
import 'package:flutter_app/widgets/social_login_button.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../services/api_service.dart';
import '../../ai/user_data_store.dart';
import '../../main.dart'; // For AppRoutes

class LoginScreen extends StatefulWidget {
  final VoidCallback? onLogin;
  final VoidCallback? onRegister;

  const LoginScreen({super.key, this.onLogin, this.onRegister});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen tüm alanları doldurun."), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await ApiService().login(email, password);
      final user = result['user'] as Map<String, dynamic>;

      // Load profile info into UserDataStore
      final store = UserDataStore();
      store.updateName(user['name'] ?? 'Kullanıcı');
      store.updateAge(user['age'] ?? 25);
      store.updateGender(user['gender'] ?? 'female');
      store.updateMeasurements(
        (user['weight'] ?? 60.0).toDouble(),
        (user['height'] ?? 170.0).toDouble(),
      );
      store.updateGoal(user['goal'] ?? 'maintain');
      store.updateEmailAndPassword(user['email'], user['password']);

      setState(() => _isLoading = false);
      
      // Navigate to instructions
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.instructions);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Giriş Hatası"),
          content: Text(e.toString().replaceAll("Exception: ", "")),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Tamam"),
            ),
          ],
        ),
      );
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.purple50, AppColors.white, AppColors.emerald50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 64),

                      // Header with Logo
                      ZoomIn(
                        duration: const Duration(milliseconds: 500),
                        delay: const Duration(milliseconds: 100),
                        child: Center(
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: AppColors.logoGradient,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              LucideIcons.scan,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      FadeInDown(
                        duration: const Duration(milliseconds: 500),
                        delay: const Duration(milliseconds: 200),
                        from: 20,
                        child: Text(
                          'HOŞ GELDİNİZ',
                          style: AppTypography.display.copyWith(fontSize: 40),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: 8),

                      FadeInDown(
                        duration: const Duration(milliseconds: 500),
                        delay: const Duration(milliseconds: 300),
                        from: 10,
                        child: Text(
                          "AI Body Scanner'a giriş yapın",
                          style: AppTypography.body.copyWith(
                            color: AppColors.mutedForeground,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Form
                      FadeInLeft(
                        duration: const Duration(milliseconds: 500),
                        delay: const Duration(milliseconds: 400),
                        from: 20,
                        child: CustomTextField(
                          placeholder: "E-posta adresiniz",
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ),

                      const SizedBox(height: 20),

                      FadeInLeft(
                        duration: const Duration(milliseconds: 500),
                        delay: const Duration(milliseconds: 500),
                        from: 20,
                        child: CustomTextField(
                          placeholder: "Şifreniz",
                          controller: _passwordController,
                          obscureText: true,
                        ),
                      ),

                      const SizedBox(height: 16),

                      FadeInUp(
                        duration: const Duration(milliseconds: 500),
                        delay: const Duration(milliseconds: 600),
                        from: 20,
                        child: PrimaryButton(
                          onPressed: _handleLogin,
                          fullWidth: true,
                          child: const Text("Giriş Yap"),
                        ),
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Row(
                          children: [
                            Expanded(child: Divider(color: AppColors.border)),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                "veya",
                                style: TextStyle(
                                    color: AppColors.mutedForeground, fontSize: 14),
                              ),
                            ),
                            Expanded(child: Divider(color: AppColors.border)),
                          ],
                        ),
                      ),

                      // Register Option
                      FadeInUp(
                        duration: const Duration(milliseconds: 500),
                        delay: const Duration(milliseconds: 650),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Hesabınız yok mu?",
                                style: TextStyle(color: AppColors.mutedForeground)),
                            TextButton(
                              onPressed: widget.onRegister,
                              child: const Text("Kayıt Olun",
                                  style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold)),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

}
