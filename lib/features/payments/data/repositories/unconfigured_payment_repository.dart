import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/payment.dart';
import '../../domain/repositories/payment_repository.dart';

class UnconfiguredPaymentRepository implements PaymentRepository {
  const UnconfiguredPaymentRepository();

  static const _failure = UnknownFailure(
    'Payment backend is not configured yet. Connect the Midtrans service to enable this flow.',
    code: 'payment_backend_unconfigured',
  );

  @override
  Future<Either<Failure, Payment>> createPayment(PaymentRequest request) async {
    return const Left(_failure);
  }

  @override
  Future<Either<Failure, Unit>> cancelPayment(String paymentId) async {
    return const Left(_failure);
  }

  @override
  Future<Either<Failure, List<Payment>>> getAgencyPayments(String adminId) async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, Payment>> getPaymentByBookingId(String bookingId) async {
    return const Left(_failure);
  }

  @override
  Future<Either<Failure, Payment>> getPaymentById(String paymentId) async {
    return const Left(_failure);
  }

  @override
  Future<Either<Failure, List<Payment>>> getPaymentHistory(String userId) async {
    return const Right([]);
  }
}
