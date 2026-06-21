import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/empty_state.dart';
import '../../../../../core/widgets/error_card.dart';
import '../../providers/super_admin_providers.dart';
import '../../widgets/super_admin/super_admin_list_controls.dart';
import '../../widgets/super_admin/super_admin_stat_card.dart';

class SuperAdminAgencyDetailScreen extends ConsumerWidget {
  const SuperAdminAgencyDetailScreen({required this.agencyId, super.key});

  final String agencyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agencyAsync = ref.watch(agencyDetailProvider(agencyId));
    final roomsAsync = ref.watch(agencyRoomsProvider(agencyId));
    final currency =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Agency')),
      body: agencyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(16),
          child: ErrorCard(message: error.toString()),
        ),
        data: (agency) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _InfoCard(
              title: agency.name,
              subtitle: agency.statusLabel,
              rows: [
                _InfoRow('Pemilik', agency.ownerName ?? 'Belum diisi'),
                _InfoRow('Email Pemilik', agency.ownerEmail ?? 'Belum diisi'),
                _InfoRow('Telepon Pemilik', agency.ownerPhone ?? 'Belum diisi'),
                _InfoRow('Email', agency.email ?? 'Belum diisi'),
                _InfoRow('Telepon', agency.phone ?? 'Belum diisi'),
                _InfoRow('Alamat', agency.address ?? agency.city ?? 'Belum diisi'),
                _InfoRow('Deskripsi', agency.description ?? 'Belum diisi'),
                _InfoRow('Logo URL', agency.logoUrl ?? 'Belum diisi'),
                _InfoRow('Slug', agency.slug),
                _InfoRow(
                  'Registrasi',
                  agency.createdAt == null
                      ? 'Belum diisi'
                      : dateFormat.format(agency.createdAt!),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _AgencyDetailActions(
                agencyId: agency.id,
                status: agency.approvalStatus,
                isActive: agency.isActive),
            const SizedBox(height: 16),
            SuperAdminStatsGrid(
              children: [
                SuperAdminStatCard(
                  label: 'Total Room',
                  value: '${agency.roomCount}',
                  icon: Icons.meeting_room_outlined,
                ),
                SuperAdminStatCard(
                  label: 'Total Booking',
                  value: '${agency.bookingCount}',
                  icon: Icons.event_available_outlined,
                  accent: AppColors.secondary,
                ),
                SuperAdminStatCard(
                  label: 'Revenue',
                  value: currency.format(agency.revenue),
                  icon: Icons.payments_outlined,
                  accent: AppColors.tertiary,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Daftar Room',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            roomsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('Gagal memuat room'),
              data: (rooms) => rooms.isEmpty
                  ? const EmptyState(title: 'Belum ada room')
                  : Column(
                      children: [
                        for (final item in rooms)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.meeting_room_outlined),
                            title: Text(item.room.name),
                            subtitle: Text(
                                '${item.room.capacity} orang • ${currency.format(item.room.hourlyRate)}/jam'),
                            trailing: SuperAdminStatusChip(
                              label: item.room.isActive ? 'Active' : 'Inactive',
                              color: item.room.isActive
                                  ? AppColors.secondary
                                  : AppColors.onSurfaceVariant,
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

class _AgencyDetailActions extends ConsumerWidget {
  const _AgencyDetailActions({
    required this.agencyId,
    required this.status,
    required this.isActive,
  });

  final String agencyId;
  final String status;
  final bool isActive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> run(Future<void> Function() action) async {
      await action();
      invalidateSuperAdminData(ref);
      ref.invalidate(agencyDetailProvider(agencyId));
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (status != 'approved' || !isActive)
          FilledButton.icon(
            onPressed: () => run(() async {
              await ref
                  .read(superAdminRepositoryProvider)
                  .approveAgency(agencyId);
            }),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Approve'),
          ),
        if (status == 'pending')
          OutlinedButton.icon(
            onPressed: () => run(() async {
              await ref
                  .read(superAdminRepositoryProvider)
                  .rejectAgency(agencyId);
            }),
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Reject'),
          ),
        if (status == 'approved' && isActive)
          OutlinedButton.icon(
            onPressed: () => run(() async {
              await ref
                  .read(superAdminRepositoryProvider)
                  .suspendAgency(agencyId);
            }),
            icon: const Icon(Icons.block_outlined),
            label: const Text('Suspend'),
          ),
        if (status == 'suspended' || !isActive)
          FilledButton.icon(
            onPressed: () => run(() async {
              await ref
                  .read(superAdminRepositoryProvider)
                  .reactivateAgency(agencyId);
            }),
            icon: const Icon(Icons.restart_alt_outlined),
            label: const Text('Reactivate'),
          ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.subtitle,
    required this.rows,
  });

  final String title;
  final String subtitle;
  final List<_InfoRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
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
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: const TextStyle(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 12),
          for (final row in rows) row,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 90,
              child: Text(label,
                  style: const TextStyle(color: AppColors.onSurfaceVariant))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
