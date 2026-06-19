import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/config/app_env.dart';
import '../../../../core/constants/supabase_tables.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../../domain/entities/payment.dart';
import '../../domain/repositories/payment_repository.dart';

class SupabasePaymentRepository implements PaymentRepository {
  const SupabasePaymentRepository(this._service);

  final SupabaseService _service;

  @override
  Future<Either<Failure, Payment>> createPayment(PaymentRequest request) async {
    try {
      final pendingRows = await _service.requireClient
          .from(SupabaseTables.payments)
          .select()
          .eq('booking_id', request.bookingId)
          .eq('transaction_status', PaymentStatus.pending.value)
          .order('created_at', ascending: false)
          .limit(1);
      if (pendingRows.isNotEmpty) {
        return right(Payment.fromJson(pendingRows.first));
      }

      final payload = request.toJson()
        ..removeWhere((_, value) => value == null);
      payload['order_id'] ??= _buildOrderId(request.bookingId);
      payload['amount'] = request.grossAmount;
      payload['status'] = PaymentStatus.pending.value;
      payload['midtrans_order_id'] = payload['order_id'];

      final row = await _service.requireClient
          .from(SupabaseTables.payments)
          .insert(payload)
          .select()
          .single();

      return right(Payment.fromJson(row));
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, Payment>> createMidtransPayment(String bookingId) async {
    try {
      final client = _service.requireClient;
      final session = client.auth.currentSession;
      debugPrint('[payment] createMidtransPayment bookingId=$bookingId');
      debugPrint('[payment] create-payment request body={booking_id: $bookingId}');
      debugPrint('[payment] create-payment hasSession=${session != null}');
      final headers = <String, String>{
        'apikey': AppEnv.supabaseAnonKey,
        'Authorization': 'Bearer ${session?.accessToken ?? AppEnv.supabaseAnonKey}',
      };
      debugPrint('[payment] create-payment endpoint=functions/v1/create-payment');
      debugPrint('[payment] create-payment sendsAuthorization=${headers['Authorization']!.isNotEmpty}');
      final response = await client.functions.invoke(
        'create-payment',
        body: {'booking_id': bookingId},
        headers: headers,
      );
      final data = response.data;
      debugPrint('[payment] create-payment status=${response.status}');
      debugPrint('[payment] create-payment response=$data');
      if (data is! Map) {
        debugPrint('[payment] create-payment invalid response type=${data.runtimeType}');
        return left(const UnknownFailure('Invalid create-payment response.'));
      }

      if (data['error'] != null) {
        debugPrint('[payment] create-payment error=${data['error']}');
        return left(UnknownFailure(data['error'].toString()));
      }

      final paymentData = data['payment'];
      if (paymentData is! Map) {
        debugPrint('[payment] create-payment missing payment payload');
        return left(const UnknownFailure('Payment data was not returned by create-payment.'));
      }

      debugPrint('[payment] create-payment saved payment=${paymentData['id']} order=${paymentData['order_id']}');
      return right(Payment.fromJson(paymentData.cast<String, dynamic>()));
    } catch (error) {
      debugPrint('[payment] createMidtransPayment exception=$error');
      debugPrint(
        '[payment] create-payment failed. Check SUPABASE_URL uses the project root URL '
        '(https://PROJECT_REF.supabase.co), the Edge Function name is create-payment, '
        'and Supabase secrets SUPABASE_SERVICE_ROLE_KEY and MIDTRANS_SERVER_KEY are set.',
      );
      final message = error.toString().contains('Failed to fetch')
          ? 'Gagal menghubungi create-payment di Supabase Edge Function. URL Supabase sudah benar, jadi pastikan function create-payment sudah deploy di project yang sama, verify_jwt/CORS mengizinkan request, dan secret SUPABASE_SERVICE_ROLE_KEY serta MIDTRANS_SERVER_KEY sudah terpasang.'
          : error.toString();
      return left(UnknownFailure(message));
    }
  }

  @override
  Future<Either<Failure, List<Payment>>> getAllPaymentsForAdmin({
    String? status,
  }) async {
    return getAdminPayments(status: status);
  }

  @override
  Future<Either<Failure, List<Payment>>> getAdminPayments({
    String? status,
  }) async {
    try {
      var query = _service.requireClient
          .from(SupabaseTables.payments)
          .select('*, user:users!payments_user_id_fkey(full_name)');

      if (status != null && status.isNotEmpty) {
        query = query.eq('transaction_status', status);
      }

      final rows = await query.order('created_at', ascending: false);
      return right(rows.map(Payment.fromJson).toList());
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, Payment>> getPaymentById(String paymentId) async {
    try {
      final row = await _service.requireClient
          .from(SupabaseTables.payments)
          .select('*, user:users!payments_user_id_fkey(full_name)')
          .eq('id', paymentId)
          .single();

      return right(Payment.fromJson(row));
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, Payment?>> getLatestPaymentByBooking(String bookingId) async {
    try {
      final rows = await _service.requireClient
          .from(SupabaseTables.payments)
          .select()
          .eq('booking_id', bookingId)
          .order('created_at', ascending: false)
          .limit(1);

      if (rows.isEmpty) return right(null);
      return right(Payment.fromJson(rows.first));
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Payment>>> getPaymentsByBooking(String bookingId) async {
    try {
      final rows = await _service.requireClient
          .from(SupabaseTables.payments)
          .select()
          .eq('booking_id', bookingId)
          .order('created_at', ascending: false);

      return right(rows.map(Payment.fromJson).toList());
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Payment>>> getPaymentsByUser(String userId) async {
    try {
      debugPrint('[payment] getPaymentsByUser userId=$userId');
      final rows = await _service.requireClient
          .from(SupabaseTables.payments)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      debugPrint('[payment] getPaymentsByUser rows=${rows.length}');
      return right(rows.map(Payment.fromJson).toList());
    } catch (error) {
      debugPrint('[payment] getPaymentsByUser error=$error');
      return left(UnknownFailure(error.toString()));
    }
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
    try {
      final payload = <String, dynamic>{
        'transaction_status': status.value,
        'transaction_id': transactionId,
        'payment_method': paymentMethod,
        'payment_type': paymentType,
        'midtrans_response': midtransResponse,
        'paid_at': paidAt?.toIso8601String(),
      }..removeWhere((_, value) => value == null);

      final row = await _service.requireClient
          .from(SupabaseTables.payments)
          .update(payload)
          .eq('id', paymentId)
          .select()
          .single();

      return right(Payment.fromJson(row));
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  String _buildOrderId(String bookingId) {
    final safeBookingId = bookingId.replaceAll('-', '');
    final shortBookingId = safeBookingId.length > 12
        ? safeBookingId.substring(0, 12)
        : safeBookingId;
    return 'CR-$shortBookingId-${DateTime.now().millisecondsSinceEpoch}';
  }
}
