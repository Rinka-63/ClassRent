class Payment {
  const Payment({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.amount,
    required this.status,
    this.paymentMethod,
    this.isDp = false,
  });

  final String id;
  final String bookingId;
  final String userId;
  final double amount;
  final String status;
  final String? paymentMethod;
  final bool isDp;
}
