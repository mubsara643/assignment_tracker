class ClassModel {
  final String id;
  final String className;
  final String section;
  final String joinCode;
  final String teacherId;

  ClassModel({
    required this.id,
    required this.className,
    required this.section,
    required this.joinCode,
    required this.teacherId,
  });

  factory ClassModel.fromMap(String id, Map<String, dynamic> map) {
    return ClassModel(
      id: id,
      className: map['className'] ?? '',
      section: map['section'] ?? '',
      joinCode: map['joinCode'] ?? '',
      teacherId: map['teacherId'] ?? '',
    );
  }
}
