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
          .select('*, users:users!user_id(full_name), rooms(name)')
          .inFilter('room_id', ids)
          .order('created_at', ascending: false);
      return right<Failure, List<Booking>>(rows.map((row) => BookingDto.fromJson(row)).toList());
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Booking>>> getBookingsForRoom(String roomId) async {
    try {
      final rows = await _service.requireClient
          .from(SupabaseTables.bookings)
          .select('*, users:users!user_id(full_name), rooms(name)')
          .eq('room_id', roomId)
          .order('booking_date', ascending: false);
      return right<Failure, List<Booking>>(rows.map((row) => BookingDto.fromJson(row)).toList());
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Booking>>> getBookingsForUser(String userId) async {
    try {
      final rows = await _service.requireClient
          .from(SupabaseTables.bookings)
          .select('*, users:users!user_id(full_name), rooms(name)')
          .eq('user_id', userId)
          .order('booking_date', ascending: false);
      return right<Failure, List<Booking>>(rows.map((row) => BookingDto.fromJson(row)).toList());
    } catch (error, stackTrace) {
      return left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, Booking>> getBookingById(String id) async {
    try {
      final row = await _service.requireClient
          .from(SupabaseTables.bookings)
          .select('*, users:users!user_id(full_name), rooms(name)')
          .eq('id', id)
          .single();
      return right(BookingDto.fromJson(row));
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, Booking>> createBooking(Map<String, dynamic> payload) async {
    try {
      final couponId = payload.remove('coupon_id');
      final discountAmount = payload.remove('discount_amount');

      if (couponId != null) {
        // Pre-check if the coupon is already used by this user
        final userCoupon = await _service.requireClient
            .from('user_coupons')
            .select('is_used')
            .eq('user_id', payload['user_id'])
            .eq('coupon_id', couponId)
            .maybeSingle();
            
        if (userCoupon != null && userCoupon['is_used'] == true) {
          return left(const UnknownFailure('Gagal: Voucher diskon ini sudah pernah Anda gunakan.'));
        }
      }

      final row = await _service.requireClient
          .from(SupabaseTables.bookings)
          .insert(payload)
          .select()
          .single();
          
      if (couponId != null && discountAmount != null) {
        try {
          // Record the redemption
          await _service.requireClient.from('coupon_redemptions').insert({
            'coupon_id': couponId,
            'user_id': payload['user_id'],
            'booking_id': row['id'],
            'discount_applied': discountAmount,
          });
          
          // Mark as used if it's a user coupon
          await _service.requireClient
              .from('user_coupons')
              .update({'is_used': true, 'used_at': DateTime.now().toIso8601String()})
              .eq('user_id', payload['user_id'])
              .eq('coupon_id', couponId);
        } catch (couponError) {
          // Rollback booking if coupon application fails
          await _service.requireClient.from(SupabaseTables.bookings).delete().eq('id', row['id']);
          return left(const UnknownFailure('Gagal menggunakan voucher: Voucher mungkin sudah pernah diklaim atau tidak valid lagi.'));
        }
      }

      return right(BookingDto.fromJson(row));
    } catch (error) {
      if (error.toString().contains('no_overlap')) {
        return left(UnknownFailure('Jadwal ruangan sudah dibooking pada waktu tersebut. Silakan pilih waktu lain.'));
      }
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
      if (error.toString().contains('no_overlap')) {
        return left(UnknownFailure('Jadwal ruangan sudah dibooking pada waktu tersebut. Silakan pilih waktu lain.'));
      }
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

  @override
  Future<Either<Failure, Unit>> deleteBooking(String id) async {
    try {
      await _service.requireClient
          .from(SupabaseTables.bookings)
          .delete()
          .eq('id', id);
      return right(unit);
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }
}
