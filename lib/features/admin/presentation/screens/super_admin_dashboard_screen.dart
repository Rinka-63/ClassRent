import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_card.dart';
import '../../../../shared/domain/entities/app_user.dart';
import '../../domain/entities/agency.dart';
import '../../domain/entities/audit_log_entry.dart';
import '../../domain/entities/platform_analytics.dart';
import '../../domain/entities/platform_stats.dart';
import '../../domain/entities/platform_user.dart';
import '../providers/agency_providers.dart';

class SuperAdminDashboardScreen extends ConsumerStatefulWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  ConsumerState<SuperAdminDashboardScreen> createState() => _SuperAdminDashboardScreenState();
}

class _SuperAdminDashboardScreenState extends ConsumerState<SuperAdminDashboardScreen> {
  final _agencySearchController = TextEditingController();
  final _userSearchController = TextEditingController();
  final _auditSearchController = TextEditingController();

  int _currentIndex = 0;
  String _agencyFilter = 'all';
  String _userRoleFilter = 'all';
  String _userStatusFilter = 'all';
  String _auditFilter = 'all';

  @override
  void initState() {
    super.initState();
    _agencySearchController.addListener(_handleTextChanged);
    _userSearchController.addListener(_handleTextChanged);
    _auditSearchController.addListener(_handleTextChanged);
  }

  @override
  void dispose() {
    _agencySearchController.removeListener(_handleTextChanged);
    _userSearchController.removeListener(_handleTextChanged);
    _auditSearchController.removeListener(_handleTextChanged);
    _agencySearchController.dispose();
    _userSearchController.dispose();
    _auditSearchController.dispose();
    super.dispose();
  }

  void _handleTextChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _OverviewTab(),
      _AgenciesTab(
        searchController: _agencySearchController,
        statusFilter: _agencyFilter,
        onStatusChanged: (value) => setState(() => _agencyFilter = value),
      ),
      _UsersTab(
        searchController: _userSearchController,
        roleFilter: _userRoleFilter,
        statusFilter: _userStatusFilter,
        onRoleChanged: (value) => setState(() => _userRoleFilter = value),
        onStatusChanged: (value) => setState(() => _userStatusFilter = value),
      ),
      _AuditLogsTab(
        searchController: _auditSearchController,
        filter: _auditFilter,
        onFilterChanged: (value) => setState(() => _auditFilter = value),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Super Admin'),
            SizedBox(height: 2),
            Text(
              'ClassRent Platform Management',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Data',
            onPressed: _refreshAll,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: () => context.push(AppRoutes.superAdminSettings),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: pages,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.apartment_outlined),
            selectedIcon: Icon(Icons.apartment),
            label: 'Agencies',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Users',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Audit Logs',
          ),
        ],
      ),
    );
  }

  void _refreshAll() {
    ref.invalidate(platformStatsProvider);
    ref.invalidate(platformAnalyticsProvider);
    ref.invalidate(agenciesProvider);
    ref.invalidate(platformUsersProvider);
    ref.invalidate(auditLogsProvider);
  }
}

class _OverviewTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsValue = ref.watch(platformStatsProvider);
    final analyticsValue = ref.watch(platformAnalyticsProvider);
    final auditValue = ref.watch(auditLogsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(platformStatsProvider);
        ref.invalidate(platformAnalyticsProvider);
        ref.invalidate(auditLogsProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          statsValue.when(
            loading: () => const _OverviewSkeleton(height: 200),
            error: (error, _) => ErrorCard(
              message: 'Unable to load overview data. Please try again.',
              onRetry: () => ref.invalidate(platformStatsProvider),
            ),
            data: (stats) => _OverviewHero(stats: stats),
          ),
          const SizedBox(height: 16),
          statsValue.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (stats) => _HeroStatGrid(stats: stats),
          ),
          const SizedBox(height: 16),
          statsValue.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (stats) => _RevenueHealthRow(stats: stats),
          ),
          const SizedBox(height: 16),
          analyticsValue.when(
            loading: () => const _OverviewSkeleton(height: 280),
            error: (error, _) => ErrorCard(
              message: 'Unable to load platform analytics. Please try again.',
              onRetry: () => ref.invalidate(platformAnalyticsProvider),
            ),
            data: (analytics) => _AnalyticsSection(analytics: analytics),
          ),
          const SizedBox(height: 16),
          auditValue.when(
            loading: () => const _OverviewSkeleton(height: 180),
            error: (_, __) => const SizedBox.shrink(),
            data: (logs) => _RecentActivitySection(entries: logs.take(5).toList()),
          ),
        ],
      ),
    );
  }
}

