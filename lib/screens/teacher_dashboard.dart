import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'add_assignment.dart';
import 'login_screen.dart';
import 'view_submissions.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  final FirestoreService firestore = FirestoreService();
  final AuthService auth = AuthService();

  String? selectedClassId;
  bool creatingClass = false;

  final classNameController = TextEditingController();
  final sectionController = TextEditingController();

  String selectedSemester = '7th Semester';

  final List<String> semesters = const [
    '1st Semester',
    '2nd Semester',
    '3rd Semester',
    '4th Semester',
    '5th Semester',
    '6th Semester',
    '7th Semester',
    '8th Semester',
  ];

  @override
  void dispose() {
    classNameController.dispose();
    sectionController.dispose();
    super.dispose();
  }

  Future<void> createClass() async {
    final className = classNameController.text.trim();
    final section = sectionController.text.trim();

    if (className.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter class name'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (section.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter section'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    setState(() => creatingClass = true);

    try {
      final code = await firestore.createClass(
        className,
        section,
        user.uid,
        semester: selectedSemester,
      );

      if (!mounted) return;

      classNameController.clear();
      sectionController.clear();

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Class created! Code: $code',
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => creatingClass = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not create class: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void showCreateClassDialog() {
    classNameController.clear();
    sectionController.clear();
    selectedSemester = '7th Semester';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: const Text(
                'Create New Class',
                style: AppText.heading,
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Create another class for your students.',
                        style: AppText.caption,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: classNameController,
                      decoration: const InputDecoration(
                        labelText: 'Class / Program',
                        hintText: 'e.g. BS Information Technology',
                        prefixIcon: Icon(Icons.class_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: selectedSemester,
                      decoration: const InputDecoration(
                        labelText: 'Semester',
                        prefixIcon: Icon(Icons.school_outlined),
                      ),
                      items: semesters.map((semester) {
                        return DropdownMenuItem(
                          value: semester,
                          child: Text(semester),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedSemester = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: sectionController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Section',
                        hintText: 'e.g. B',
                        prefixIcon: Icon(Icons.groups_outlined),
                      ),
                    ),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(
                20,
                0,
                20,
                20,
              ),
              actions: [
                TextButton(
                  onPressed:
                      creatingClass ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: creatingClass
                      ? null
                      : () async {
                          setDialogState(
                            () => creatingClass = true,
                          );
                          await createClass();
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: creatingClass
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Create Class'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> logout() async {
    await auth.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final teacher = FirebaseAuth.instance.currentUser;

    if (teacher == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please login again.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: firestore.getMyClasses(teacher.uid),
          builder: (context, classSnapshot) {
            if (classSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              );
            }

            if (classSnapshot.hasError) {
              return _errorState(
                classSnapshot.error.toString(),
              );
            }

            final classDocs = classSnapshot.data?.docs ?? [];

            if (classDocs.isEmpty) {
              return _noClassState();
            }

            // If there is no selected class, select the first one.
            if (selectedClassId == null ||
                !classDocs.any(
                  (doc) => doc.id == selectedClassId,
                )) {
              selectedClassId = classDocs.first.id;
            }

            final selectedDoc = classDocs.firstWhere(
              (doc) => doc.id == selectedClassId,
            );

            final data = selectedDoc.data() as Map<String, dynamic>;

            final classId = selectedDoc.id;
            final className = data['className']?.toString() ?? 'My Class';
            final semester = data['semester']?.toString() ?? '';
            final section = data['section']?.toString() ?? '';
            final code = data['joinCode']?.toString() ?? '';

            return Column(
              children: [
                _header(
                  className,
                  semester,
                  section,
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: firestore.getAssignmentsForClass(
                      classId,
                    ),
                    builder: (context, snapshot) {
                      final assignments = snapshot.data?.docs ?? [];

                      return ListView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(
                          20,
                          24,
                          20,
                          110,
                        ),
                        children: [
                          _classSelector(
                            classDocs,
                            classId,
                          ),
                          const SizedBox(height: 16),
                          _classCard(
                            className,
                            semester,
                            section,
                            code,
                            classId,
                          ),
                          const SizedBox(height: 28),
                          Row(
                            children: [
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Assignments',
                                      style: AppText.heading,
                                    ),
                                    SizedBox(height: 3),
                                    Text(
                                      'Manage this class work',
                                      style: AppText.caption,
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primarySoft,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${assignments.length}',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          if (snapshot.connectionState ==
                              ConnectionState.waiting)
                            const Padding(
                              padding: EdgeInsets.all(40),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                ),
                              ),
                            )
                          else if (snapshot.hasError)
                            _errorState(
                              snapshot.error.toString(),
                            )
                          else if (assignments.isEmpty)
                            _emptyAssignments()
                          else
                            ...assignments.map((doc) {
                              final item = doc.data() as Map<String, dynamic>;

                              return _assignmentCard(
                                context,
                                doc.id,
                                item,
                              );
                            }),
                        ],
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: selectedClassId == null
          ? null
          : FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 3,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddAssignmentScreen(
                      classId: selectedClassId!,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'New Assignment',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
    );
  }

  Widget _classSelector(
    List<QueryDocumentSnapshot> classDocs,
    String currentId,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.line,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentId,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
          ),
          items: classDocs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;

            final name = data['className']?.toString() ?? '';
            final semester = data['semester']?.toString() ?? '';
            final section = data['section']?.toString() ?? '';

            final details = [
              if (semester.isNotEmpty) semester,
              if (section.isNotEmpty) 'Section $section',
            ].join(' • ');

            return DropdownMenuItem<String>(
              value: doc.id,
              child: Text(
                details.isEmpty ? name : '$name — $details',
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value == null) return;

            setState(() {
              selectedClassId = value;
            });
          },
        ),
      ),
    );
  }

  Widget _header(
    String className,
    String semester,
    String section,
  ) {
    final details = [
      if (semester.isNotEmpty) semester,
      if (section.isNotEmpty) 'Section $section',
    ].join(' • ');

    return Container(
      padding: const EdgeInsets.fromLTRB(
        20,
        18,
        14,
        20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: AppColors.line,
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome back!',
                  style: AppText.caption,
                ),
                const SizedBox(height: 2),
                Text(
                  className,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                if (details.isNotEmpty)
                  Text(
                    details,
                    style: AppText.caption,
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

  Widget _classCard(
    String className,
    String semester,
    String section,
    String code,
    String classId,
  ) {
    final details = [
      if (semester.isNotEmpty) semester,
      if (section.isNotEmpty) 'Section $section',
    ].join(' • ');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(.15),
            blurRadius: 20,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'YOUR CLASS',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              FutureBuilder<int>(
                future: firestore.countStudentsInClass(
                  classId,
                ),
                builder: (context, snapshot) {
                  return Row(
                    children: [
                      const Icon(
                        Icons.people_alt_outlined,
                        color: Colors.white70,
                        size: 17,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${snapshot.data ?? 0} students',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            className,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (details.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              details,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.12),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.key_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 9),
                const Text(
                  'Class Code',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Text(
                  code,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _assignmentCard(
    BuildContext context,
    String id,
    Map<String, dynamic> data,
  ) {
    final hasFile = (data['fileUrl'] ?? '').toString().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.line,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ViewSubmissionsScreen(
                assignmentId: id,
                assignmentTitle: data['title'] ?? '',
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.assignment_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['title'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      data['description'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.caption,
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 13,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Due ${data['dueDate'] ?? ''}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.warning,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (hasFile) ...[
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.attach_file_rounded,
                            size: 14,
                            color: AppColors.primary,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.danger,
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text(
                        'Delete Assignment',
                      ),
                      content: const Text(
                        'Are you sure you want to delete this assignment?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(
                            ctx,
                          ),
                          child: const Text(
                            'Cancel',
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            await firestore.deleteAssignment(
                              id,
                            );

                            if (ctx.mounted) {
                              Navigator.pop(
                                ctx,
                              );
                            }
                          },
                          child: const Text(
                            'Delete',
                            style: TextStyle(
                              color: AppColors.danger,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyAssignments() {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 48,
        horizontal: 25,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.line,
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 54,
            color: AppColors.primary,
          ),
          SizedBox(height: 14),
          Text(
            'No assignments yet',
            style: AppText.heading,
          ),
          SizedBox(height: 6),
          Text(
            'Create an assignment for this class using the button below.',
            textAlign: TextAlign.center,
            style: AppText.caption,
          ),
        ],
      ),
    );
  }

  Widget _noClassState() {
    return Column(
      children: [
        _header(
          'Teacher Dashboard',
          '',
          '',
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 82,
                    height: 82,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: const Icon(
                      Icons.school_outlined,
                      size: 40,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Create your first class',
                    style: AppText.heading,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Create multiple classes for different semesters and sections.',
                    textAlign: TextAlign.center,
                    style: AppText.caption,
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: showCreateClassDialog,
                      icon: const Icon(
                        Icons.add_rounded,
                      ),
                      label: const Text(
                        'Create Class',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _errorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 55,
              color: AppColors.danger,
            ),
            const SizedBox(height: 15),
            const Text(
              'Something went wrong',
              style: AppText.heading,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: AppText.caption,
            ),
          ],
        ),
      ),
    );
  }
}
