import 'package:fpdart/fpdart.dart';

import '../../../../core/constants/supabase_tables.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../../domain/entities/coupon.dart';
import '../../domain/repositories/coupon_repository.dart';
import '../dto/coupon_dto.dart';

class SupabaseCouponRepository implements CouponRepository {
  const SupabaseCouponRepository(this._service);

  final SupabaseService _service;

  @override
  Future<Either<Failure, Coupon>> getCouponByCode(String code) async {
    try {
      final response = await _service.requireClient
          .from(SupabaseTables.coupons)
          .select()
          .eq('code', code.toUpperCase())
          .eq('is_active', true)
          .maybeSingle();

      if (response == null) {
        return left(const UnknownFailure('Kupon tidak ditemukan atau sudah tidak aktif.'));
      }

      final coupon = CouponDto.fromJson(response);
      if (!coupon.isValid) {
        return left(const UnknownFailure('Kupon sudah kadaluarsa.'));
      }

      return right(coupon);
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Coupon>>> getAllCoupons() async {
    try {
      final response = await _service.requireClient
          .from(SupabaseTables.coupons)
          .select()
          .eq('is_active', true)
          .order('discount_value', ascending: false);

      final coupons = (response as List)
          .map((e) => CouponDto.fromJson(e))
          .where((c) => c.isValid)
          .toList();

      return right(coupons);
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getClaimedCoupons(String userId) async {
    try {
      final response = await _service.requireClient
          .from('user_coupons')
          .select('coupon_id')
          .eq('user_id', userId);

      final List<String> claimedIds = (response as List)
          .map((row) => row['coupon_id'] as String)
          .toList();

      return right(claimedIds);
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> claimCoupon(String userId, String couponId) async {
    try {
      // Check if already claimed
      final existing = await _service.requireClient
          .from('user_coupons')
          .select('id')
          .eq('user_id', userId)
          .eq('coupon_id', couponId)
          .maybeSingle();

      if (existing != null) {
        return left(const UnknownFailure('Voucher sudah diklaim'));
      }

      await _service.requireClient.from('user_coupons').insert({
        'user_id': userId,
        'coupon_id': couponId,
        'is_used': false,
      });

      return right(null);
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }
}
