import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../services/auth_service.dart';
import '../widgets/app_text_field.dart';
import '../widgets/error_banner.dart';
import '../widgets/primary_button.dart';
import 'signup_screen.dart';
import 'student_dashboard.dart';
import 'teacher_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final AuthService authService = AuthService();
  bool isLoading = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    loadSavedCredentials();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> loadSavedCredentials() async {
    final creds = await authService.getSavedCredentials();
    if (!mounted) return;
    if ((creds['email'] ?? '').isNotEmpty) {
      setState(() {
        emailController.text = creds['email'] ?? '';
        passwordController.text = creds['password'] ?? '';
      });
    }
  }

  Future<void> handleLogin() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(
          () => errorMessage = 'Enter your email and password to continue.');
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final String? error = await authService.login(email, password);

      if (error != null) {
        if (!mounted) return;
        setState(() {
          errorMessage = error;
          isLoading = false;
        });
        return;
      }

      final String? role = await authService.getUserRole();
      if (!mounted) return;
      setState(() => isLoading = false);

      final Widget next = role == 'teacher'
          ? const TeacherDashboard()
          : const StudentDashboard();

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => next),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage =
            'Something went wrong. Check your internet connection and try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Welcome back', style: AppText.title),
            const SizedBox(height: 6),
            Text(
              'Log in to see your assignments and deadlines.',
              style: AppText.body.copyWith(color: AppColors.inkSoft),
            ),
            const SizedBox(height: 32),
            AppTextField(
              label: 'Email',
              hint: 'you@university.edu',
              icon: Icons.mail_outline_rounded,
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 18),
            AppTextField(
              label: 'Password',
              hint: 'Enter your password',
              icon: Icons.lock_outline_rounded,
              controller: passwordController,
              isPassword: true,
            ),
            if (errorMessage.isNotEmpty) ...[
              const SizedBox(height: 16),
              ErrorBanner(message: errorMessage),
            ],
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Log in',
              isLoading: isLoading,
              onPressed: handleLogin,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Don't have an account?", style: AppText.caption),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SignupScreen()),
                    );
                  },
                  child: Text(
                    'Sign up',
                    style: AppText.label.copyWith(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
