class MonthlyDataPoint {
  const MonthlyDataPoint({
    required this.label,
    required this.count,
    this.revenue = 0,
  });

  final String label;
  final int count;
  final double revenue;
}

class PlatformAnalytics {
  const PlatformAnalytics({
    required this.bookingsPerMonth,
    required this.paymentsPerMonth,
    required this.userGrowth,
    required this.agencyGrowth,
    required this.revenuePerMonth,
  });

  final List<MonthlyDataPoint> bookingsPerMonth;
  final List<MonthlyDataPoint> paymentsPerMonth;
  final List<MonthlyDataPoint> userGrowth;
  final List<MonthlyDataPoint> agencyGrowth;
  final List<MonthlyDataPoint> revenuePerMonth;
}
