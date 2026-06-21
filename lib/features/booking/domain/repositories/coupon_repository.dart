import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/coupon.dart';

abstract interface class CouponRepository {
  Future<Either<Failure, Coupon>> getCouponByCode(String code);
  Future<Either<Failure, List<Coupon>>> getAllCoupons();
  Future<Either<Failure, List<String>>> getClaimedCoupons(String userId);
  Future<Either<Failure, void>> claimCoupon(String userId, String couponId);
}
