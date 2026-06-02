class Agency {
  const Agency({
    required this.id,
    required this.adminId,
    required this.name,
    required this.slug,
    required this.isActive,
    required this.approvalStatus,
    this.city,
    this.createdAt,
  });

  final String id;
  final String adminId;
  final String name;
  final String slug;
  final bool isActive;
  final String approvalStatus;
  final String? city;
  final DateTime? createdAt;
}
