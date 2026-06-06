import '../../../../shared/domain/entities/app_user.dart';

class PlatformUser {
  const PlatformUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.isVerified,
    required this.isActive,
    this.agencyName,
    this.createdAt,
  });

  final String id;
  final String email;
  final String fullName;
  final UserRole role;
  final bool isVerified;
  final bool isActive;
  final String? agencyName;
  final DateTime? createdAt;
}
