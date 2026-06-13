class Agency {
  const Agency({
    required this.id,
    required this.adminId,
    required this.name,
    required this.slug,
    required this.isActive,
    required this.approvalStatus,
    required this.roomCount,
    required this.bookingCount,
    this.city,
    this.createdAt,
    this.rejectedAt,
    this.approvedAt,
    this.rejectionReason,
  });

  final String id;
  final String adminId;
  final String name;
  final String slug;
  final bool isActive;
  final String approvalStatus;
  final int roomCount;
  final int bookingCount;
  final String? city;
  final DateTime? createdAt;
  final DateTime? approvedAt;
  final DateTime? rejectedAt;
  final String? rejectionReason;
}
