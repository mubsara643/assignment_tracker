import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random();

    return String.fromCharCodes(
      Iterable.generate(
        6,
        (_) => chars.codeUnitAt(rnd.nextInt(chars.length)),
      ),
    );
  }

  Future<String> createClass(
    String className,
    String section,
    String teacherId, {
    String semester = '',
  }) async {
    String code = _generateCode();

    // Make sure the generated code is unique.
    while (true) {
      final existing = await _db
          .collection('classes')
          .where('joinCode', isEqualTo: code)
          .limit(1)
          .get();

      if (existing.docs.isEmpty) {
        break;
      }

      code = _generateCode();
    }

    await _db.collection('classes').add({
      'className': className,
      'semester': semester,
      'section': section,
      'joinCode': code,
      'teacherId': teacherId,
      'createdAt': DateTime.now().toIso8601String(),
    });

    return code;
  }

  Future<Map<String, dynamic>?> getClassByCode(String code) async {
    final result = await _db
        .collection('classes')
        .where(
          'joinCode',
          isEqualTo: code.trim().toUpperCase(),
        )
        .limit(1)
        .get();

    if (result.docs.isEmpty) return null;

    final data = result.docs.first.data();
    data['id'] = result.docs.first.id;

    return data;
  }

  Stream<QuerySnapshot> getMyClasses(String teacherId) {
    return _db
        .collection('classes')
        .where('teacherId', isEqualTo: teacherId)
        .snapshots();
  }

  Future<DocumentSnapshot?> getClassById(String classId) async {
    if (classId.isEmpty) return null;

    final doc = await _db.collection('classes').doc(classId).get();

    if (!doc.exists) return null;

    return doc;
  }

  Future<int> countStudentsInClass(String classId) async {
    final result = await _db
        .collection('users')
        .where('classId', isEqualTo: classId)
        .get();

    return result.docs.length;
  }

  Future<void> addAssignment(
    String title,
    String description,
    String dueDate,
    String fileUrl,
    String teacherId,
    String classId,
  ) async {
    await _db.collection('assignments').add({
      'title': title,
      'description': description,
      'dueDate': dueDate,
      'fileUrl': fileUrl,
      'teacherId': teacherId,
      'classId': classId,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Stream<QuerySnapshot> getAssignments() {
    return _db
        .collection('assignments')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getAssignmentsForClass(String classId) {
    return _db
        .collection('assignments')
        .where('classId', isEqualTo: classId)
        .snapshots();
  }

  Stream<QuerySnapshot> getAssignmentsByTeacher(String teacherId) {
    return _db
        .collection('assignments')
        .where('teacherId', isEqualTo: teacherId)
        .snapshots();
  }

  Future<void> deleteAssignment(String assignmentId) async {
    final submissions = await _db
        .collection('submissions')
        .where('assignmentId', isEqualTo: assignmentId)
        .get();

    for (final doc in submissions.docs) {
      await doc.reference.delete();
    }

    await _db.collection('assignments').doc(assignmentId).delete();
  }

  Future<void> submitAssignment(
    String assignmentId,
    String assignmentTitle,
    String studentName,
    String fileName,
  ) async {
    final existing = await _db
        .collection('submissions')
        .where(
          'assignmentId',
          isEqualTo: assignmentId,
        )
        .where(
          'studentName',
          isEqualTo: studentName,
        )
        .get();

    if (existing.docs.isNotEmpty) {
      await _db.collection('submissions').doc(existing.docs.first.id).update({
        'fileName': fileName,
        'submittedAt': DateTime.now().toIso8601String(),
      });
    } else {
      await _db.collection('submissions').add({
        'assignmentId': assignmentId,
        'assignmentTitle': assignmentTitle,
        'studentName': studentName,
        'fileName': fileName,
        'submittedAt': DateTime.now().toIso8601String(),
        'marks': '',
        'feedback': '',
      });
    }
  }

  Future<void> deleteSubmission(
    String assignmentId,
    String studentEmail,
  ) async {
    final result = await _db
        .collection('submissions')
        .where(
          'assignmentId',
          isEqualTo: assignmentId,
        )
        .where(
          'studentName',
          isEqualTo: studentEmail,
        )
        .get();

    for (final doc in result.docs) {
      await doc.reference.delete();
    }
  }

  Stream<QuerySnapshot> getSubmissions(String assignmentId) {
    return _db
        .collection('submissions')
        .where(
          'assignmentId',
          isEqualTo: assignmentId,
        )
        .snapshots();
  }

  Future<bool> hasSubmitted(
    String assignmentId,
    String studentEmail,
  ) async {
    final result = await _db
        .collection('submissions')
        .where(
          'assignmentId',
          isEqualTo: assignmentId,
        )
        .where(
          'studentName',
          isEqualTo: studentEmail,
        )
        .get();

    return result.docs.isNotEmpty;
  }

  Future<DocumentSnapshot?> getMySubmission(
    String assignmentId,
    String studentEmail,
  ) async {
    final result = await _db
        .collection('submissions')
        .where(
          'assignmentId',
          isEqualTo: assignmentId,
        )
        .where(
          'studentName',
          isEqualTo: studentEmail,
        )
        .get();

    if (result.docs.isEmpty) return null;

    return result.docs.first;
  }

  Future<void> gradeSubmission(
    String submissionId,
    String marks,
    String feedback,
  ) async {
    await _db.collection('submissions').doc(submissionId).update({
      'marks': marks,
      'feedback': feedback,
    });
  }
}
