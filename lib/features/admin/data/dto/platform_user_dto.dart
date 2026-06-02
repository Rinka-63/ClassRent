import '../../../../shared/domain/entities/app_user.dart';
import '../../domain/entities/platform_user.dart';

class PlatformUserDto extends PlatformUser {
  const PlatformUserDto({
    required super.id,
    required super.email,
    required super.fullName,
    required super.role,
    required super.isVerified,
    super.createdAt,
  });

  factory PlatformUserDto.fromJson(Map<String, dynamic> json) {
    return PlatformUserDto(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      role: UserRole.fromDb(json['role'] as String?),
      isVerified: json['is_verified'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}
