class PlatformAnalytics {
  const PlatformAnalytics({
    required this.totalUsers,
    required this.totalAgencies,
    required this.totalRooms,
    required this.totalBookings,
    required this.userRegistrationsByMonth,
    required this.agencyRegistrationsByMonth,
    required this.bookingsByMonth,
    required this.topAgencies,
    required this.topRooms,
  });

  final int totalUsers;
  final int totalAgencies;
  final int totalRooms;
  final int totalBookings;
  final List<MonthlyMetric> userRegistrationsByMonth;
  final List<MonthlyMetric> agencyRegistrationsByMonth;
  final List<MonthlyMetric> bookingsByMonth;
  final List<LeaderboardRow> topAgencies;
  final List<LeaderboardRow> topRooms;
}

class MonthlyMetric {
  const MonthlyMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final int value;
}

class LeaderboardRow {
  const LeaderboardRow({
    required this.id,
    required this.label,
    required this.value,
  });

  final String id;
  final String label;
  final int value;
}
