import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

class SubmitAssignmentScreen extends StatefulWidget {
  final String assignmentId;
  final String assignmentTitle;

  const SubmitAssignmentScreen({
    super.key,
    required this.assignmentId,
    required this.assignmentTitle,
  });

  @override
  State<SubmitAssignmentScreen> createState() => _SubmitAssignmentScreenState();
}

class _SubmitAssignmentScreenState extends State<SubmitAssignmentScreen> {
  String? selectedFileName;
  String? previouslySubmittedFile;
  bool isLoading = false;
  bool isChecking = true;
  final FirestoreService firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    loadExistingSubmission();
  }

  void loadExistingSubmission() async {
    String email = FirebaseAuth.instance.currentUser?.email ?? '';
    var db = FirebaseFirestore.instance;
    var result = await db
        .collection('submissions')
        .where('assignmentId', isEqualTo: widget.assignmentId)
        .where('studentName', isEqualTo: email)
        .get();

    if (result.docs.isNotEmpty) {
      var data = result.docs.first.data();
      setState(() {
        previouslySubmittedFile = data['fileName'];
        selectedFileName = data['fileName'];
      });
    }
    setState(() => isChecking = false);
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
    setState(() {
      selectedFileName = null;
      previouslySubmittedFile = null;
    });
  }

  void handleSubmit() async {
    setState(() => isLoading = true);
    String studentEmail = FirebaseAuth.instance.currentUser?.email ?? 'Unknown';

    if (selectedFileName == null) {
      // File remove ki gayi thi -> submission delete karo
      var db = FirebaseFirestore.instance;
      var existing = await db
          .collection('submissions')
          .where('assignmentId', isEqualTo: widget.assignmentId)
          .where('studentName', isEqualTo: studentEmail)
          .get();
      for (var doc in existing.docs) {
        await doc.reference.delete();
      }

      setState(() {
        isLoading = false;
        previouslySubmittedFile = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Submission removed'),
              backgroundColor: Colors.orange),
        );
        Navigator.pop(context);
      }
      return;
    }


    await firestoreService.submitAssignment(
      widget.assignmentId,
      widget.assignmentTitle,
      studentEmail,
      selectedFileName!,
    );

    setState(() {
      isLoading = false;
      previouslySubmittedFile = selectedFileName;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Assignment submitted!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool hasChanged = selectedFileName != previouslySubmittedFile;

    return Scaffold(
      appBar: AppBar(title: const Text('Submit Assignment')),
      body: isChecking
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.assignmentTitle,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  if (previouslySubmittedFile != null)
                    Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle,
                              color: Colors.green, size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                                'Already submitted. Replace or remove below.',
                                style: TextStyle(
                                    color: Colors.green, fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                  const Text('Your File',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey)),
                  const SizedBox(height: 10),
                  if (selectedFileName == null)
                    OutlinedButton.icon(
                      onPressed: pickFile,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.attach_file),
                      label: const Text('Choose PDF or Image'),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.insert_drive_file,
                              color: Colors.blue),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(selectedFileName!,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            tooltip: 'Remove file',
                            onPressed: removeFile,
                          ),
                        ],
                      ),
                    ),
                  if (selectedFileName != null) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: pickFile,
                        icon: const Icon(Icons.swap_horiz, size: 18),
                        label: const Text('Replace File'),
                      ),
                    ),
                  ],
                  const Spacer(),
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16)),
                            onPressed: !hasChanged ? null : handleSubmit,
                            child: FittedBox(
                              child: Text(
                                selectedFileName == null
                                    ? 'Submit Assignment'
                                    : (previouslySubmittedFile == null
                                        ? 'Submit Assignment'
                                        : 'Submit Assignment'),
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ),
                ],
              ),
            ),
    );
  }
}