class _OverviewHero extends StatelessWidget {
  const _OverviewHero({required this.stats});

  final PlatformStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryContainer, AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white24,
                child: Icon(Icons.shield_outlined, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Super Admin Overview',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _Badge(label: 'Live', color: Colors.white.withValues(alpha: 0.18)),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            '${stats.totalAgencies} agencies, ${stats.totalUsers} users, ${stats.totalBookings} bookings, ${stats.totalRooms} rooms.',
            style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white.withValues(alpha: 0.92)),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniStat(label: 'Active Agencies', value: stats.activeAgencies.toString()),
              _MiniStat(label: 'Pending', value: stats.pendingAgencies.toString()),
              _MiniStat(label: 'Revenue This Month', value: NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(stats.revenueThisMonth)),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStatGrid extends StatelessWidget {
  const _HeroStatGrid({required this.stats});

  final PlatformStats stats;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _Metric('Total Users', stats.totalUsers, Icons.people_outline, AppColors.primaryContainer),
      _Metric('Total Agencies', stats.totalAgencies, Icons.apartment_outlined, AppColors.secondary),
      _Metric('Pending Agencies', stats.pendingAgencies, Icons.hourglass_top_outlined, AppColors.tertiary),
      _Metric('Total Rooms', stats.totalRooms, Icons.meeting_room_outlined, AppColors.primary),
      _Metric('Total Bookings', stats.totalBookings, Icons.fact_check_outlined, AppColors.secondaryContainer),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: metrics.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 250,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.18,
      ),
      itemBuilder: (_, index) => _MetricCard(metric: metrics[index]),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.82),
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _Metric {
  const _Metric(this.label, this.value, this.icon, this.color);

  final String label;
  final int value;
  final IconData icon;
  final Color color;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final _Metric metric;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(minHeight: 150),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              metric.color.withValues(alpha: 0.18),
              AppColors.surfaceContainerLowest,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  backgroundColor: metric.color.withValues(alpha: 0.12),
                  child: Icon(metric.icon, color: metric.color),
                ),
                _Badge(label: 'Live', color: metric.color.withValues(alpha: 0.12), textColor: metric.color),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${metric.value}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  metric.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RevenueHealthRow extends StatelessWidget {
  const _RevenueHealthRow({required this.stats});

  final PlatformStats stats;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 700;
        final revenueCard = _SummaryCard(
          title: 'Revenue Summary',
          accent: AppColors.secondary,
          lines: [
            'Successful transactions: ${stats.totalSuccessfulTransactions}',
            NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(stats.revenueThisMonth),
          ],
        );
        final healthCard = _SummaryCard(
          title: 'Platform Health',
          accent: AppColors.primary,
          lines: [
            'Active agencies today: ${stats.activeAgenciesToday}',
            'Active users today: ${stats.activeUsersToday}',
          ],
        );

        if (isNarrow) {
          return Column(
            children: [
              revenueCard,
              const SizedBox(height: 12),
              healthCard,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: revenueCard),
            const SizedBox(width: 12),
            Expanded(child: healthCard),
          ],
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.lines,
    required this.accent,
  });

  final String title;
  final List<String> lines;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.18)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 10,
                  backgroundColor: accent.withValues(alpha: 0.16),
                  child: Icon(Icons.insights_outlined, size: 12, color: accent),
                ),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 10),
            for (final line in lines) ...[
              Text(
                line,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _OverviewSkeleton extends StatelessWidget {
  const _OverviewSkeleton({this.height = 120});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
      ),
    );
  }
}

