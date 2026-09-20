import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../widgets/assignment_card.dart';
import 'login_screen.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final FirestoreService firestoreService = FirestoreService();
  final AuthService authService = AuthService();

  DateTime? lastBackPress;

  Future<void> logout() async {
    await authService.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        final now = DateTime.now();

        if (lastBackPress == null ||
            now.difference(lastBackPress!) > const Duration(seconds: 2)) {
          lastBackPress = now;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back again to exit'),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          if (Platform.isAndroid) {
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: FutureBuilder<String?>(
            future: authService.getUserClassId(),
            builder: (context, classIdSnapshot) {
              if (classIdSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                );
              }

              final classId = classIdSnapshot.data ?? '';

              if (classId.isEmpty) {
                return _buildNoClassState();
              }

              return StreamBuilder<QuerySnapshot>(
                stream: firestoreService.getAssignmentsForClass(classId),
                builder: (context, snapshot) {
                  final assignments = snapshot.data?.docs ?? [];

                  return CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: _buildHeader(),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            20,
                            26,
                            20,
                            14,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Your Assignments',
                                      style: AppText.heading,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Keep track of your class work',
                                      style: AppText.caption,
                                    ),
                                  ],
                                ),
                              ),
                              if (snapshot.hasData)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 11,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primarySoft,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${assignments.length} ${assignments.length == 1 ? 'task' : 'tasks'}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (snapshot.connectionState == ConnectionState.waiting)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      else if (snapshot.hasError)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _buildErrorState(),
                        )
                      else if (assignments.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _buildEmptyState(),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(
                            20,
                            0,
                            20,
                            28,
                          ),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final data = assignments[index].data()
                                    as Map<String, dynamic>;

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: StudentAssignmentCard(
                                    assignmentId: assignments[index].id,
                                    title: data['title'] ?? '',
                                    description: data['description'] ?? '',
                                    dueDate: data['dueDate'] ?? '',
                                    hasTeacherFile:
                                        (data['fileUrl'] ?? '').isNotEmpty,
                                  ),
                                );
                              },
                              childCount: assignments.length,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 14, 22),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: AppColors.line,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.school_rounded,
              color: AppColors.primary,
              size: 25,
            ),
          ),
          const SizedBox(width: 13),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back!',
                  style: AppText.caption,
                ),
                SizedBox(height: 2),
                Text(
                  'Student Dashboard',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: AppColors.dangerSoft,
            borderRadius: BorderRadius.circular(13),
            child: InkWell(
              onTap: logout,
              borderRadius: BorderRadius.circular(13),
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  Icons.logout_rounded,
                  color: AppColors.danger,
                  size: 21,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.assignment_turned_in_outlined,
                size: 38,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No assignments yet',
              style: AppText.heading,
            ),
            const SizedBox(height: 7),
            const Text(
              'Your teacher has not posted any assignments yet.',
              textAlign: TextAlign.center,
              style: AppText.caption,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoClassState() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: AppColors.warningSoft,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.groups_outlined,
                      size: 38,
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'No class joined',
                    style: AppText.heading,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please contact your teacher and ask for the Class Code.',
                    textAlign: TextAlign.center,
                    style: AppText.caption,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: AppColors.dangerSoft,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: AppColors.danger,
                size: 34,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: AppText.heading,
            ),
            const SizedBox(height: 6),
            const Text(
              'We could not load your assignments.',
              textAlign: TextAlign.center,
              style: AppText.caption,
            ),
          ],
        ),
      ),
    );
  }
}
