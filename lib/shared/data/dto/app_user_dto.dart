import '../../domain/entities/app_user.dart';

class AppUserDto extends AppUser {
  const AppUserDto({
    required super.id,
    required super.email,
    required super.fullName,
    required super.role,
    super.phone,
    super.avatarUrl,
    super.isVerified,
  });

  factory AppUserDto.fromJson(Map<String, dynamic> json) {
    return AppUserDto(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      role: UserRole.fromDb(json['role'] as String?),
      isVerified: json['is_verified'] as bool? ?? false,
    );
  }
}