class _AnalyticsPreview extends StatelessWidget {
  const _AnalyticsPreview({required this.analytics});

  final PlatformAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _LeaderboardCard(
          title: 'Top Agencies',
          rows: analytics.topAgencies,
        ),
        const SizedBox(height: 12),
        _LeaderboardCard(
          title: 'Top Rooms',
          rows: analytics.topRooms,
        ),
      ],
    );
  }
}

class _AnalyticsSection extends StatelessWidget {
  const _AnalyticsSection({required this.analytics});

  final PlatformAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TrendCard(
          title: 'User Growth Trend',
          series: analytics.userRegistrationsByMonth,
          accent: AppColors.primary,
        ),
        const SizedBox(height: 12),
        _TrendCard(
          title: 'Agency Growth Trend',
          series: analytics.agencyRegistrationsByMonth,
          accent: AppColors.secondary,
        ),
        const SizedBox(height: 12),
        _TrendCard(
          title: 'Booking Trend',
          series: analytics.bookingsByMonth,
          accent: AppColors.tertiary,
        ),
        const SizedBox(height: 12),
        _DistributionCard(
          title: 'Room Distribution',
          users: analytics.totalUsers,
          agencies: analytics.totalAgencies,
          rooms: analytics.totalRooms,
          bookings: analytics.totalBookings,
        ),
        const SizedBox(height: 12),
        _AnalyticsPreview(analytics: analytics),
      ],
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({
    required this.title,
    required this.series,
    required this.accent,
  });

  final String title;
  final List<MonthlyMetric> series;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: series.isEmpty
                  ? const Center(child: Text('No data yet'))
                  : CustomPaint(
                      painter: _LineChartPainter(series: series, color: accent),
                      child: const SizedBox.expand(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DistributionCard extends StatelessWidget {
  const _DistributionCard({
    required this.title,
    required this.users,
    required this.agencies,
    required this.rooms,
    required this.bookings,
  });

  final String title;
  final int users;
  final int agencies;
  final int rooms;
  final int bookings;

  @override
  Widget build(BuildContext context) {
    final maxValue = math.max(1, math.max(math.max(users, agencies), math.max(rooms, bookings)));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            _BarRow(label: 'Users', value: users, maxValue: maxValue, color: AppColors.primary),
            _BarRow(label: 'Agencies', value: agencies, maxValue: maxValue, color: AppColors.secondary),
            _BarRow(label: 'Rooms', value: rooms, maxValue: maxValue, color: AppColors.tertiary),
            _BarRow(label: 'Bookings', value: bookings, maxValue: maxValue, color: AppColors.primaryContainer),
          ],
        ),
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  const _BarRow({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
  });

  final String label;
  final int value;
  final int maxValue;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ratio = value / maxValue;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Text(value.toString(), style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio.isFinite ? ratio : 0,
              minHeight: 8,
              backgroundColor: AppColors.surfaceContainerLow,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  const _LineChartPainter({
    required this.series,
    required this.color,
  });

  final List<MonthlyMetric> series;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (series.isEmpty) return;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [color.withValues(alpha: 0.18), color.withValues(alpha: 0.02)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final points = <Offset>[];
    final maxValue = series.map((e) => e.value).fold<int>(1, math.max);
    final stepX = series.length == 1 ? size.width : size.width / (series.length - 1);

    for (var i = 0; i < series.length; i++) {
      final x = i * stepX;
      final y = size.height - (series[i].value / maxValue) * (size.height - 20) - 10;
      points.add(Offset(x, y));
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }

    final area = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(area, fillPaint);
    canvas.drawPath(path, paint);

    for (final point in points) {
      canvas.drawCircle(point, 4.5, Paint()..color = Colors.white);
      canvas.drawCircle(point, 3, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.series != series || oldDelegate.color != color;
  }
}

class _RecentActivitySection extends StatelessWidget {
  const _RecentActivitySection({required this.entries});

  final List<AuditLogEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recent Activities', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            if (entries.isEmpty)
              const Text('No recent activity yet.')
            else
              for (final entry in entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.10),
                        child: const Icon(Icons.bolt_outlined, size: 18, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${entry.agencyName ?? 'Agency'} • ${entry.actorName ?? 'System'}',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              entry.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(entry.createdAt),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.color,
    this.textColor,
  });

  final String label;
  final Color color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor ?? Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LeaderboardCard extends StatelessWidget {
  const _LeaderboardCard({
    required this.title,
    required this.rows,
  });

  final String title;
  final List<LeaderboardRow> rows;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            if (rows.isEmpty)
              const Text('No data yet')
            else
              for (final row in rows)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(child: Text(row.label, maxLines: 1, overflow: TextOverflow.ellipsis)),
                      Text(row.value.toString(), style: const TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _AgenciesTab extends ConsumerStatefulWidget {
  const _AgenciesTab({
    required this.searchController,
    required this.statusFilter,
    required this.onStatusChanged,
  });

  final TextEditingController searchController;
  final String statusFilter;
  final ValueChanged<String> onStatusChanged;

  @override
  ConsumerState<_AgenciesTab> createState() => _AgenciesTabState();
}

class _AgenciesTabState extends ConsumerState<_AgenciesTab> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final agenciesValue = ref.watch(agenciesProvider);
    final query = widget.searchController.text.toLowerCase().trim();

    return agenciesValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: ErrorCard(
          message: 'Unable to load agencies. Please try again.',
          onRetry: () => ref.invalidate(agenciesProvider),
        ),
      ),
      data: (agencies) {
        final filtered = agencies.where((agency) {
          final matchesQuery = query.isEmpty ||
              agency.name.toLowerCase().contains(query) ||
              agency.slug.toLowerCase().contains(query);
          final matchesStatus = widget.statusFilter == 'all' || agency.approvalStatus == widget.statusFilter;
          return matchesQuery && matchesStatus;
        }).toList();
        const pageSize = 8;
        final pageCount = math.max(1, (filtered.length / pageSize).ceil());
        if (_page >= pageCount) _page = pageCount - 1;
        if (_page < 0) _page = 0;
        final pageItems = filtered.skip(_page * pageSize).take(pageSize).toList();

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(agenciesProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SearchField(
                controller: widget.searchController,
                hintText: 'Search agency...',
                onChanged: (_) => setState(() => _page = 0),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _FilterChip(label: 'All', selected: widget.statusFilter == 'all', onTap: () { widget.onStatusChanged('all'); setState(() => _page = 0); }),
                  _FilterChip(label: 'Pending', selected: widget.statusFilter == 'pending', onTap: () { widget.onStatusChanged('pending'); setState(() => _page = 0); }),
                  _FilterChip(label: 'Approved', selected: widget.statusFilter == 'approved', onTap: () { widget.onStatusChanged('approved'); setState(() => _page = 0); }),
                  _FilterChip(label: 'Suspended', selected: widget.statusFilter == 'suspended', onTap: () { widget.onStatusChanged('suspended'); setState(() => _page = 0); }),
                ],
              ),
              const SizedBox(height: 16),
              if (pageItems.isEmpty)
                const EmptyState(
                  title: 'No agency found',
                  message: 'Try another search or filter status.',
                )
              else ...[
                for (final agency in pageItems) ...[
                  _AgencyCard(
                    agency: agency,
                    onTap: () => _showAgencyDetail(context, ref, agency.id),
                  ),
                  const SizedBox(height: 12),
                ],
                if (pageCount > 1)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Page ${_page + 1} of $pageCount'),
                      Row(
                        children: [
                          IconButton(
                            onPressed: _page == 0 ? null : () => setState(() => _page -= 1),
                            icon: const Icon(Icons.chevron_left),
                          ),
                          IconButton(
                            onPressed: _page >= pageCount - 1 ? null : () => setState(() => _page += 1),
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _showAgencyDetail(BuildContext context, WidgetRef ref, String agencyId) async {
    final result = await ref.read(agencyRepositoryProvider).getAgencyDetail(agencyId);
    result.match(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message))),
      (agency) async {
        if (!context.mounted) return;
        await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (sheetContext) => Padding(
            padding: const EdgeInsets.all(16),
            child: _AgencyDetailSheet(agency: agency),
          ),
        );
      },
    );
  }
}

class _AgencyCard extends StatelessWidget {
  const _AgencyCard({
    required this.agency,
    required this.onTap,
  });

  final Agency agency;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.apartment_outlined, color: AppColors.primary),
        ),
        title: Text(agency.name),
        subtitle: Text(
          '${agency.city ?? agency.slug}\nRooms ${agency.roomCount} • Bookings ${agency.bookingCount}',
        ),
        isThreeLine: true,
        trailing: _StatusChip(status: agency.approvalStatus),
      ),
    );
  }
}

