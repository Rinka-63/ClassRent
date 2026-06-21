import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/error_card.dart';
import '../../../domain/entities/platform_stats.dart';
import '../../providers/super_admin_providers.dart';
import '../../widgets/super_admin/super_admin_charts.dart';
import '../../widgets/super_admin/super_admin_list_controls.dart';
import '../../widgets/super_admin/super_admin_stat_card.dart';

class SuperAdminHomeTab extends ConsumerWidget {
  const SuperAdminHomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(platformStatsProvider);
    final analyticsAsync = ref.watch(platformAnalyticsProvider);

    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: ErrorCard(
          message: error.toString(),
          onRetry: () => ref.invalidate(platformStatsProvider),
        ),
      ),
      data: (stats) => RefreshIndicator(
        onRefresh: () async => invalidateSuperAdminData(ref),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _HeroBanner(stats: stats),
            const SizedBox(height: 16),
            _StatsSection(stats: stats),
            const SizedBox(height: 20),
            analyticsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (_, __) => const SizedBox.shrink(),
              data: (analytics) => SuperAdminChartSection(analytics: analytics),
            ),
            const SizedBox(height: 20),
            _AlertCardsSection(stats: stats),
            const SizedBox(height: 20),
            const _RecentActivitySection(),
            const SizedBox(height: 20),
            const _QuickActionsSection(),
          ],
        ),
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.stats});

  final PlatformStats stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Platform Control Center',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Developer & System Administrator — pantau ${stats.totalAgencies} agency, '
            '${stats.totalUsers} user, dan ${stats.totalBookings} booking.',
            style: const TextStyle(color: Colors.white70, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  const _StatsSection({required this.stats});

  final PlatformStats stats;

  @override
  Widget build(BuildContext context) {
    final currency =
        NumberFormat.compactCurrency(locale: 'id_ID', symbol: 'Rp');

    return SuperAdminStatsGrid(
      children: [
        SuperAdminStatCard(
          label: 'Total Agency',
          value: '${stats.totalAgencies}',
          icon: Icons.apartment_outlined,
        ),
        SuperAdminStatCard(
          label: 'Pending Approval',
          value: '${stats.pendingAgencies}',
          icon: Icons.pending_actions_outlined,
          accent: AppColors.tertiary,
        ),
        SuperAdminStatCard(
          label: 'Approved Agency',
          value: '${stats.approvedAgencies}',
          icon: Icons.verified_outlined,
          accent: AppColors.secondary,
        ),
        SuperAdminStatCard(
          label: 'Suspended Agency',
          value: '${stats.suspendedAgencies}',
          icon: Icons.block_outlined,
          accent: AppColors.error,
        ),
        SuperAdminStatCard(
          label: 'Total User',
          value: '${stats.totalUsers}',
          icon: Icons.people_outline,
          accent: AppColors.secondary,
        ),
        SuperAdminStatCard(
          label: 'Active User',
          value: '${stats.activeUsers}',
          icon: Icons.person_outline,
          accent: AppColors.secondary,
        ),
        SuperAdminStatCard(
          label: 'Pending User',
          value: '${stats.pendingUsers}',
          icon: Icons.person_add_alt_1_outlined,
          accent: AppColors.tertiary,
        ),
        SuperAdminStatCard(
          label: 'Suspended User',
          value: '${stats.suspendedUsers}',
          icon: Icons.person_off_outlined,
          accent: AppColors.error,
        ),
        SuperAdminStatCard(
          label: 'Total Payment',
          value: '${stats.totalPayments}',
          icon: Icons.payments_outlined,
        ),
        SuperAdminStatCard(
          label: 'Pending Payment',
          value: '${stats.pendingPayments}',
          icon: Icons.hourglass_top_outlined,
          accent: AppColors.tertiary,
        ),
        SuperAdminStatCard(
          label: 'Completed Payment',
          value: '${stats.completedPayments}',
          icon: Icons.check_circle_outline,
          accent: AppColors.secondary,
        ),
        SuperAdminStatCard(
          label: 'Total Revenue',
          value: currency.format(stats.totalRevenue),
          icon: Icons.trending_up,
          accent: AppColors.secondary,
        ),
      ],
    );
  }
}

class _AlertCardsSection extends StatelessWidget {
  const _AlertCardsSection({required this.stats});

  final PlatformStats stats;

