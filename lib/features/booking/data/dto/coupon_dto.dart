import '../../domain/entities/coupon.dart';

class CouponDto extends Coupon {
  const CouponDto({
    required super.id,
    required super.code,
    required super.name,
    required super.discountType,
    required super.discountValue,
    super.maxDiscountAmount,
    super.isActive = true,
    required super.validFrom,
    super.validUntil,
  });

  factory CouponDto.fromJson(Map<String, dynamic> json) {
    return CouponDto(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String? ?? '',
      discountType: json['discount_type'] as String? ?? 'percentage',
      discountValue: (json['discount_value'] as num?)?.toDouble() ?? 0,
      maxDiscountAmount: json['max_discount_amount'] != null
          ? (json['max_discount_amount'] as num).toDouble()
          : null,
      isActive: json['is_active'] as bool? ?? true,
      validFrom: json['valid_from'] != null
          ? DateTime.parse(json['valid_from'] as String)
          : DateTime.now(),
      validUntil: json['valid_until'] != null
          ? DateTime.parse(json['valid_until'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'discount_type': discountType,
      'discount_value': discountValue,
      'max_discount_amount': maxDiscountAmount,
      'is_active': isActive,
      'valid_from': validFrom.toIso8601String(),
      'valid_until': validUntil?.toIso8601String(),
    };
  }
}
