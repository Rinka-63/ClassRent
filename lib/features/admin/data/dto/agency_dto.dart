import '../../domain/entities/agency.dart';

class AgencyDto extends Agency {
  const AgencyDto({
    required super.id,
    required super.adminId,
    required super.name,
    required super.slug,
    required super.isActive,
    required super.approvalStatus,
    super.ownerName,
    super.ownerEmail,
    super.ownerPhone,
    super.email,
    super.phone,
    super.address,
    super.city,
    super.description,
    super.logoUrl,
    super.createdAt,
    super.roomCount,
    super.bookingCount,
    super.revenue,
  });

  factory AgencyDto.fromJson(Map<String, dynamic> json) {
    final owner = json['users'];
    Map<String, dynamic>? ownerMap;
    if (owner is Map<String, dynamic>) {
      ownerMap = owner;
    } else if (owner is List && owner.isNotEmpty) {
      ownerMap = owner.first as Map<String, dynamic>;
    }

    return AgencyDto(
      id: json['id'] as String,
      adminId: json['admin_id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      isActive: json['is_active'] as bool? ?? false,
      approvalStatus: json['approval_status'] as String? ?? 'pending',
      ownerName: ownerMap?['full_name'] as String?,
      ownerEmail: ownerMap?['email'] as String?,
      ownerPhone: ownerMap?['phone'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      description: json['description'] as String?,
      logoUrl: json['logo_url'] as String?,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      roomCount: json['room_count'] as int? ?? 0,
      bookingCount: json['booking_count'] as int? ?? 0,
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
    );
  }
}
