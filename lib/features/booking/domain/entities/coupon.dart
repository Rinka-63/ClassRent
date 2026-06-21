class Coupon {
  const Coupon({
    required this.id,
    required this.code,
    required this.name,
    required this.discountType,
    required this.discountValue,
    this.maxDiscountAmount,
    this.isActive = true,
    required this.validFrom,
    this.validUntil,
  });

  final String id;
  final String code;
  final String name;
  final String discountType; // 'percentage', 'fixed_amount', 'free_hours'
  final double discountValue;
  final double? maxDiscountAmount;
  final bool isActive;
  final DateTime validFrom;
  final DateTime? validUntil;

  /// Convenience getter untuk persentase diskon
  int get discountPercent => discountType == 'percentage' ? discountValue.toInt() : 0;

  bool get isValid {
    if (!isActive) return false;
    if (validUntil != null && validUntil!.isBefore(DateTime.now())) return false;
    return true;
  }
}
