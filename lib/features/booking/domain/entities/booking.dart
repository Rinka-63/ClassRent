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
    this.userName,
    this.roomName,
  });

  final String id;
  final String userId;
  final String roomId;
  final String? facilityId;
  final String? userName;
  final String? roomName;
  final DateTime bookingDate;
  final String startTime;
  final String endTime;
  final double basePrice;
  final double finalPrice;
  final String status;
}
