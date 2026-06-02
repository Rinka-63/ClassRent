class PlatformStats {
  const PlatformStats({
    required this.totalAgencies,
    required this.pendingAgencies,
    required this.activeAgencies,
    required this.totalUsers,
    required this.totalRooms,
    required this.totalBookings,
  });

  final int totalAgencies;
  final int pendingAgencies;
  final int activeAgencies;
  final int totalUsers;
  final int totalRooms;
  final int totalBookings;
}
