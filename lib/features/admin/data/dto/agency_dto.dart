import '../../domain/entities/agency.dart';

class AgencyDto extends Agency {
  const AgencyDto({
    required super.id,
    required super.adminId,
    required super.name,
    required super.slug,
    required super.isActive,
    required super.approvalStatus,
    required super.roomCount,
    required super.bookingCount,
    super.city,
    super.createdAt,
    super.approvedAt,
    super.rejectedAt,
    super.rejectionReason,
  });

  factory AgencyDto.fromJson(Map<String, dynamic> json) {
    return AgencyDto(
      id: json['id'] as String,
      adminId: json['admin_id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      isActive: json['is_active'] as bool? ?? false,
      approvalStatus: json['approval_status'] as String? ?? 'pending',
      roomCount: json['room_count'] as int? ?? 0,
      bookingCount: json['booking_count'] as int? ?? 0,
      city: json['city'] as String?,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      approvedAt: DateTime.tryParse(json['approved_at']?.toString() ?? ''),
      rejectedAt: DateTime.tryParse(json['rejected_at']?.toString() ?? ''),
      rejectionReason: json['rejection_reason'] as String?,
    );
  }
}
