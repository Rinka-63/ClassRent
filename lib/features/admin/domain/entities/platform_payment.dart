class PlatformPayment {
  const PlatformPayment({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.userName,
    this.paymentMethod,
  });

  final String id;
  final String bookingId;
  final String userId;
  final double amount;
  final String status;
  final DateTime createdAt;
  final String? userName;
  final String? paymentMethod;
}
