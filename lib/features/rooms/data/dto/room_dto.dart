import '../../domain/entities/room.dart';

class RoomDto extends Room {
  const RoomDto({
    required super.id,
    required super.adminId,
    required super.name,
    required super.capacity,
    required super.hourlyRate,
    required super.city,
    super.facilityId,
    super.description,
    super.roomType,
    super.areaSqm,
    super.dailyRate,
    super.dpPercentage,
    super.minimumHours,
    super.bufferMinutes,
    super.requiresApproval,
    super.avgRating,
    super.reviewCount,
    super.isActive,
    super.address,
  });

  factory RoomDto.fromJson(Map<String, dynamic> json) {
    return RoomDto(
      id: json['id'] as String,
      facilityId: json['facility_id'] as String?,
      adminId: json['admin_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      roomType: json['room_type'] as String?,
      capacity: json['capacity'] as int,
      areaSqm: (json['area_sqm'] as num?)?.toDouble(),
      hourlyRate: (json['hourly_rate'] as num).toDouble(),
      dailyRate: (json['daily_rate'] as num?)?.toDouble(),
      dpPercentage: json['dp_percentage'] as int? ?? 30,
      minimumHours: json['minimum_hours'] as int? ?? 1,
      bufferMinutes: json['buffer_minutes'] as int? ?? 15,
      requiresApproval: json['requires_approval'] as bool? ?? false,
      avgRating: (json['avg_rating'] as num?)?.toDouble() ?? 0,
      reviewCount: json['review_count'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      city: json['city'] as String,
      address: json['address'] as String?,
    );
  }
}
