import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_card.dart';
import '../../../../shared/domain/entities/app_user.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/agency.dart';
import '../../domain/entities/platform_stats.dart';
import '../../domain/entities/platform_user.dart';
import '../providers/agency_providers.dart';

class SuperAdminDashboardScreen extends ConsumerWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: AppScaffold(
        title: 'Super Admin',
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(platformStatsProvider);
              ref.invalidate(agenciesProvider);
              ref.invalidate(platformUsersProvider);
            },
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).logout();
              if (context.mounted) context.go(AppRoutes.login);
            },
            icon: const Icon(Icons.logout),
          ),
        ],
        body: Column(
          children: [
            const Material(
              color: AppColors.surfaceContainerLowest,
              child: TabBar(
                tabs: [
                  Tab(icon: Icon(Icons.dashboard_outlined), text: 'Overview'),
                  Tab(icon: Icon(Icons.apartment_outlined), text: 'Agencies'),
                  Tab(icon: Icon(Icons.people_outline), text: 'Users'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _OverviewTab(),
                  _AgenciesTab(),
                  _UsersTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsValue = ref.watch(platformStatsProvider);

    return statsValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: ErrorCard(
          message: error.toString(),
          onRetry: () => ref.invalidate(platformStatsProvider),
        ),
      ),
      data: (stats) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(platformStatsProvider),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _HeroPanel(stats: stats),
            const SizedBox(height: 16),
            _MetricGrid(stats: stats),
            const SizedBox(height: 16),
            const _OpsChecklist(),
          ],
        ),
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.stats});

  final PlatformStats stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.verified_user_outlined, color: Colors.white, size: 32),
          const SizedBox(height: 12),
          Text(
            'Platform Control Center',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '${stats.pendingAgencies} agency menunggu approval. '
            '${stats.activeAgencies} agency aktif di platform.',
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.stats});

  final PlatformStats stats;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _Metric('Agencies', stats.totalAgencies, Icons.apartment_outlined),
      _Metric('Pending', stats.pendingAgencies, Icons.hourglass_top_outlined),
      _Metric('Active', stats.activeAgencies, Icons.check_circle_outline),
      _Metric('Users', stats.totalUsers, Icons.people_outline),
      _Metric('Rooms', stats.totalRooms, Icons.meeting_room_outlined),
      _Metric('Bookings', stats.totalBookings, Icons.fact_check_outlined),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: metrics.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.35,
      ),
      itemBuilder: (_, index) => _MetricCard(metric: metrics[index]),
    );
  }
}

class _Metric {
  const _Metric(this.label, this.value, this.icon);

  final String label;
  final int value;
  final IconData icon;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final _Metric metric;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(metric.icon, color: AppColors.primary),
            const Spacer(),
            Text(
              '${metric.value}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            Text(metric.label, style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
      ),
    );
  }
}

class _OpsChecklist extends StatelessWidget {
  const _OpsChecklist();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Super admin scope',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            SizedBox(height: 12),
            _ChecklistRow(text: 'Approve atau reject agency baru'),
            _ChecklistRow(text: 'Aktifkan atau nonaktifkan agency'),
            _ChecklistRow(text: 'Pantau user, room, dan booking lintas platform'),
            _ChecklistRow(text: 'Akses penuh tetap diamankan oleh RLS super_admin'),
          ],
        ),
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: AppColors.secondary),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _AgenciesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agenciesValue = ref.watch(agenciesProvider);

    return agenciesValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: ErrorCard(
          message: error.toString(),
          onRetry: () => ref.invalidate(agenciesProvider),
        ),
      ),
      data: (agencies) {
        if (agencies.isEmpty) {
          return const EmptyState(
            title: 'Belum ada agency',
            message:
                'Agency admin yang register dari aplikasi akan muncul di sini.',
          );
        }

        final pending = agencies
            .where((agency) => agency.approvalStatus == 'pending')
            .toList();
        final reviewed = agencies
            .where((agency) => agency.approvalStatus != 'pending')
            .toList();

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(agenciesProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SectionHeader(
                title: 'Pending approval',
                count: pending.length,
              ),
              const SizedBox(height: 8),
              if (pending.isEmpty)
                const _InlineEmpty(text: 'Tidak ada agency yang menunggu.')
              else
                ...pending.map((agency) => _AgencyCard(agency: agency)),
              const SizedBox(height: 20),
              _SectionHeader(title: 'Reviewed agencies', count: reviewed.length),
              const SizedBox(height: 8),
              if (reviewed.isEmpty)
                const _InlineEmpty(text: 'Belum ada agency yang direview.')
              else
                ...reviewed.map((agency) => _AgencyCard(agency: agency)),
            ],
          ),
        );
      },
    );
  }
}

