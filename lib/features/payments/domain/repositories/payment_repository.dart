import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/payment.dart';

abstract interface class PaymentRepository {
  Future<Either<Failure, Payment>> createPayment(PaymentRequest request);
  Future<Either<Failure, Payment>> createMidtransPayment(String bookingId);
  Future<Either<Failure, Payment>> getPaymentById(String paymentId);
  Future<Either<Failure, Payment?>> getLatestPaymentByBooking(String bookingId);
  Future<Either<Failure, List<Payment>>> getPaymentsByUser(String userId);
  Future<Either<Failure, List<Payment>>> getPaymentsByBooking(String bookingId);
  Future<Either<Failure, List<Payment>>> getAllPaymentsForAdmin({
    String? status,
  });
  Future<Either<Failure, Payment>> updatePaymentStatus({
    required String paymentId,
    required PaymentStatus status,
    Map<String, dynamic>? midtransResponse,
    String? transactionId,
    String? paymentMethod,
    String? paymentType,
    DateTime? paidAt,
  });
}
