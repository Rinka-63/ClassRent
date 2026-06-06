import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/payment.dart';

abstract interface class PaymentRepository {
  Future<Either<Failure, Payment>> createPayment(PaymentRequest request);
  Future<Either<Failure, Payment>> getPaymentById(String paymentId);
  Future<Either<Failure, Payment>> getPaymentByBookingId(String bookingId);
  Future<Either<Failure, List<Payment>>> getPaymentHistory(String userId);
  Future<Either<Failure, List<Payment>>> getAgencyPayments(String adminId);
  Future<Either<Failure, Unit>> cancelPayment(String paymentId);
}
