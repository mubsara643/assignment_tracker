import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/app_text_field.dart';
import '../widgets/error_banner.dart';
import '../widgets/primary_button.dart';
import '../widgets/segmented_toggle.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final classNameController = TextEditingController();
  final sectionController = TextEditingController();
  final classCodeController = TextEditingController();

  String selectedRole = 'student';
  final AuthService authService = AuthService();
  final FirestoreService firestoreService = FirestoreService();
  bool isLoading = false;
  String errorMessage = '';

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    classNameController.dispose();
    sectionController.dispose();
    classCodeController.dispose();
    super.dispose();
  }

  Future<void> handleSignup() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => errorMessage = 'Please fill all required fields');
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      String classId = '';

      if (selectedRole == 'student') {
        final code = classCodeController.text.trim();
        if (code.isEmpty) {
          setState(() {
            isLoading = false;
            errorMessage = 'Please enter your class code';
          });
          return;
        }
        final classData = await firestoreService.getClassByCode(code);
        if (classData == null) {
          if (!mounted) return;
          setState(() {
            isLoading = false;
            errorMessage =
                'Invalid class code. Please check with your teacher.';
          });
          return;
        }
        classId = classData['id'].toString();
      }

      final String? error = await authService.signup(
        name,
        email,
        password,
        selectedRole,
        classId: classId,
      );

      if (error != null) {
        if (!mounted) return;
        setState(() {
          isLoading = false;
          errorMessage = error;
        });
        return;
      }

      if (selectedRole == 'teacher') {
        final className = classNameController.text.trim();
        if (className.isEmpty) {
          if (!mounted) return;
          setState(() {
            isLoading = false;
            errorMessage = '';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Account created! Please log in and create your class.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).pop();
          return;
        }
        final String teacherId = FirebaseAuth.instance.currentUser!.uid;
        await firestoreService.createClass(
          className,
          sectionController.text.trim(),
          teacherId,
        );
      }

      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created! Please log in.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
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
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.line),
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.ink,
                    size: 22,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Create account', style: AppText.title),
            const SizedBox(height: 6),
            Text(
              'Join your class and keep track of every deadline.',
              style: AppText.body.copyWith(color: AppColors.inkSoft),
            ),
            const SizedBox(height: 24),
            const Text('I am a', style: AppText.label),
            const SizedBox(height: 8),
            SegmentedToggle(
              options: const ['Student', 'Teacher'],
              selectedIndex: selectedRole == 'student' ? 0 : 1,
              onChanged: (i) => setState(
                () => selectedRole = i == 0 ? 'student' : 'teacher',
              ),
            ),
            const SizedBox(height: 22),
            AppTextField(
              label: 'Full name',
              hint: 'Your full name',
              icon: Icons.person_outline_rounded,
              controller: nameController,
            ),
            const SizedBox(height: 18),
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
              hint: 'Create a password',
              icon: Icons.lock_outline_rounded,
              controller: passwordController,
              isPassword: true,
            ),
            const SizedBox(height: 18),
            if (selectedRole == 'student')
              AppTextField(
                label: 'Class code',
                hint: 'Code from your teacher',
                icon: Icons.key_rounded,
                controller: classCodeController,
                textCapitalization: TextCapitalization.characters,
              )
            else ...[
              AppTextField(
                label: 'Class name',
                hint: 'e.g. BSIT 6th Semester',
                icon: Icons.class_outlined,
                controller: classNameController,
              ),
              const SizedBox(height: 18),
              AppTextField(
                label: 'Section',
                hint: 'e.g. Section A',
                icon: Icons.groups_outlined,
                controller: sectionController,
              ),
            ],
            if (errorMessage.isNotEmpty) ...[
              const SizedBox(height: 16),
              ErrorBanner(message: errorMessage),
            ],
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Create account',
              isLoading: isLoading,
              onPressed: handleSignup,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Already have an account?', style: AppText.caption),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Log in',
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
