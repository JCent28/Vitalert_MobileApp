class UserModel {
  final String staffId;
  final String name;
  final String role; // 'Head Nurse', 'Staff Nurse', 'Admin'
  final String status; // 'Active', 'Inactive'
  final String createdAt;

  const UserModel({
    required this.staffId,
    required this.name,
    required this.role,
    this.status = 'Active',
    this.createdAt = '',
  });

  bool get isHeadNurse =>
      role.toLowerCase().contains('head nurse') || role.toLowerCase() == 'admin';

  bool get isStaffNurse => role.toLowerCase().contains('staff nurse');

  bool get isAdmin => role.toLowerCase() == 'admin';

  bool get canManagePatients => isHeadNurse || isAdmin;

  bool get canDeletePatients => isHeadNurse || isAdmin;

  factory UserModel.fromMap(String staffId, Map<String, dynamic> data) {
    return UserModel(
      staffId: staffId,
      name: data['name'] ?? 'Staff Nurse',
      role: data['role'] ?? 'Staff Nurse',
      status: data['status'] ?? 'Active',
      createdAt: data['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'staff_id': staffId,
      'name': name,
      'role': role,
      'status': status,
      'created_at': createdAt,
    };
  }
}
