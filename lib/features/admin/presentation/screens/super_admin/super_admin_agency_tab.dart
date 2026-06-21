import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/empty_state.dart';
import '../../../../../core/widgets/error_card.dart';
import '../../../domain/entities/agency.dart';
import '../../providers/super_admin_providers.dart';
import '../../widgets/super_admin/super_admin_list_controls.dart';
import 'super_admin_agency_detail_screen.dart';

class SuperAdminAgencyTab extends ConsumerStatefulWidget {
  const SuperAdminAgencyTab({super.key});

  @override
  ConsumerState<SuperAdminAgencyTab> createState() =>
      _SuperAdminAgencyTabState();
}

class _SuperAdminAgencyTabState extends ConsumerState<SuperAdminAgencyTab> {
  String _search = '';
  String? _filter;
  SuperAdminSortOption _sort = SuperAdminSortOption.newest;
  int _page = 0;
  static const _pageSize = 8;

  @override
  Widget build(BuildContext context) {
    final agenciesAsync = ref.watch(agenciesProvider);

    return agenciesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: ErrorCard(
          message: error.toString(),
          onRetry: () => ref.invalidate(agenciesProvider),
        ),
      ),
      data: (agencies) {
        final filtered = _applyFilters(agencies);
        final paged = paginateList(filtered, _page, _pageSize);
        final totalPages = totalPagesFor(filtered.length, _pageSize);

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(agenciesProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SuperAdminListControls(
                searchHint: 'Cari agency...',
                onSearchChanged: (value) => setState(() {
                  _search = value.toLowerCase();
                  _page = 0;
                }),
                filterOptions: const [
                  'Approved',
                  'Suspended',
                  'Pending',
                  'Rejected',
                ],
                selectedFilter: _filter,
                onFilterChanged: (value) => setState(() {
                  _filter = value;
                  _page = 0;
                }),
                selectedSort: _sort,
                onSortChanged: (value) => setState(() => _sort = value),
              ),
              const SizedBox(height: 16),
              if (filtered.isEmpty)
                const EmptyState(
                  title: 'Agency tidak ditemukan',
                  message: 'Coba ubah kata kunci atau filter pencarian.',
                )
              else ...[
                if (_filter == null) ...[
                  _PendingRegistrationsSection(
                    agencies: agencies
                        .where((agency) => agency.approvalStatus == 'pending')
                        .toList(),
                    onOpen: (agency) => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => SuperAdminAgencyDetailScreen(
                          agencyId: agency.id,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                for (final agency in paged) ...[
                  _AgencyListTile(
                    agency: agency,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            SuperAdminAgencyDetailScreen(agencyId: agency.id),
                      ),
                    ),
                    onEdit: () => _editAgency(context, agency),
                    onDelete: () => _deleteAgency(context, agency),
                  ),
                  const SizedBox(height: 12),
                ],
                SuperAdminPaginationBar(
                  currentPage: _page,
                  totalPages: totalPages,
                  onPageChanged: (page) => setState(() => _page = page),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  List<Agency> _applyFilters(List<Agency> agencies) {
    var result = agencies.where((agency) {
      final query = _search.trim();
      if (query.isEmpty) return true;
      return agency.name.toLowerCase().contains(query) ||
          (agency.email?.toLowerCase().contains(query) ?? false) ||
          (agency.city?.toLowerCase().contains(query) ?? false);
    }).toList();

    if (_filter != null) {
      result = result.where((agency) {
        return switch (_filter) {
          'Approved' => agency.approvalStatus == 'approved' && agency.isActive,
          'Suspended' =>
            agency.approvalStatus == 'suspended' || !agency.isActive,
          'Pending' => agency.approvalStatus == 'pending',
          'Rejected' => agency.approvalStatus == 'rejected',
          _ => true,
        };
      }).toList();
    }

    result.sort((a, b) {
      return switch (_sort) {
        SuperAdminSortOption.newest =>
          (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
              .compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)),
        SuperAdminSortOption.oldest =>
          (a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
              .compareTo(b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)),
        SuperAdminSortOption.nameAsc => a.name.compareTo(b.name),
        SuperAdminSortOption.nameDesc => b.name.compareTo(a.name),
      };
    });

    return result;
  }

  Future<void> _editAgency(BuildContext context, Agency agency) async {
    final nameController = TextEditingController(text: agency.name);
    final emailController = TextEditingController(text: agency.email ?? '');
    final phoneController = TextEditingController(text: agency.phone ?? '');
    final addressController = TextEditingController(text: agency.address ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Agency'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nama')),
              TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email')),
              TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Telepon')),
              TextField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: 'Alamat')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Simpan')),
        ],
      ),
    );

