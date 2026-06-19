import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/supabase/supabase_client_provider.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../booking/domain/repositories/booking_repository.dart';
import '../../../booking/presentation/providers/booking_admin_providers.dart';
import '../../data/repositories/supabase_payment_repository.dart';
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

final createPaymentLoadingProvider = Provider<bool>((ref) {
  return ref.watch(paymentControllerProvider).isLoading;
});

final createPaymentErrorProvider = Provider<String?>((ref) {
  return ref.watch(paymentControllerProvider).errorMessage;
});

final createdPaymentProvider = Provider<Payment?>((ref) {
  return ref.watch(paymentControllerProvider).payment;
});

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return SupabasePaymentRepository(
    SupabaseService(ref.watch(supabaseClientProvider)),
  );
});

final adminPaymentStatusFilterProvider = StateProvider<String?>((ref) => null);

final paymentControllerProvider =
    StateNotifierProvider<PaymentController, PaymentActionState>((ref) {
  return PaymentController(
    ref.watch(paymentRepositoryProvider),
    ref.watch(bookingRepositoryProvider),
  );
});

class PaymentController extends StateNotifier<PaymentActionState> {
  PaymentController(this._repository, this._bookingRepository)
      : super(const PaymentActionState());

  final PaymentRepository _repository;
  final BookingRepository _bookingRepository;

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

  Future<bool> createPaymentForBooking(String bookingId) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final bookingResult = await _bookingRepository.getBookingById(bookingId);
    return bookingResult.match(
      (failure) async {
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        );
        return false;
      },
      (booking) async {
        final request = PaymentRequest(
          bookingId: booking.id,
          userId: booking.userId,
          grossAmount: booking.finalPrice,
          expiredAt: DateTime.now().add(const Duration(minutes: 15)),
        );
        return createPayment(request);
      },
    );
  }

  Future<bool> createMidtransPayment(String bookingId) async {
    state = state.copyWith(
      isLoading: true,
      clearPayment: true,
      clearError: true,
    );

    final result = await _repository.createMidtransPayment(bookingId);
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

  Future<bool> updatePaymentStatus({
    required String paymentId,
    required PaymentStatus status,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.updatePaymentStatus(
      paymentId: paymentId,
      status: status,
      paidAt: status == PaymentStatus.settlement ? DateTime.now() : null,
    );
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
}

final paymentHistoryProvider = FutureProvider<List<Payment>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const [];

  final result =
      await ref.watch(paymentRepositoryProvider).getPaymentsByUser(user.id);
  return result.match((failure) => throw failure, (payments) => payments);
});

final paymentDetailProvider =
    FutureProvider.family<Payment, String>((ref, paymentId) async {
  final result =
      await ref.watch(paymentRepositoryProvider).getPaymentById(paymentId);
  return result.match((failure) => throw failure, (payment) => payment);
});

final paymentsByBookingProvider =
    FutureProvider.family<List<Payment>, String>((ref, bookingId) async {
  final result =
      await ref.watch(paymentRepositoryProvider).getPaymentsByBooking(bookingId);
  return result.match((failure) => throw failure, (payments) => payments);
});

final latestPaymentByBookingProvider =
    FutureProvider.family<Payment?, String>((ref, bookingId) async {
  final result =
      await ref.watch(paymentRepositoryProvider).getLatestPaymentByBooking(bookingId);
  return result.match((failure) => throw failure, (payment) => payment);
});

final agencyPaymentsProvider = FutureProvider<List<Payment>>((ref) async {
  if (ref.watch(currentUserProvider) == null) return const [];
  final status = ref.watch(adminPaymentStatusFilterProvider);

  final result = await ref.watch(paymentRepositoryProvider).getAdminPayments(
        status: status,
      );
  return result.match((failure) => throw failure, (payments) => payments);
});

final adminPaymentSummaryProvider = Provider<AdminPaymentSummary>((ref) {
  final payments = ref.watch(agencyPaymentsProvider).valueOrNull ?? const <Payment>[];
  return AdminPaymentSummary.fromPayments(payments);
});

class AdminPaymentSummary {
  const AdminPaymentSummary({
    required this.totalPayment,
    required this.totalPending,
    required this.totalSettlement,
    required this.totalRevenue,
  });

  factory AdminPaymentSummary.fromPayments(List<Payment> payments) {
    const revenueStatuses = {
      PaymentStatus.settlement,
      PaymentStatus.capture,
    };

    return AdminPaymentSummary(
      totalPayment: payments.length,
      totalPending: payments
          .where((payment) => payment.transactionStatus == PaymentStatus.pending)
          .length,
      totalSettlement: payments
          .where((payment) => payment.transactionStatus == PaymentStatus.settlement)
          .length,
      totalRevenue: payments.fold<double>(
        0,
        (total, payment) => revenueStatuses.contains(payment.transactionStatus)
            ? total + payment.grossAmount
            : total,
      ),
    );
  }

  final int totalPayment;
  final int totalPending;
  final int totalSettlement;
  final double totalRevenue;
}
