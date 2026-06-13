import 'package:fpdart/fpdart.dart';

import '../../../../core/constants/supabase_tables.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../../domain/entities/booking.dart';
import '../../domain/repositories/booking_repository.dart';
import '../dto/booking_dto.dart';

class SupabaseBookingRepository implements BookingRepository {
  const SupabaseBookingRepository(this._service);

  final SupabaseService _service;

  @override
  Future<Either<Failure, Booking>> getBookingById(String id) async {
    try {
      final row = await _service.requireClient
          .from(SupabaseTables.bookings)
          .select()
          .eq('id', id)
          .single();
      return right(BookingDto.fromJson(row));
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Booking>>> getBookingsForAgency(String adminId) async {
    try {
      final roomIds = await _service.requireClient
          .from(SupabaseTables.rooms)
          .select('id')
          .eq('admin_id', adminId)
          .isFilter('deleted_at', null);
      final ids = roomIds.map((row) => row['id'] as String).toList();
      if (ids.isEmpty) return right(const <Booking>[]);
      final rows = await _service.requireClient
          .from(SupabaseTables.bookings)
          .select()
          .inFilter('room_id', ids)
          .order('created_at', ascending: false);
      return right(rows.map(BookingDto.fromJson).toList());
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Booking>>> getBookingsForRoom(String roomId) async {
    try {
      final rows = await _service.requireClient
          .from(SupabaseTables.bookings)
          .select()
          .eq('room_id', roomId)
          .order('booking_date', ascending: false);
      return right(rows.map(BookingDto.fromJson).toList());
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, Booking>> createBooking(Map<String, dynamic> payload) async {
    try {
      final row = await _service.requireClient
          .from(SupabaseTables.bookings)
          .insert(payload)
          .select()
          .single();
      return right(BookingDto.fromJson(row));
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, Booking>> updateBooking(String id, Map<String, dynamic> payload) async {
    try {
      final row = await _service.requireClient
          .from(SupabaseTables.bookings)
          .update(payload)
          .eq('id', id)
          .select()
          .single();
      return right(BookingDto.fromJson(row));
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> cancelBooking(String id) async {
    try {
      await _service.requireClient
          .from(SupabaseTables.bookings)
          .update({'status': 'cancelled'})
          .eq('id', id);
      return right(unit);
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }
}
