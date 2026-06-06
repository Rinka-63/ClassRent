class PlatformStats {
  const PlatformStats({
    required this.totalAgencies,
    required this.activeAgencies,
    required this.pendingAgencies,
    required this.suspendedAgencies,
    required this.totalUsers,
    required this.activeUsersToday,
    required this.totalRooms,
    required this.activeRooms,
    required this.totalBookings,
    required this.pendingBookings,
    required this.approvedBookings,
    required this.completedBookings,
    required this.cancelledBookings,
    required this.totalSuccessfulTransactions,
    required this.revenueThisMonth,
    required this.activeAgenciesToday,
  });

  final int totalAgencies;
  final int activeAgencies;
  final int pendingAgencies;
  final int suspendedAgencies;
  final int totalUsers;
  final int activeUsersToday;
  final int totalRooms;
  final int activeRooms;
  final int totalBookings;
  final int pendingBookings;
  final int approvedBookings;
  final int completedBookings;
  final int cancelledBookings;
  final int totalSuccessfulTransactions;
  final double revenueThisMonth;
  final int activeAgenciesToday;
}
