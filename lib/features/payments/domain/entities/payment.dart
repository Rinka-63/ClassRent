enum PaymentStatus {
  pending('pending'),
  capture('capture'),
  settlement('settlement'),
  deny('deny'),
  cancel('cancel'),
  expire('expire'),
  failure('failure'),
  refund('refund');

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
    required this.grossAmount,
    required this.transactionStatus,
    required this.createdAt,
    required this.updatedAt,
    this.orderId,
    this.transactionId,
    this.snapToken,
    this.snapRedirectUrl,
    this.paymentMethod,
    this.paymentType,
    this.midtransResponse,
    this.userName,
    this.paidAt,
    this.expiredAt,
  });

  final String id;
  final String bookingId;
  final String userId;
  final String? orderId;
  final String? transactionId;
  final double grossAmount;
  final String? snapToken;
  final String? snapRedirectUrl;
  final String? paymentMethod;
  final String? paymentType;
  final PaymentStatus transactionStatus;
  final Map<String, dynamic>? midtransResponse;
  final String? userName;
  final DateTime? paidAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? expiredAt;

  double get amount => grossAmount;
  PaymentStatus get status => transactionStatus;
  String? get midtransOrderId => orderId;
  String? get midtransTransactionId => transactionId;
  String? get redirectUrl => snapRedirectUrl;
  DateTime? get settlementTime => paidAt;

  bool get canOpenPaymentPage {
    return transactionStatus == PaymentStatus.pending && snapRedirectUrl != null;
  }

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as String,
      bookingId: json['booking_id'] as String,
      userId: json['user_id'] as String,
      orderId: json['order_id'] as String?,
      transactionId: json['transaction_id'] as String?,
      grossAmount: (json['gross_amount'] as num?)?.toDouble() ??
          (json['amount'] as num?)?.toDouble() ??
          0,
      paymentMethod: json['payment_method'] as String?,
      paymentType: json['payment_type'] as String?,
      transactionStatus: PaymentStatus.fromValue(
        (json['transaction_status'] ?? json['status'] ?? 'pending').toString(),
      ),
      snapToken: json['snap_token'] as String?,
      snapRedirectUrl: json['snap_redirect_url'] as String?,
      midtransResponse:
          (json['midtrans_response'] as Map?)?.cast<String, dynamic>(),
      userName: _parseUserName(json),
      paidAt: _parseDate(json['paid_at']),
      expiredAt: _parseDate(json['expired_at']),
      createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updated_at']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_id': bookingId,
      'user_id': userId,
      'order_id': orderId,
      'transaction_id': transactionId,
      'gross_amount': grossAmount,
      'payment_method': paymentMethod,
      'payment_type': paymentType,
      'transaction_status': transactionStatus.value,
      'snap_token': snapToken,
      'snap_redirect_url': snapRedirectUrl,
      'midtrans_response': midtransResponse,
      'user_name': userName,
      'paid_at': paidAt?.toIso8601String(),
      'expired_at': expiredAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Payment copyWith({
    String? id,
    String? bookingId,
    String? userId,
    String? orderId,
    String? transactionId,
    double? grossAmount,
    PaymentStatus? transactionStatus,
    String? snapToken,
    String? snapRedirectUrl,
    String? paymentMethod,
    String? paymentType,
    Map<String, dynamic>? midtransResponse,
    String? userName,
    DateTime? paidAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? expiredAt,
  }) {
    return Payment(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      userId: userId ?? this.userId,
      orderId: orderId ?? this.orderId,
      transactionId: transactionId ?? this.transactionId,
      grossAmount: grossAmount ?? this.grossAmount,
      transactionStatus: transactionStatus ?? this.transactionStatus,
      snapToken: snapToken ?? this.snapToken,
      snapRedirectUrl: snapRedirectUrl ?? this.snapRedirectUrl,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentType: paymentType ?? this.paymentType,
      midtransResponse: midtransResponse ?? this.midtransResponse,
      userName: userName ?? this.userName,
      paidAt: paidAt ?? this.paidAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expiredAt: expiredAt ?? this.expiredAt,
    );
  }
}

class PaymentRequest {
  const PaymentRequest({
    required this.bookingId,
    required this.userId,
    required this.grossAmount,
    this.orderId,
    this.paymentMethod,
    this.paymentType,
    this.snapToken,
    this.snapRedirectUrl,
    this.midtransResponse,
    this.expiredAt,
  });

  final String bookingId;
  final String userId;
  final String? orderId;
  final double grossAmount;
  final String? paymentMethod;
  final String? paymentType;
  final String? snapToken;
  final String? snapRedirectUrl;
  final Map<String, dynamic>? midtransResponse;
  final DateTime? expiredAt;

  Map<String, dynamic> toJson() {
    return {
      'booking_id': bookingId,
      'user_id': userId,
      'order_id': orderId,
      'gross_amount': grossAmount,
      'payment_method': paymentMethod,
      'payment_type': paymentType,
      'transaction_status': PaymentStatus.pending.value,
      'snap_token': snapToken,
      'snap_redirect_url': snapRedirectUrl,
      'midtrans_response': midtransResponse,
      'expired_at': expiredAt?.toIso8601String(),
    };
  }
}

DateTime? _parseDate(Object? value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

String? _parseUserName(Map<String, dynamic> json) {
  final directName = json['user_name'];
  if (directName != null) return directName.toString();

  final user = json['user'];
  if (user is Map && user['full_name'] != null) {
    return user['full_name'].toString();
  }

  final users = json['users'];
  if (users is Map && users['full_name'] != null) {
    return users['full_name'].toString();
  }

  return null;
}
