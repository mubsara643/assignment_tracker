import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'core/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/student_dashboard.dart';
import 'screens/teacher_dashboard.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Assignment Tracker',
      theme: AppTheme.light,
      // Keeps the layout phone-sized when running on Windows or Chrome.
      builder: (context, child) {
        return ColoredBox(
          color: const Color(0xFFE9ECF5),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SizedBox.expand(child: child),
            ),
          ),
        );
      },
      home: const AuthChecker(),
    );
  }
}

class AuthChecker extends StatefulWidget {
  const AuthChecker({super.key});

  @override
  State<AuthChecker> createState() => _AuthCheckerState();
}

class _AuthCheckerState extends State<AuthChecker> {
  final AuthService authService = AuthService();
  bool isChecking = true;
  Widget destination = const SplashScreen();

  @override
  void initState() {
    super.initState();
    checkLogin();
  }

  Future<void> checkLogin() async {
    final bool loggedIn = await authService.isLoggedIn();
    if (loggedIn) {
      final String? role = await authService.getUserRole();
      if (role == 'teacher') {
        destination = const TeacherDashboard();
      } else if (role == 'student') {
        destination = const StudentDashboard();
      }
    }
    if (!mounted) return;
    setState(() => isChecking = false);
  }

  @override
  Widget build(BuildContext context) {
    if (isChecking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return destination;
  }
}
