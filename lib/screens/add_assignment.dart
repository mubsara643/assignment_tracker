import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../services/firestore_service.dart';

class AddAssignmentScreen extends StatefulWidget {
  final String classId;

  const AddAssignmentScreen({
    super.key,
    required this.classId,
  });

  @override
  State<AddAssignmentScreen> createState() => _AddAssignmentScreenState();
}

class _AddAssignmentScreenState extends State<AddAssignmentScreen> {
  final titleController = TextEditingController();
  final descController = TextEditingController();
  final dueDateController = TextEditingController();

  final FirestoreService firestoreService = FirestoreService();

  String? selectedFileName;
  bool isLoading = false;

  @override
  void dispose() {
    titleController.dispose();
    descController.dispose();
    dueDateController.dispose();
    super.dispose();
  }

  Future<void> pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null && mounted) {
        setState(() {
          selectedFileName = result.files.single.name;
        });
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not select file: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  void removeFile() {
    setState(() {
      selectedFileName = null;
    });
  }

  Future<void> handleAdd() async {
    final title = titleController.text.trim();
    final description = descController.text.trim();
    final dueDate = dueDateController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an assignment title'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You are not logged in. Please log in again.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    if (widget.classId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No class is connected to this assignment.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await firestoreService.addAssignment(
        title,
        description,
        dueDate,
        selectedFileName ?? '',
        user.uid,
        widget.classId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Assignment posted successfully!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Assignment could not be saved: $e'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Assignment'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create assignment',
                style: AppText.title,
              ),
              const SizedBox(height: 6),
              Text(
                'Add the details your students need to complete the task.',
                style: AppText.body.copyWith(
                  color: AppColors.inkSoft,
                ),
              ),
              const SizedBox(height: 24),
              _sectionLabel('Assignment details'),
              const SizedBox(height: 10),
              _field(
                controller: titleController,
                label: 'Title',
                hint: 'e.g. Mobile App Development Task',
                icon: Icons.title_rounded,
              ),
              const SizedBox(height: 16),
              _field(
                controller: descController,
                label: 'Description',
                hint: 'Write assignment instructions...',
                icon: Icons.description_outlined,
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              _field(
                controller: dueDateController,
                label: 'Due date',
                hint: 'e.g. 20 Sept 2026',
                icon: Icons.calendar_today_outlined,
              ),
              const SizedBox(height: 24),
              _sectionLabel('Attachment'),
              const SizedBox(height: 10),
              if (selectedFileName == null)
                InkWell(
                  onTap: pickFile,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 22,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.attach_file_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Attach a file',
                          style: AppText.heading,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'PDF, JPG, JPEG or PNG',
                          style: AppText.caption,
                        ),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.successSoft,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.insert_drive_file_rounded,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          selectedFileName!,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.label,
                        ),
                      ),
                      IconButton(
                        onPressed: removeFile,
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                ),
              if (selectedFileName != null) ...[
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: pickFile,
                    icon: const Icon(Icons.swap_horiz_rounded),
                    label: const Text('Replace file'),
                  ),
                ),
              ],
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : handleAdd,
                  child: isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Post Assignment'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: AppText.label.copyWith(
        color: AppColors.inkSoft,
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Padding(
          padding: const EdgeInsets.only(
            left: 4,
            right: 4,
          ),
          child: Icon(icon),
        ),
      ),
    );
  }
}
