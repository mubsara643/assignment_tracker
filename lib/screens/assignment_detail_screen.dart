import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';

class AssignmentDetailScreen extends StatefulWidget {
  final String assignmentId;
  final String title;
  final String description;
  final String dueDate;
  final bool hasTeacherFile;
  final String teacherFileName;

  const AssignmentDetailScreen({
    super.key,
    required this.assignmentId,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.hasTeacherFile,
    required this.teacherFileName,
  });

  @override
  State<AssignmentDetailScreen> createState() => _AssignmentDetailScreenState();
}

class _AssignmentDetailScreenState extends State<AssignmentDetailScreen> {
  final FirestoreService firestoreService = FirestoreService();
  String? selectedFileName;
  String? submittedFileName;
  String marks = '';
  String feedback = '';
  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    loadSubmission();
  }

  void loadSubmission() async {
    String email = FirebaseAuth.instance.currentUser?.email ?? '';
    var doc =
        await firestoreService.getMySubmission(widget.assignmentId, email);
    if (doc != null) {
      var data = doc.data() as Map<String, dynamic>;
      setState(() {
        submittedFileName = data['fileName'];
        selectedFileName = null;
        marks = data['marks'] ?? '';
        feedback = data['feedback'] ?? '';
      });
    }
    setState(() => isLoading = false);
  }

  void pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result != null) {
      setState(() => selectedFileName = result.files.single.name);
    }
  }

  void removeFile() {
    setState(() => selectedFileName = null);
  }

  void handleSubmit() async {
    String email =
        FirebaseAuth.instance.currentUser?.email ?? 'Unknown';

    setState(() => isSaving = true);

    // NEW FILE SELECTED -> SUBMIT IT
    if (selectedFileName != null) {
      await firestoreService.submitAssignment(
        widget.assignmentId,
        widget.title,
        email,
        selectedFileName!,
      );

      setState(() {
        submittedFileName = selectedFileName;
        selectedFileName = null;
        isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
      return;
    }

    // NO NEW FILE + EXISTING SUBMISSION -> UNSUBMIT
    if (submittedFileName != null) {
      await firestoreService.deleteSubmission(
        widget.assignmentId,
        email,
      );

      setState(() {
        submittedFileName = null;
        selectedFileName = null;
        marks = '';
        feedback = '';
        isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assignment unsubmitted'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() => isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final displayedFileName = selectedFileName ?? submittedFileName;

    return Scaffold(
      appBar: AppBar(title: const Text('Assignment')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(widget.title,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.event, size: 16, color: Colors.red),
                    const SizedBox(width: 4),
                    Text('Due: ${widget.dueDate}',
                        style: const TextStyle(color: Colors.red)),
                  ],
                ),
                const Divider(height: 32),
                const Text('Instructions',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 6),
                Text(widget.description,
                    style: TextStyle(color: Colors.grey.shade800, height: 1.4)),
                if (widget.hasTeacherFile) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.attach_file, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(widget.teacherFileName,
                                style: const TextStyle(fontSize: 13))),
                      ],
                    ),
                  ),
                ],
                const Divider(height: 32),
                if (marks.isNotEmpty || feedback.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Grade',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green)),
                        const SizedBox(height: 6),
                        if (marks.isNotEmpty) Text('Marks: $marks'),
                        if (feedback.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text('Feedback: $feedback'),
                          ),
                      ],
                    ),
                  ),
                const Text('Your Work',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 10),
                if (displayedFileName == null)
                  OutlinedButton.icon(
                    onPressed: pickFile,
                    style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    icon: const Icon(Icons.add),
                    label: const Text('Add or Create'),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.insert_drive_file, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(displayedFileName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13)),
                        ),
                        InkWell(
                            onTap: removeFile,
                            child: const Icon(Icons.close, color: Colors.red)),
                      ],
                    ),
                  ),
                if (selectedFileName != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: pickFile,
                      icon: const Icon(Icons.swap_horiz, size: 16),
                      label: const Text('Replace'),
                    ),
                  ),
                const SizedBox(height: 20),
                isSaving
                    ? const Center(child: CircularProgressIndicator())
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: handleSubmit,
                          style: ElevatedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14)),
                          child: Text(
                            selectedFileName != null
                                  ? 'Submit Assignment'
                                  : submittedFileName != null
                                      ? 'Unsubmit'
                                      : 'Select File First',
                          ),
                        ),
                      ),
              ],
            ),
    );
  }
}









