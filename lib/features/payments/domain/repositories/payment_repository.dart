import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/payment.dart';

abstract class PaymentRepository {
  Future<Either<Failure, Payment>> getPaymentByBookingId(String bookingId);
  Future<Either<Failure, Payment>> createPayment(Map<String, dynamic> payload);
  Future<Either<Failure, Payment>> updatePayment(String id, Map<String, dynamic> payload);
  Future<Either<Failure, List<Payment>>> getPaymentsForUser(String userId);
}
