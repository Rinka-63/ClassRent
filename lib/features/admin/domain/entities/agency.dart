class Agency {
  const Agency({
    required this.id,
    required this.adminId,
    required this.name,
    required this.slug,
    required this.isActive,
    required this.approvalStatus,
    this.ownerName,
    this.ownerEmail,
    this.ownerPhone,
    this.email,
    this.phone,
    this.address,
    this.city,
    this.description,
    this.logoUrl,
    this.createdAt,
    this.roomCount = 0,
    this.bookingCount = 0,
    this.revenue = 0,
  });

  final String id;
  final String adminId;
  final String name;
  final String slug;
  final bool isActive;
  final String approvalStatus;
  final String? ownerName;
  final String? ownerEmail;
  final String? ownerPhone;
  final String? email;
  final String? phone;
  final String? address;
  final String? city;
  final String? description;
  final String? logoUrl;
  final DateTime? createdAt;
  final int roomCount;
  final int bookingCount;
  final double revenue;

  String get statusLabel {
    if (approvalStatus == 'pending') return 'Pending';
    if (approvalStatus == 'rejected') return 'Rejected';
    if (approvalStatus == 'suspended') return 'Suspended';
    return isActive ? 'Active' : 'Inactive';
  }
}
