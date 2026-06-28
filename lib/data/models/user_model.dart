class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? studentId;
  final String? department;
  final int? year;
  final String? groupId; // ⬅️ جديد

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.studentId,
    this.department,
    this.year,
    this.groupId, // ⬅️ جديد
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'student',
      studentId: map['student_id'],
      department: map['department'],
      year: map['year'],
      groupId: map['group_id'], // ⬅️ جديد
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'student_id': studentId,
      'department': department,
      'year': year,
      'group_id': groupId, // ⬅️ جديد
    };
  }
}