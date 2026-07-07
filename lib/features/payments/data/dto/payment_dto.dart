import '../../domain/entities/payment.dart';

class PaymentDto {
  const PaymentDto({
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

  factory PaymentDto.fromJson(Map<String, dynamic> json) {
    return PaymentDto(
      id: json['id'] as String,
      bookingId: json['booking_id'] as String,
      userId: json['user_id'] as String,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'pending',
      paymentMethod: json['payment_method'] as String?,
      isDp: json['is_dp'] as bool? ?? false,
    );
  }

  Payment toEntity() {
    return Payment(
      id: id,
      bookingId: bookingId,
      userId: userId,
      amount: amount,
      status: status,
      paymentMethod: paymentMethod,
      isDp: isDp,
    );
  }
}

extension PaymentDtoX on Payment {
  PaymentDto toDto() {
    return PaymentDto(
      id: id,
      bookingId: bookingId,
      userId: userId,
      amount: amount,
      status: status,
      paymentMethod: paymentMethod,
      isDp: isDp,
    );
  }
}
