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
  Future<Either<Failure, Payment>> createMidtransPayment(String bookingId) async {
    return const Left(_failure);
  }

  @override
  Future<Either<Failure, List<Payment>>> getAllPaymentsForAdmin({
    String? status,
  }) async {
    return const Left(_failure);
  }

  @override
  Future<Either<Failure, Payment>> getPaymentById(String paymentId) async {
    return const Left(_failure);
  }

  @override
  Future<Either<Failure, Payment?>> getLatestPaymentByBooking(String bookingId) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<Payment>>> getPaymentsByBooking(String bookingId) async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, List<Payment>>> getPaymentsByUser(String userId) async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, Payment>> updatePaymentStatus({
    required String paymentId,
    required PaymentStatus status,
    Map<String, dynamic>? midtransResponse,
    String? transactionId,
    String? paymentMethod,
    String? paymentType,
    DateTime? paidAt,
  }) async {
    return const Left(_failure);
  }
}
