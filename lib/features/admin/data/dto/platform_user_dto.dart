import '../../../../shared/domain/entities/app_user.dart';
import '../../domain/entities/platform_user.dart';

class PlatformUserDto extends PlatformUser {
  const PlatformUserDto({
    required super.id,
    required super.email,
    required super.fullName,
    required super.role,
    required super.isVerified,
    required super.accountStatus,
    super.phone,
    super.agencyName,
    super.agencyId,
    super.lastLoginAt,
    super.createdAt,
  });

  factory PlatformUserDto.fromJson(Map<String, dynamic> json) {
    final agency = json['agencies'];
    String? agencyName;
    String? agencyId;
    if (agency is Map<String, dynamic>) {
      agencyName = agency['name'] as String?;
      agencyId = agency['id'] as String?;
    } else if (agency is List && agency.isNotEmpty) {
      final first = agency.first as Map<String, dynamic>;
      agencyName = first['name'] as String?;
      agencyId = first['id'] as String?;
    }

    return PlatformUserDto(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      role: UserRole.fromDb(json['role'] as String?),
      isVerified: json['is_verified'] as bool? ?? false,
      accountStatus: json['account_status'] as String? ??
          ((json['deleted_at'] as Object?) == null ? 'active' : 'deleted'),
      phone: json['phone'] as String?,
      agencyName: agencyName,
      agencyId: agencyId,
      lastLoginAt: DateTime.tryParse(json['last_login_at']?.toString() ?? ''),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}