class _AgencyCard extends ConsumerWidget {
  const _AgencyCard({required this.agency});

  final Agency agency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.apartment_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          agency.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          agency.city?.isNotEmpty == true
                              ? agency.city!
                              : agency.slug,
                          style: const TextStyle(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusChip(status: agency.approvalStatus),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    agency.isActive
                        ? Icons.toggle_on_outlined
                        : Icons.toggle_off_outlined,
                    color: agency.isActive
                        ? AppColors.secondary
                        : AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(agency.isActive ? 'Active' : 'Inactive'),
                  const Spacer(),
                  if (agency.approvalStatus != 'approved')
                    TextButton.icon(
                      onPressed: () async {
                        await ref
                            .read(agencyRepositoryProvider)
                            .approveAgency(agency.id);
                        ref.invalidate(agenciesProvider);
                        ref.invalidate(platformStatsProvider);
                      },
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Approve'),
                    ),
                  if (agency.approvalStatus != 'rejected')
                    TextButton.icon(
                      onPressed: () async {
                        await ref
                            .read(agencyRepositoryProvider)
                            .rejectAgency(agency.id);
                        ref.invalidate(agenciesProvider);
                        ref.invalidate(platformStatsProvider);
                      },
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Reject'),
                    ),
                  Switch(
                    value: agency.isActive,
                    onChanged: agency.approvalStatus == 'approved'
                        ? (value) async {
                            await ref
                                .read(agencyRepositoryProvider)
                                .setAgencyActive(agency.id, value);
                            ref.invalidate(agenciesProvider);
                            ref.invalidate(platformStatsProvider);
                          }
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UsersTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersValue = ref.watch(platformUsersProvider);

    return usersValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: ErrorCard(
          message: error.toString(),
          onRetry: () => ref.invalidate(platformUsersProvider),
        ),
      ),
      data: (users) {
        if (users.isEmpty) {
          return const EmptyState(title: 'Belum ada user');
        }

        final grouped = <UserRole, List<PlatformUser>>{
          UserRole.superAdmin: [],
          UserRole.admin: [],
          UserRole.user: [],
        };
        for (final user in users) {
          grouped[user.role]?.add(user);
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(platformUsersProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final entry in grouped.entries) ...[
                _SectionHeader(
                  title: _roleLabel(entry.key),
                  count: entry.value.length,
                ),
                const SizedBox(height: 8),
                if (entry.value.isEmpty)
                  const _InlineEmpty(text: 'Tidak ada user pada role ini.')
                else
                  ...entry.value.map((user) => _UserTile(user: user)),
                const SizedBox(height: 16),
              ],
            ],
          ),
        );
      },
    );
  }

  String _roleLabel(UserRole role) {
    return switch (role) {
      UserRole.superAdmin => 'Super Admin',
      UserRole.admin => 'Agency Admin',
      UserRole.user => 'Users',
    };
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({required this.user});

  final PlatformUser user;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.surfaceContainerLow,
          child: Text(user.fullName.characters.first.toUpperCase()),
        ),
        title: Text(user.fullName),
        subtitle: Text(user.email),
        trailing: _StatusChip(status: user.role.dbValue),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(width: 8),
        Chip(label: Text('$count')),
      ],
    );
  }
}

class _InlineEmpty extends StatelessWidget {
  const _InlineEmpty({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(text, style: const TextStyle(color: AppColors.onSurfaceVariant)),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'approved' || 'super_admin' => AppColors.secondary,
      'pending' || 'admin' => AppColors.primary,
      'rejected' => AppColors.error,
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
