import '../../domain/entities/agency.dart';

class AgencyDto extends Agency {
  const AgencyDto({
    required super.id,
    required super.adminId,
    required super.name,
    required super.slug,
    required super.isActive,
    required super.approvalStatus,
    super.city,
    super.createdAt,
  });

  factory AgencyDto.fromJson(Map<String, dynamic> json) {
    return AgencyDto(
      id: json['id'] as String,
      adminId: json['admin_id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      isActive: json['is_active'] as bool? ?? false,
      approvalStatus: json['approval_status'] as String? ?? 'pending',
      city: json['city'] as String?,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}
