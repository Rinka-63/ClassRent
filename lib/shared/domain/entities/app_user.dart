enum UserRole {
  user,
  admin,
  superAdmin;

  static UserRole fromDb(String? value) => switch (value) {
        'ADMIN' || 'admin' => UserRole.admin,
        'SUPER_ADMIN' || 'super_admin' => UserRole.superAdmin,
        _ => UserRole.user,
      };

  String get dbValue => switch (this) {
        UserRole.user => 'user',
        UserRole.admin => 'ADMIN',
        UserRole.superAdmin => 'SUPER_ADMIN',
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
