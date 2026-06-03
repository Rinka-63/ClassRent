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
  });

  factory BookingDto.fromJson(Map<String, dynamic> json) {
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
    );
  }
}
