import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/firestore_service.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../screens/assignment_detail_screen.dart';

class StudentAssignmentCard extends StatefulWidget {
  final String assignmentId;
  final String title;
  final String description;
  final String dueDate;
  final bool hasTeacherFile;

  const StudentAssignmentCard({
    super.key,
    required this.assignmentId,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.hasTeacherFile,
  });

  @override
  State<StudentAssignmentCard> createState() => _StudentAssignmentCardState();
}

class _StudentAssignmentCardState extends State<StudentAssignmentCard> {
  final FirestoreService firestoreService = FirestoreService();

  bool submitted = false;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    checkStatus();
  }

  Future<void> checkStatus() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() => loading = false);
      }
      return;
    }

    final submission = await firestoreService.getMySubmission(
      widget.assignmentId,
      user.email ?? '',
    );

    if (!mounted) return;

    setState(() {
      submitted = submission != null;
      loading = false;
    });
  }

  Future<void> openDetails() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AssignmentDetailScreen(
          assignmentId: widget.assignmentId,
          title: widget.title,
          description: widget.description,
          dueDate: widget.dueDate,
          hasTeacherFile: widget.hasTeacherFile,
          teacherFileName: 'Teacher attachment',
        ),
      ),
    );

    checkStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: openDetails,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.line,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.assignment_outlined,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    if (widget.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        widget.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.caption,
                      ),
                    ],
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        if (widget.dueDate.trim().isNotEmpty)
                          _InfoChip(
                            icon: Icons.calendar_today_outlined,
                            text: widget.dueDate,
                            background: AppColors.warningSoft,
                            foreground: AppColors.warning,
                          ),
                        if (widget.hasTeacherFile)
                          const _InfoChip(
                            icon: Icons.attach_file_rounded,
                            text: 'Attachment',
                            background: AppColors.violetSoft,
                            foreground: AppColors.violet,
                          ),
                        if (!loading)
                          _InfoChip(
                            icon: submitted
                                ? Icons.check_circle_outline_rounded
                                : Icons.access_time_rounded,
                            text: submitted ? 'Submitted' : 'Pending',
                            background: submitted
                                ? AppColors.successSoft
                                : AppColors.primarySoft,
                            foreground: submitted
                                ? AppColors.success
                                : AppColors.primary,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 7),
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.inkSoft,
                  size: 23,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color background;
  final Color foreground;

  const _InfoChip({
    required this.icon,
    required this.text,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: foreground,
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}