    if (saved == true) {
      await ref.read(superAdminRepositoryProvider).updateAgency(agency.id, {
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'phone': phoneController.text.trim(),
        'address': addressController.text.trim(),
      });
      invalidateSuperAdminData(ref);
    }
  }

  Future<void> _deleteAgency(BuildContext context, Agency agency) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nonaktifkan Agency?'),
        content: Text('Agency "${agency.name}" akan dinonaktifkan.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Nonaktifkan')),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(superAdminRepositoryProvider)
          .setAgencyActive(agency.id, false);
      invalidateSuperAdminData(ref);
    }
  }
}

class _AgencyListTile extends ConsumerWidget {
  const _AgencyListTile({
    required this.agency,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final Agency agency;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = MaterialLocalizations.of(context);
    final statusColor = switch (agency.approvalStatus) {
      'approved' when agency.isActive => AppColors.secondary,
      'approved' => AppColors.onSurfaceVariant,
      'pending' => AppColors.primary,
      'rejected' => AppColors.error,
      'suspended' => AppColors.error,
      _ => AppColors.onSurfaceVariant,
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    agency.name,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                SuperAdminStatusChip(
                    label: agency.statusLabel, color: statusColor),
              ],
            ),
            const SizedBox(height: 8),
            _InfoLine(
                icon: Icons.person_outline, text: agency.ownerName ?? '-'),
            _InfoLine(icon: Icons.email_outlined, text: agency.email ?? '-'),
            _InfoLine(icon: Icons.phone_outlined, text: agency.phone ?? '-'),
            _InfoLine(
                icon: Icons.location_on_outlined,
                text: agency.address ?? agency.city ?? '-'),
            _InfoLine(
              icon: Icons.calendar_today_outlined,
              text: agency.createdAt == null
                  ? '-'
                  : dateFormat.formatMediumDate(agency.createdAt!),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _MetricBadge(label: '${agency.roomCount} Room'),
                const SizedBox(width: 8),
                _MetricBadge(label: '${agency.bookingCount} Booking'),
                const Spacer(),
                _AgencyActionMenu(agency: agency),
                IconButton(
                    onPressed: onEdit, icon: const Icon(Icons.edit_outlined)),
                IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.block_outlined)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingRegistrationsSection extends StatelessWidget {
  const _PendingRegistrationsSection({
    required this.agencies,
    required this.onOpen,
  });

  final List<Agency> agencies;
  final ValueChanged<Agency> onOpen;

  @override
  Widget build(BuildContext context) {
    if (agencies.isEmpty) return const SizedBox.shrink();
    final dateFormat = MaterialLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pending Registrations',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          for (final agency in agencies)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.pending_actions_outlined),
              title: Text(agency.name),
              subtitle: Text(
                '${agency.ownerName ?? '-'} • ${agency.ownerEmail ?? agency.email ?? '-'}\n'
                '${agency.phone ?? agency.ownerPhone ?? '-'} • ${agency.address ?? '-'}',
              ),
              isThreeLine: true,
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const SuperAdminStatusChip(
                    label: 'Pending',
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    agency.createdAt == null
                        ? '-'
                        : dateFormat.formatShortDate(agency.createdAt!),
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
              onTap: () => onOpen(agency),
            ),
        ],
      ),
    );
  }
}

class _AgencyActionMenu extends ConsumerWidget {
  const _AgencyActionMenu({required this.agency});

  final Agency agency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      tooltip: 'Aksi agency',
      icon: const Icon(Icons.more_vert),
      onSelected: (value) async {
        final repository = ref.read(superAdminRepositoryProvider);
        if (value == 'approve') {
          await repository.approveAgency(agency.id);
        } else if (value == 'reject') {
          await repository.rejectAgency(agency.id);
        } else if (value == 'suspend') {
          await repository.suspendAgency(agency.id);
        } else if (value == 'reactivate') {
          await repository.reactivateAgency(agency.id);
        }
        invalidateSuperAdminData(ref);
      },
      itemBuilder: (context) => [
        if (agency.approvalStatus != 'approved' || !agency.isActive)
          const PopupMenuItem(value: 'approve', child: Text('Approve')),
        if (agency.approvalStatus == 'pending')
          const PopupMenuItem(value: 'reject', child: Text('Reject')),
        if (agency.approvalStatus == 'approved' && agency.isActive)
          const PopupMenuItem(value: 'suspend', child: Text('Suspend')),
        if (agency.approvalStatus == 'suspended' || !agency.isActive)
          const PopupMenuItem(value: 'reactivate', child: Text('Reactivate')),
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  style: const TextStyle(color: AppColors.onSurfaceVariant))),
        ],
      ),
    );
  }
}

class _MetricBadge extends StatelessWidget {
  const _MetricBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
