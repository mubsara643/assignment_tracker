// assignment_card.dart
//
// ISME KYA HAI:
// - Assignment ka title, description, due date, attachment dikhta hai
// - "Choose File" button - file picker khulta hai
// - File select hone ke baad uska naam dikhta hai + ek cross (X) icon
//   -> cross dabane se selected file remove ho jati hai
// - "Submit" button - jab file select ho tabhi enable hota hai
//
// SETUP (ZAROORI):
// 1. pubspec.yaml mein ye line dependencies ke andar add karein:
//      file_picker: ^8.0.0
//    (terminal mein "flutter pub get" chalayein)
//
// 2. Is file ko apne "lib" folder mein "assignment_card.dart" naam se save karein
//
// 3. Jahan bhi ye card use karna hai (jaise aapki dashboard screen),
//    upar import karein:
//      import 'assignment_card.dart';
//
//    aur use karein:
//      AssignmentCard(
//        title: "data mining",
//        description: "introduction ton data mining tools",
//        dueDate: "20 sept 2026",
//        hasTeacherAttachment: true,
//        onSubmit: (filePath) {
//          // yahan apna submit logic likhein (jaise API call / database save)
//          print("Submitted file: $filePath");
//        },
//      )

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class AssignmentCard extends StatefulWidget {
  final String title;
  final String description;
  final String dueDate;
  final bool hasTeacherAttachment;
  final Function(String filePath)? onSubmit;

  const AssignmentCard({
    super.key,
    required this.title,
    required this.description,
    required this.dueDate,
    this.hasTeacherAttachment = false,
    this.onSubmit,
  });

  @override
  State<AssignmentCard> createState() => _AssignmentCardState();
}

class _AssignmentCardState extends State<AssignmentCard> {
  PlatformFile? _selectedFile;
  bool _isSubmitting = false;
  bool _isSubmitted = false;

  // File choose karne ka function
  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedFile = result.files.first;
      });
    }
  }

  // Galat file select ho jaye to cross se hataane ka function
  void _removeFile() {
    setState(() {
      _selectedFile = null;
    });
  }

  // Submit button ka function
  Future<void> _submitFile() async {
    if (_selectedFile == null) return;

    setState(() {
      _isSubmitting = true;
    });

    // Yahan apna real submit logic daal sakte hain (API/DB call).
    // Abhi ke liye ek chota delay simulate kar rahe hain.
    await Future.delayed(const Duration(seconds: 1));

    if (widget.onSubmit != null) {
      widget.onSubmit!(_selectedFile!.path ?? _selectedFile!.name);
    }

    setState(() {
      _isSubmitting = false;
      _isSubmitted = true;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Assignment submitted successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      color: Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              widget.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              widget.description,
              style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 10),

            // Due date
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 18, color: Colors.red),
                const SizedBox(width: 6),
                Text(
                  "Due: ${widget.dueDate}",
                  style: const TextStyle(
                      color: Colors.red, fontWeight: FontWeight.w500),
                ),
              ],
            ),

            // Teacher attachment (agar hai to)
            if (widget.hasTeacherAttachment) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.attach_file,
                      size: 18, color: Colors.blue.shade700),
                  const SizedBox(width: 6),
                  Text(
                    "Attachment from teacher",
                    style: TextStyle(color: Colors.blue.shade700),
                  ),
                ],
              ),
            ],

            const Divider(height: 28),

            // Agar already submit ho chuka hai to sirf status dikhao
            if (_isSubmitted)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade700),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Submitted",
                            style: TextStyle(
                              color: Colors.green.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _selectedFile?.name ?? "",
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isSubmitted = false;
                        });
                      },
                      child: const Text("Edit"),
                    ),
                  ],
                ),
              )
            else ...[
              // Choose File button
              OutlinedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.upload_file),
                label: const Text("Choose File"),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                ),
              ),

              // Selected file ka naam + cross (X) button
              if (_selectedFile != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.insert_drive_file,
                          size: 18, color: Colors.blueGrey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedFile!.name,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      // Cross icon - galat file remove karne ke liye
                      GestureDetector(
                        onTap: _removeFile,
                        child: const Icon(Icons.close,
                            size: 20, color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Submit button - file select hone par hi enabled
              ElevatedButton(
                onPressed: (_selectedFile != null && !_isSubmitting)
                    ? _submitFile
                    : null,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 46),
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text("Submit"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
