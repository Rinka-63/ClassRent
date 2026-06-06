import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/unconfigured_payment_repository.dart';
import '../../domain/entities/payment.dart';
import '../../domain/repositories/payment_repository.dart';

class PaymentActionState {
  const PaymentActionState({
    this.isLoading = false,
    this.payment,
    this.errorMessage,
  });

  final bool isLoading;
  final Payment? payment;
  final String? errorMessage;

  PaymentActionState copyWith({
    bool? isLoading,
    Payment? payment,
    String? errorMessage,
    bool clearPayment = false,
    bool clearError = false,
  }) {
    return PaymentActionState(
      isLoading: isLoading ?? this.isLoading,
      payment: clearPayment ? null : payment ?? this.payment,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return const UnconfiguredPaymentRepository();
});

final paymentControllerProvider =
    StateNotifierProvider<PaymentController, PaymentActionState>((ref) {
  return PaymentController(ref.watch(paymentRepositoryProvider));
});

class PaymentController extends StateNotifier<PaymentActionState> {
  PaymentController(this._repository) : super(const PaymentActionState());

  final PaymentRepository _repository;

  Future<bool> createPayment(PaymentRequest request) async {
    state = state.copyWith(
      isLoading: true,
      clearPayment: true,
      clearError: true,
    );

    final result = await _repository.createPayment(request);
    return result.match(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        );
        return false;
      },
      (payment) {
        state = PaymentActionState(payment: payment);
        return true;
      },
    );
  }

  Future<bool> cancelPayment(String paymentId) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.cancelPayment(paymentId);
    return result.match(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        );
        return false;
      },
      (_) {
        state = state.copyWith(isLoading: false);
        return true;
      },
    );
  }
}

final paymentHistoryProvider = FutureProvider<List<Payment>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const [];

  final result =
      await ref.watch(paymentRepositoryProvider).getPaymentHistory(user.id);
  return result.match((failure) => throw failure, (payments) => payments);
});

final paymentDetailProvider =
    FutureProvider.family<Payment, String>((ref, paymentId) async {
  final result =
      await ref.watch(paymentRepositoryProvider).getPaymentById(paymentId);
  return result.match((failure) => throw failure, (payment) => payment);
});

final paymentByBookingProvider =
    FutureProvider.family<Payment, String>((ref, bookingId) async {
  final result =
      await ref.watch(paymentRepositoryProvider).getPaymentByBookingId(bookingId);
  return result.match((failure) => throw failure, (payment) => payment);
});

final agencyPaymentsProvider = FutureProvider<List<Payment>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const [];

  final result =
      await ref.watch(paymentRepositoryProvider).getAgencyPayments(user.id);
  return result.match((failure) => throw failure, (payments) => payments);
});
