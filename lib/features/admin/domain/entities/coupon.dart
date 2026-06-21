class Coupon {
  final String id;
  final String code;
  final String name;
  final String discountType; // 'percentage', 'fixed_amount', 'free_hours'
  final double discountValue;
  final double? maxDiscountAmount;
  final bool isActive;
  final DateTime validFrom;
  final DateTime? validUntil;
  final String? createdBy;

  Coupon({
    required this.id,
    required this.code,
    required this.name,
    required this.discountType,
    required this.discountValue,
    this.maxDiscountAmount,
    required this.isActive,
    required this.validFrom,
    this.validUntil,
    this.createdBy,
  });

  factory Coupon.fromJson(Map<String, dynamic> json) {
    return Coupon(
      id: json['id'],
      code: json['code'],
      name: json['name'],
      discountType: json['discount_type'],
      discountValue: (json['discount_value'] as num).toDouble(),
      maxDiscountAmount: json['max_discount_amount'] != null ? (json['max_discount_amount'] as num).toDouble() : null,
      isActive: json['is_active'] ?? true,
      validFrom: DateTime.parse(json['valid_from']),
      validUntil: json['valid_until'] != null ? DateTime.parse(json['valid_until']) : null,
      createdBy: json['created_by'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'discount_type': discountType,
      'discount_value': discountValue,
      'max_discount_amount': maxDiscountAmount,
      'is_active': isActive,
      'valid_from': validFrom.toIso8601String(),
      if (validUntil != null) 'valid_until': validUntil!.toIso8601String(),
      if (createdBy != null) 'created_by': createdBy,
    };
  }

  int get discountPercent => discountType == 'percentage' ? discountValue.toInt() : 0;
}
