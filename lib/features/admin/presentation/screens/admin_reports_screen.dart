import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../core/constants/app_routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_scaffold.dart';
import '../../../../../core/widgets/error_card.dart';
import '../../../../../shared/presentation/widgets/admin_nav_bar.dart';
import '../providers/admin_overview_providers.dart';

class AdminReportsScreen extends ConsumerWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsValue = ref.watch(adminRoomReportsProvider);
    final money = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return AppScaffold(
      title: 'Reports',
      actions: [
        IconButton(
          onPressed: () => context.push(AppRoutes.profile),
          icon: const Icon(Icons.person_outline),
        ),
      ],
      body: reportsValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(16),
          child: ErrorCard(
            message: error.toString(),
            onRetry: () => ref.invalidate(adminRoomReportsProvider),
          ),
        ),
        data: (reports) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SummaryCard(
              title: 'Total Rooms',
              value: reports.totalRooms.toString(),
              color: AppColors.primary,
            ),
            _SummaryCard(
              title: 'Active Rooms',
              value: reports.activeRooms.toString(),
              color: AppColors.secondary,
            ),
            _SummaryCard(
              title: 'Need Approval',
              value: reports.requiresApproval.toString(),
              color: AppColors.tertiary,
            ),
            _SummaryCard(
              title: 'Total Capacity',
              value: reports.totalCapacity.toString(),
              color: AppColors.primaryContainer,
            ),
            _SummaryCard(
              title: 'Avg Rating',
              value: reports.averageRating.toStringAsFixed(1),
              color: AppColors.secondary,
            ),
            _SummaryCard(
              title: 'Price Range',
              value: '${money.format(reports.hourlyFloor)} - ${money.format(reports.hourlyCeiling)}',
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Laporan ini otomatis diambil dari inventory ruangan. Saat booking dan payment sudah aktif, halaman ini bisa diperluas ke omzet, okupansi, dan funnel booking.',
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AdminNavBar(currentPath: AppRoutes.adminReports),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.analytics_outlined, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: color,
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
