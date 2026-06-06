enum PaymentStatus {
  pending('pending'),
  paid('paid'),
  failed('failed'),
  expired('expired'),
  cancelled('cancelled');

  const PaymentStatus(this.value);

  final String value;

  static PaymentStatus fromValue(String value) {
    return PaymentStatus.values.firstWhere(
      (status) => status.value == value.toLowerCase(),
      orElse: () => PaymentStatus.pending,
    );
  }
}

class Payment {
  const Payment({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.amount,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.agencyId,
    this.midtransOrderId,
    this.midtransTransactionId,
    this.snapToken,
    this.redirectUrl,
    this.paymentMethod,
    this.expiredAt,
    this.settlementTime,
    this.metadata = const {},
  });

  final String id;
  final String bookingId;
  final String userId;
  final String? agencyId;
  final double amount;
  final PaymentStatus status;
  final String? midtransOrderId;
  final String? midtransTransactionId;
  final String? snapToken;
  final String? redirectUrl;
  final String? paymentMethod;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? expiredAt;
  final DateTime? settlementTime;
  final Map<String, Object?> metadata;

  bool get canOpenPaymentPage {
    return status == PaymentStatus.pending && redirectUrl != null;
  }

  Payment copyWith({
    String? id,
    String? bookingId,
    String? userId,
    String? agencyId,
    double? amount,
    PaymentStatus? status,
    String? midtransOrderId,
    String? midtransTransactionId,
    String? snapToken,
    String? redirectUrl,
    String? paymentMethod,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? expiredAt,
    DateTime? settlementTime,
    Map<String, Object?>? metadata,
  }) {
    return Payment(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      userId: userId ?? this.userId,
      agencyId: agencyId ?? this.agencyId,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      midtransOrderId: midtransOrderId ?? this.midtransOrderId,
      midtransTransactionId:
          midtransTransactionId ?? this.midtransTransactionId,
      snapToken: snapToken ?? this.snapToken,
      redirectUrl: redirectUrl ?? this.redirectUrl,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expiredAt: expiredAt ?? this.expiredAt,
      settlementTime: settlementTime ?? this.settlementTime,
      metadata: metadata ?? this.metadata,
    );
  }
}

class PaymentRequest {
  const PaymentRequest({
    required this.bookingId,
    required this.userId,
    required this.amount,
    this.agencyId,
    this.customerName,
    this.customerEmail,
    this.customerPhone,
    this.itemName,
  });

  final String bookingId;
  final String userId;
  final String? agencyId;
  final double amount;
  final String? customerName;
  final String? customerEmail;
  final String? customerPhone;
  final String? itemName;
}
