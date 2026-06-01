class Room {
  const Room({
    required this.id,
    required this.adminId,
    required this.name,
    required this.capacity,
    required this.hourlyRate,
    required this.city,
    this.facilityId,
    this.description,
    this.roomType,
    this.areaSqm,
    this.dailyRate,
    this.dpPercentage = 30,
    this.minimumHours = 1,
    this.bufferMinutes = 15,
    this.requiresApproval = false,
    this.avgRating = 0,
    this.reviewCount = 0,
    this.isActive = true,
    this.address,
  });

  final String id;
  final String? facilityId;
  final String adminId;
  final String name;
  final String? description;
  final String? roomType;
  final int capacity;
  final double? areaSqm;
  final double hourlyRate;
  final double? dailyRate;
  final int dpPercentage;
  final int minimumHours;
  final int bufferMinutes;
  final bool requiresApproval;
  final double avgRating;
  final int reviewCount;
  final bool isActive;
  final String city;
  final String? address;
}
