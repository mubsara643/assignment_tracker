import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

class ViewSubmissionsScreen extends StatelessWidget {
  final String assignmentId;
  final String assignmentTitle;

  const ViewSubmissionsScreen({
    super.key,
    required this.assignmentId,
    required this.assignmentTitle,
  });

  String formatDate(String isoDate) {
    try {
      DateTime dt = DateTime.parse(isoDate);
      return '${dt.day}/${dt.month}/${dt.year} at ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoDate;
    }
  }

  void showGradeDialog(BuildContext context, FirestoreService service,
      String submissionId, String currentMarks, String currentFeedback) {
    final marksController = TextEditingController(text: currentMarks);
    final feedbackController = TextEditingController(text: currentFeedback);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Grade Submission'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: marksController,
              decoration: const InputDecoration(labelText: 'Marks (e.g. 8/10)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: feedbackController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Feedback'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await service.gradeSubmission(submissionId,
                  marksController.text.trim(), feedbackController.text.trim());
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: Text('Submissions - $assignmentTitle')),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.getSubmissions(assignmentId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No submissions yet'));
          }

          var submissions = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: submissions.length,
            itemBuilder: (context, index) {
              var doc = submissions[index];
              var data = doc.data() as Map<String, dynamic>;
              String fileName = data['fileName'] ?? 'No file';
              String submittedAt = data['submittedAt'] ?? '';
              String marks = data['marks'] ?? '';
              String feedback = data['feedback'] ?? '';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(child: Icon(Icons.person)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(data['studentName'] ?? 'Unknown',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.insert_drive_file,
                              size: 14, color: Colors.blue),
                          const SizedBox(width: 4),
                          Expanded(
                              child: Text(fileName,
                                  style: const TextStyle(fontSize: 12))),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Submitted: ${formatDate(submittedAt)}',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey)),
                      const Divider(height: 20),
                      if (marks.isNotEmpty || feedback.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (marks.isNotEmpty)
                                Text('Marks: $marks',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green)),
                              if (feedback.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text('Feedback: $feedback',
                                      style: const TextStyle(fontSize: 12)),
                                ),
                            ],
                          ),
                        ),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                showGradeDialog(context, firestoreService,
                                    doc.id, marks, feedback);
                              },
                              icon: const Icon(Icons.grade_outlined, size: 16),
                              label: Text(
                                  marks.isEmpty ? 'Add Grade' : 'Edit Grade'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
