class Booking {
  const Booking({
    required this.id,
    required this.userId,
    required this.roomId,
    required this.bookingDate,
    required this.startTime,
    required this.endTime,
    required this.basePrice,
    required this.finalPrice,
    required this.status,
    this.facilityId,
  });

  final String id;
  final String userId;
  final String roomId;
  final String? facilityId;
  final DateTime bookingDate;
  final String startTime;
  final String endTime;
  final double basePrice;
  final double finalPrice;
  final String status;
}
