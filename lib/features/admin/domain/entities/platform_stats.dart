class PlatformStats {
  const PlatformStats({
    required this.totalAgencies,
    required this.pendingAgencies,
    required this.activeAgencies,
    required this.approvedAgencies,
    required this.suspendedAgencies,
    required this.totalUsers,
    required this.activeUsers,
    required this.pendingUsers,
    required this.suspendedUsers,
    required this.totalRooms,
    required this.totalBookings,
    required this.totalPayments,
    required this.pendingPayments,
    required this.completedPayments,
    required this.totalRevenue,
  });

  final int totalAgencies;
  final int pendingAgencies;
  final int activeAgencies;
  final int approvedAgencies;
  final int suspendedAgencies;
  final int totalUsers;
  final int activeUsers;
  final int pendingUsers;
  final int suspendedUsers;
  final int totalRooms;
  final int totalBookings;
  final int totalPayments;
  final int pendingPayments;
  final int completedPayments;
  final double totalRevenue;
}
