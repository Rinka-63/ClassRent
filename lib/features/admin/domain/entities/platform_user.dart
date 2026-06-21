import '../../../../shared/domain/entities/app_user.dart';

class PlatformUser {
  const PlatformUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.isVerified,
    required this.accountStatus,
    this.phone,
    this.agencyName,
    this.agencyId,
    this.lastLoginAt,
    this.createdAt,
  });

  final String id;
  final String email;
  final String fullName;
  final UserRole role;
  final bool isVerified;
  final String accountStatus;
  final String? phone;
  final String? agencyName;
  final String? agencyId;
  final DateTime? lastLoginAt;
  final DateTime? createdAt;

  String get statusLabel => switch (accountStatus) {
        'active' => 'Active',
        'pending' => 'Pending',
        'suspended' => 'Suspended',
        'disabled' => 'Disabled',
        'deleted' => 'Deleted',
        _ => isVerified ? 'Active' : 'Pending',
      };
}