  @override
  Widget build(BuildContext context) {
    final alerts = [
      _AlertItem(
        title: 'Agency Menunggu Approval',
        value: stats.pendingAgencies,
        icon: Icons.apartment_outlined,
        color: AppColors.tertiary,
      ),
      _AlertItem(
        title: 'User Bermasalah',
        value: stats.suspendedUsers,
        icon: Icons.person_off_outlined,
        color: AppColors.error,
      ),
      _AlertItem(
        title: 'Booking Bermasalah',
        value: 0,
        icon: Icons.event_busy_outlined,
        color: AppColors.error,
      ),
      _AlertItem(
        title: 'Payment Pending',
        value: stats.pendingPayments,
        icon: Icons.hourglass_top_outlined,
        color: AppColors.primary,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SuperAdminSectionHeader(title: 'Alert Cards'),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: MediaQuery.sizeOf(context).width > 720 ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.9,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            for (final alert in alerts)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: alert.color.withValues(alpha: 0.35)),
                ),
                child: Row(
                  children: [
                    Icon(alert.icon, color: alert.color),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${alert.value}',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          Text(
                            alert.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _AlertItem {
  const _AlertItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final int value;
  final IconData icon;
  final Color color;
}

class _RecentActivitySection extends ConsumerWidget {
  const _RecentActivitySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(recentUsersProvider);
    final bookingsAsync = ref.watch(recentBookingsProvider);
    final agenciesAsync = ref.watch(recentAgenciesProvider);
    final paymentsAsync = ref.watch(recentPaymentsProvider);
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');
    final currency =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SuperAdminSectionHeader(title: 'Aktivitas Terbaru'),
        const SizedBox(height: 12),
        _ActivityCard(
          title: 'User Terbaru',
          child: usersAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const Text('Gagal memuat user'),
            data: (users) => users.isEmpty
                ? const Text('Belum ada user')
                : Column(
                    children: [
                      for (final user in users)
                        _ActivityRow(
                          icon: Icons.person_outline,
                          title: user.fullName,
                          subtitle: user.email,
                          trailing: dateFormat
                              .format(user.createdAt ?? DateTime.now()),
                        ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 12),
        _ActivityCard(
          title: 'Booking Terbaru',
          child: bookingsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const Text('Gagal memuat booking'),
            data: (bookings) => bookings.isEmpty
                ? const Text('Belum ada booking')
                : Column(
                    children: [
                      for (final booking in bookings)
                        _ActivityRow(
                          icon: Icons.event_note_outlined,
                          title: _nestedName(booking['rooms']) ?? 'Booking',
                          subtitle: booking['status'] as String? ?? '-',
                          trailing: currency.format(
                            (booking['final_price'] as num?)?.toDouble() ?? 0,
                          ),
                        ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 12),
        _ActivityCard(
          title: 'Agency Terbaru',
          child: agenciesAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const Text('Gagal memuat agency'),
            data: (agencies) => agencies.isEmpty
                ? const Text('Belum ada agency')
                : Column(
                    children: [
                      for (final agency in agencies)
                        _ActivityRow(
                          icon: Icons.apartment_outlined,
                          title: agency.name,
                          subtitle: agency.statusLabel,
                          trailing: dateFormat
                              .format(agency.createdAt ?? DateTime.now()),
                        ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 12),
        _ActivityCard(
          title: 'Payment Terbaru',
          child: paymentsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const Text('Gagal memuat payment'),
            data: (payments) => payments.isEmpty
                ? const Text('Belum ada payment')
                : Column(
                    children: [
                      for (final payment in payments)
                        _ActivityRow(
                          icon: Icons.payments_outlined,
                          title: payment.userName ?? payment.userId,
                          subtitle: payment.status,
                          trailing: currency.format(payment.amount),
                        ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  String? _nestedName(dynamic nested) {
    if (nested is Map<String, dynamic>) return nested['name'] as String?;
    if (nested is List && nested.isNotEmpty) {
      return (nested.first as Map<String, dynamic>)['name'] as String?;
    }
    return null;
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(subtitle,
                    style: const TextStyle(
                        color: AppColors.onSurfaceVariant, fontSize: 12)),
              ],
            ),
          ),
          Text(trailing,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _QuickActionsSection extends ConsumerWidget {
  const _QuickActionsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SuperAdminSectionHeader(title: 'Quick Actions'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: () =>
                  ref.read(superAdminTabIndexProvider.notifier).state = 4,
              icon: const Icon(Icons.receipt_long_outlined),
              label: const Text('Lihat Audit Log'),
            ),
          ],
        ),
      ],
    );
  }
}
