import 'package:fpdart/fpdart.dart';

import '../../../../core/constants/supabase_tables.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../dto/payment_dto.dart';
import '../../domain/entities/payment.dart';
import '../../domain/repositories/payment_repository.dart';

class SupabasePaymentRepository implements PaymentRepository {
  const SupabasePaymentRepository(this._service);

  final SupabaseService _service;

  @override
  Future<Either<Failure, Payment>> getPaymentByBookingId(String bookingId) async {
    try {
      final row = await _service.requireClient
          .from(SupabaseTables.payments)
          .select()
          .eq('booking_id', bookingId)
          .maybeSingle();
      
      if (row == null) {
        return left(UnknownFailure('Payment not found'));
      }
      
      return right(PaymentDto.fromJson(row).toEntity());
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, Payment>> createPayment(Map<String, dynamic> payload) async {
    try {
      final row = await _service.requireClient
          .from(SupabaseTables.payments)
          .insert(payload)
          .select()
          .single();
      return right(PaymentDto.fromJson(row).toEntity());
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, Payment>> updatePayment(String id, Map<String, dynamic> payload) async {
    try {
      final row = await _service.requireClient
          .from(SupabaseTables.payments)
          .update(payload)
          .eq('id', id)
          .select()
          .single();
      return right(PaymentDto.fromJson(row).toEntity());
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Payment>>> getPaymentsForUser(String userId) async {
    try {
      final rows = await _service.requireClient
          .from(SupabaseTables.payments)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return right(rows.map((row) => PaymentDto.fromJson(row).toEntity()).toList());
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }
}
