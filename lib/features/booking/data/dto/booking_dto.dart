import '../../domain/entities/booking.dart';

class BookingDto extends Booking {
  const BookingDto({
    required super.id,
    required super.userId,
    required super.roomId,
    required super.bookingDate,
    required super.startTime,
    required super.endTime,
    required super.basePrice,
    required super.finalPrice,
    required super.status,
    super.facilityId,
    super.userName,
    super.roomName,
    super.createdAt,
  });

  factory BookingDto.fromJson(Map<String, dynamic> json) {
    // Extract related names if joined
    String? parsedUserName;
    final user = json['users'];
    if (user is Map<String, dynamic>) {
      parsedUserName = user['full_name'] as String?;
    } else if (user is List && user.isNotEmpty) {
      parsedUserName =
          (user.first as Map<String, dynamic>)['full_name'] as String?;
    }
    String? parsedRoomName;
    final room = json['rooms'];
    if (room is Map<String, dynamic>) {
      parsedRoomName = room['name'] as String?;
    } else if (room is List && room.isNotEmpty) {
      parsedRoomName = (room.first as Map<String, dynamic>)['name'] as String?;
    }

    DateTime? parsedCreatedAt;
    if (json['created_at'] != null) {
      parsedCreatedAt = DateTime.parse(json['created_at'].toString());
    }

    return BookingDto(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      roomId: json['room_id'] as String,
      facilityId: json['facility_id'] as String?,
      bookingDate: DateTime.parse(json['booking_date'].toString()),
      startTime: json['start_time'].toString(),
      endTime: json['end_time'].toString(),
      basePrice: (json['base_price'] as num).toDouble(),
      finalPrice: (json['final_price'] as num).toDouble(),
      status: json['status'] as String,
      userName: parsedUserName,
      roomName: parsedRoomName,
      createdAt: parsedCreatedAt,
    );
  }
}
