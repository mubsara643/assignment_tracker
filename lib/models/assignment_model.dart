class AssignmentModel {
  final String title;
  final String description;
  final String dueDate;
  final String grade;
  final String comments;

  AssignmentModel({
    required this.title,
    required this.description,
    required this.dueDate,
    this.grade = 'Not graded',
    this.comments = 'No comments yet',
  });
}