class _AgencyDetailSheet extends ConsumerWidget {
  const _AgencyDetailSheet({required this.agency});

  final Agency agency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(agency.name, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          _detailRow('Status', agency.approvalStatus),
          _detailRow('Active', agency.isActive ? 'Yes' : 'No'),
          _detailRow('Rooms', agency.roomCount.toString()),
          _detailRow('Bookings', agency.bookingCount.toString()),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: agency.approvalStatus == 'approved'
                      ? null
                      : () async {
                          await ref.read(agencyRepositoryProvider).approveAgency(agency.id);
                          ref.invalidate(agenciesProvider);
                          ref.invalidate(platformStatsProvider);
                          if (context.mounted) Navigator.pop(context);
                        },
                  child: const Text('Approve'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    await ref.read(agencyRepositoryProvider).rejectAgency(agency.id);
                    ref.invalidate(agenciesProvider);
                    ref.invalidate(platformStatsProvider);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Reject'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonal(
                  onPressed: () async {
                    await ref.read(agencyRepositoryProvider).setAgencyActive(agency.id, false);
                    ref.invalidate(agenciesProvider);
                    ref.invalidate(platformStatsProvider);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Suspend'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: () async {
                    await ref.read(agencyRepositoryProvider).setAgencyActive(agency.id, true);
                    ref.invalidate(agenciesProvider);
                    ref.invalidate(platformStatsProvider);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Reactivate'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Flexible(child: Text(value, textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}

class _UsersTab extends ConsumerStatefulWidget {
  const _UsersTab({
    required this.searchController,
    required this.roleFilter,
    required this.statusFilter,
    required this.onRoleChanged,
    required this.onStatusChanged,
  });

  final TextEditingController searchController;
  final String roleFilter;
  final String statusFilter;
  final ValueChanged<String> onRoleChanged;
  final ValueChanged<String> onStatusChanged;

  @override
  ConsumerState<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends ConsumerState<_UsersTab> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final usersValue = ref.watch(platformUsersProvider);
    final query = widget.searchController.text.toLowerCase().trim();

    return usersValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: ErrorCard(
          message: 'Unable to load users. Please try again.',
          onRetry: () => ref.invalidate(platformUsersProvider),
        ),
      ),
      data: (users) {
        final filtered = users.where((user) {
          final matchesQuery = query.isEmpty ||
              user.fullName.toLowerCase().contains(query) ||
              user.email.toLowerCase().contains(query) ||
              (user.agencyName ?? '').toLowerCase().contains(query);
          final matchesRole = widget.roleFilter == 'all' || user.role.dbValue == widget.roleFilter;
          final matchesStatus = widget.statusFilter == 'all' ||
              (widget.statusFilter == 'active' && user.isActive) ||
              (widget.statusFilter == 'suspended' && !user.isActive);
          return matchesQuery && matchesRole && matchesStatus;
        }).toList();
        const pageSize = 8;
        final pageCount = math.max(1, (filtered.length / pageSize).ceil());
        if (_page >= pageCount) _page = pageCount - 1;
        if (_page < 0) _page = 0;
        final pageItems = filtered.skip(_page * pageSize).take(pageSize).toList();

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(platformUsersProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SearchField(
                controller: widget.searchController,
                hintText: 'Search user...',
                onChanged: (_) => setState(() => _page = 0),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _FilterChip(label: 'All', selected: widget.roleFilter == 'all', onTap: () { widget.onRoleChanged('all'); setState(() => _page = 0); }),
                  _FilterChip(label: 'Admin', selected: widget.roleFilter == 'ADMIN', onTap: () { widget.onRoleChanged('ADMIN'); setState(() => _page = 0); }),
                  _FilterChip(label: 'User', selected: widget.roleFilter == 'user', onTap: () { widget.onRoleChanged('user'); setState(() => _page = 0); }),
                  _FilterChip(label: 'Active', selected: widget.statusFilter == 'active', onTap: () { widget.onStatusChanged('active'); setState(() => _page = 0); }),
                  _FilterChip(label: 'Suspended', selected: widget.statusFilter == 'suspended', onTap: () { widget.onStatusChanged('suspended'); setState(() => _page = 0); }),
                ],
              ),
              const SizedBox(height: 16),
              if (pageItems.isEmpty)
                const EmptyState(
                  title: 'No user found',
                  message: 'Try another search or filter.',
                )
              else ...[
                for (final user in pageItems) ...[
                  _UserTile(
                    user: user,
                    onTap: () => _showUserDetail(context, ref, user.id),
                  ),
                  const SizedBox(height: 12),
                ],
                if (pageCount > 1)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Page ${_page + 1} of $pageCount'),
                      Row(
                        children: [
                          IconButton(
                            onPressed: _page == 0 ? null : () => setState(() => _page -= 1),
                            icon: const Icon(Icons.chevron_left),
                          ),
                          IconButton(
                            onPressed: _page >= pageCount - 1 ? null : () => setState(() => _page += 1),
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _showUserDetail(BuildContext context, WidgetRef ref, String userId) async {
    final result = await ref.read(agencyRepositoryProvider).getUserDetail(userId);
    result.match(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message))),
      (user) async {
        if (!context.mounted) return;
        await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (sheetContext) => Padding(
            padding: const EdgeInsets.all(16),
            child: _UserDetailSheet(user: user),
          ),
        );
      },
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({
    required this.user,
    required this.onTap,
  });

  final PlatformUser user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppColors.surfaceContainerLow,
          child: Text(user.fullName.characters.first.toUpperCase()),
        ),
        title: Text(user.fullName),
        subtitle: Text(user.email),
        trailing: _StatusChip(status: user.isActive ? 'active' : 'suspended'),
      ),
    );
  }
}

class _UserDetailSheet extends ConsumerWidget {
  const _UserDetailSheet({required this.user});

  final PlatformUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSuperAdmin = user.role == UserRole.superAdmin;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(user.fullName, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          _detailRow('Email', user.email),
          _detailRow('Role', user.role.dbValue),
          _detailRow('Status', user.isActive ? 'Active' : 'Suspended'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonal(
                  onPressed: isSuperAdmin
                      ? null
                      : () async {
                          await ref.read(agencyRepositoryProvider).setUserActive(user.id, false);
                          ref.invalidate(platformUsersProvider);
                          ref.invalidate(auditLogsProvider);
                          if (context.mounted) Navigator.pop(context);
                        },
                  child: const Text('Suspend'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: isSuperAdmin
                      ? null
                      : () async {
                          await ref.read(agencyRepositoryProvider).setUserActive(user.id, true);
                          ref.invalidate(platformUsersProvider);
                          ref.invalidate(auditLogsProvider);
                          if (context.mounted) Navigator.pop(context);
                        },
                  child: const Text('Activate'),
                ),
              ),
            ],
          ),
          if (isSuperAdmin)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text('Super admin account cannot be disabled from this screen.'),
            ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Flexible(child: Text(value, textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}

class _AuditLogsTab extends ConsumerStatefulWidget {
  const _AuditLogsTab({
    required this.searchController,
    required this.filter,
    required this.onFilterChanged,
  });

  final TextEditingController searchController;
  final String filter;
  final ValueChanged<String> onFilterChanged;

  @override
  ConsumerState<_AuditLogsTab> createState() => _AuditLogsTabState();
}

class _AuditLogsTabState extends ConsumerState<_AuditLogsTab> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final logsValue = ref.watch(auditLogsProvider);
    final query = widget.searchController.text.toLowerCase().trim();

    return logsValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: ErrorCard(
          message: 'Unable to load audit logs. Please try again.',
          onRetry: () => ref.invalidate(auditLogsProvider),
        ),
      ),
      data: (logs) {
        const pageSize = 10;
        final filtered = logs.where((log) {
          final matchesQuery = query.isEmpty ||
              log.action.toLowerCase().contains(query) ||
              log.entityType.toLowerCase().contains(query) ||
              (log.entityName ?? '').toLowerCase().contains(query) ||
              (log.actorName ?? '').toLowerCase().contains(query) ||
              (log.agencyName ?? '').toLowerCase().contains(query);
          final matchesFilter = widget.filter == 'all' || log.entityType.toLowerCase() == widget.filter;
          return matchesQuery && matchesFilter;
        }).toList();

        final pageCount = math.max(1, (filtered.length / pageSize).ceil());
        if (_page >= pageCount) _page = pageCount - 1;
        if (_page < 0) _page = 0;
        final safePage = _page;
        final pageItems = filtered.skip(safePage * pageSize).take(pageSize).toList();

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(auditLogsProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SearchField(
                controller: widget.searchController,
                hintText: 'Search audit logs...',
                onChanged: (_) => setState(() => _page = 0),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _FilterChip(label: 'All', selected: widget.filter == 'all', onTap: () { widget.onFilterChanged('all'); setState(() => _page = 0); }),
                  _FilterChip(label: 'Agency', selected: widget.filter == 'agency', onTap: () { widget.onFilterChanged('agency'); setState(() => _page = 0); }),
                  _FilterChip(label: 'User', selected: widget.filter == 'user', onTap: () { widget.onFilterChanged('user'); setState(() => _page = 0); }),
                  _FilterChip(label: 'Room', selected: widget.filter == 'room', onTap: () { widget.onFilterChanged('room'); setState(() => _page = 0); }),
                  _FilterChip(label: 'Booking', selected: widget.filter == 'booking', onTap: () { widget.onFilterChanged('booking'); setState(() => _page = 0); }),
                ],
              ),
              const SizedBox(height: 16),
              if (filtered.isEmpty)
                const EmptyState(
                  title: 'No audit logs found',
                  message: 'Try another search or filter.',
                )
              else ...[
                for (final log in pageItems) ...[
                  _AuditLogTile(log: log),
                  const SizedBox(height: 12),
                ],
                if (pageCount > 1)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Page ${safePage + 1} of $pageCount'),
                      Row(
                        children: [
                          IconButton(
                            onPressed: safePage == 0 ? null : () => setState(() => _page -= 1),
                            icon: const Icon(Icons.chevron_left),
                          ),
                          IconButton(
                            onPressed: safePage >= pageCount - 1 ? null : () => setState(() => _page += 1),
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _AuditLogTile extends StatelessWidget {
  const _AuditLogTile({required this.log});

  final AuditLogEntry log;

  @override
  Widget build(BuildContext context) {
    final sentence = _auditSentence(log);
    final actionLabel = _humanActionLabel(log.action);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => showDialog<void>(
          context: context,
          builder: (dialogContext) => Dialog(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      actionLabel,
                      style: Theme.of(dialogContext).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    _dialogDetail('Actor', log.actorName ?? '-'),
                    _dialogDetail('Role', log.actorRole ?? '-'),
                    _dialogDetail('Agency', log.agencyName ?? '-'),
                    _dialogDetail('Target', log.entityName ?? '-'),
                    _dialogDetail('Timestamp', DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(log.createdAt)),
                    const SizedBox(height: 16),
                    Text(sentence, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
        ),
        child: ListTile(
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.history_outlined, color: AppColors.primary),
          ),
          title: Text(
            sentence,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '[${log.agencyName ?? 'Platform'}] ${log.actorName ?? 'System'} • $actionLabel\n${DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(log.createdAt)}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          isThreeLine: true,
        ),
      ),
    );
  }
}

Widget _dialogDetail(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(width: 12),
        Flexible(child: Text(value, textAlign: TextAlign.end)),
      ],
    ),
  );
}

String _auditSentence(AuditLogEntry log) {
  final agency = log.agencyName ?? 'Agency';
  final actor = log.actorName ?? 'System';
  final target = log.entityName ?? log.entityType;

  return switch (log.action) {
    'agency_created' => '$agency membuat agency baru',
    'agency_approved' => '$agency disetujui',
    'agency_rejected' => '$agency ditolak',
    'agency_suspended' => '$agency disuspensi',
    'user_registered' => '$actor mendaftar sebagai user baru',
    'user_deleted' => '$actor dihapus',
    'room_created' => '$agency menambahkan ruang $target',
    'room_updated' => '$agency memperbarui ruang $target',
    'room_deleted' => '$agency menghapus ruang $target',
    'room_restored' => '$agency memulihkan ruang $target',
    'booking_created' => '$agency menerima booking ruang $target',
    'booking_approved' => '$agency menyetujui booking ruang $target',
    'booking_rejected' => '$agency menolak booking ruang $target',
    'booking_cancelled' => '$agency membatalkan booking ruang $target',
    'booking_completed' => '$agency menyelesaikan booking ruang $target',
    _ => '${log.agencyName ?? 'Platform'} melakukan ${log.action.replaceAll('_', ' ')} pada $target',
  };
}

String _humanActionLabel(String action) {
  return switch (action) {
    'agency_created' => 'Membuat agency',
    'agency_approved' => 'Menyetujui agency',
    'agency_rejected' => 'Menolak agency',
    'agency_suspended' => 'Mensuspensi agency',
    'user_registered' => 'User baru terdaftar',
    'user_deleted' => 'Menghapus user',
    'room_created' => 'Menambahkan ruang',
    'room_updated' => 'Memperbarui ruang',
    'room_deleted' => 'Menghapus ruang',
    'room_restored' => 'Memulihkan ruang',
    'booking_created' => 'Membuat booking',
    'booking_approved' => 'Menyetujui booking',
    'booking_rejected' => 'Menolak booking',
    'booking_cancelled' => 'Membatalkan booking',
    'booking_completed' => 'Menyelesaikan booking',
    _ => action.replaceAll('_', ' '),
  };
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.hintText,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: const Icon(Icons.search),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      label: Text(label),
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(color: selected ? Colors.white : AppColors.onSurface),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'approved' || 'active' || 'super_admin' => AppColors.secondary,
      'pending' || 'admin' => AppColors.primary,
      'rejected' || 'suspended' => AppColors.error,
      _ => AppColors.onSurfaceVariant,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
