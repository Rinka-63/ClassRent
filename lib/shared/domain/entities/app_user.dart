enum UserRole {
  user,
  staff,
  admin,
  superAdmin;

  static UserRole fromDb(String? value) => switch (value) {
        'staff' => UserRole.staff,
        'admin' => UserRole.admin,
        'super_admin' => UserRole.superAdmin,
        _ => UserRole.user,
      };

  String get dbValue => switch (this) {
        UserRole.user => 'user',
        UserRole.staff => 'staff',
        UserRole.admin => 'admin',
        UserRole.superAdmin => 'super_admin',
      };
}

class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.phone,
    this.avatarUrl,
    this.isVerified = false,
    this.agencyId,
    this.agencyStatus,
    this.agencyIsActive,
  });

  final String id;
  final String email;
  final String fullName;
  final UserRole role;
  final String? phone;
  final String? avatarUrl;
  final bool isVerified;
  final String? agencyId;
  final String? agencyStatus;
  final bool? agencyIsActive;

  bool get hasApprovedAgency =>
      agencyStatus == 'approved' && agencyIsActive != false;
}
