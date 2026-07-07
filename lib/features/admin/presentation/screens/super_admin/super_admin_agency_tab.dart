import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/l10n/app_strings.dart';
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
    final strings = AppStrings.of(context);

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
                searchHint: strings.searchAgencyHint,
                onSearchChanged: (value) => setState(() {
                  _search = value.toLowerCase();
                  _page = 0;
                }),
                filterOptions: [
                  SuperAdminFilterOption(
                    value: 'approved',
                    label: strings.tr('Disetujui', 'Approved'),
                  ),
                  SuperAdminFilterOption(
                    value: 'suspended',
                    label: strings.tr('Disuspen', 'Suspended'),
                  ),
                  SuperAdminFilterOption(
                    value: 'pending',
                    label: strings.tr('Menunggu', 'Pending'),
                  ),
                  SuperAdminFilterOption(
                    value: 'rejected',
                    label: strings.tr('Ditolak', 'Rejected'),
                  ),
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
                EmptyState(
                  title: strings.tr(
                    'Agensi tidak ditemukan',
                    'No agencies found',
                  ),
                  message: strings.tr(
                    'Coba ubah kata kunci atau filter pencarian.',
                    'Try changing the keyword or search filter.',
                  ),
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
          'approved' => agency.approvalStatus == 'approved' && agency.isActive,
          'suspended' =>
            agency.approvalStatus == 'suspended' || !agency.isActive,
          'pending' => agency.approvalStatus == 'pending',
          'rejected' => agency.approvalStatus == 'rejected',
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
}

class _AgencyListTile extends ConsumerWidget {
  const _AgencyListTile({
    required this.agency,
    required this.onTap,
  });

  final Agency agency;
  final VoidCallback onTap;

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
                _MetricBadge(label: '${agency.roomCount} Ruangan'),
                const SizedBox(width: 8),
                _MetricBadge(label: '${agency.bookingCount} Pesanan'),
                const Spacer(),
                _AgencyActionMenu(agency: agency),
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
            'Pendaftaran Menunggu',
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
                    label: 'Menunggu',
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
    final strings = AppStrings.of(context);
    return PopupMenuButton<String>(
      tooltip: strings.tr('Aksi agensi', 'Agency actions'),
      icon: const Icon(Icons.more_vert),
      onSelected: (value) async {
        final repository = ref.read(superAdminRepositoryProvider);
        Object? result;
        String successMessage =
            strings.tr('Aksi agensi berhasil.', 'Agency action completed.');
        if (value == 'suspend') {
          result = await repository.suspendAgency(agency.id);
          successMessage = strings.tr(
            'Agensi berhasil disuspen.',
            'Agency suspended successfully.',
          );
        } else if (value == 'ban') {
          result = await repository.rejectAgency(agency.id);
          successMessage = strings.tr(
            'Agensi berhasil diblokir.',
            'Agency banned successfully.',
          );
        } else if (value == 'reactivate') {
          result = await repository.reactivateAgency(agency.id);
          successMessage = strings.tr(
            'Agensi berhasil diaktifkan kembali.',
            'Agency reactivated successfully.',
          );
        }
        if (!context.mounted || result == null) return;
        final either = result as dynamic;
        either.match(
          (failure) => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(failure.message)),
          ),
          (_) {
            invalidateSuperAdminData(ref);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(successMessage)),
            );
          },
        );
      },
      itemBuilder: (context) {
        final canReactivate = agency.approvalStatus == 'suspended' ||
            agency.approvalStatus == 'rejected' ||
            !agency.isActive;

        return [
          if (canReactivate)
            PopupMenuItem(
              value: 'reactivate',
              child: Text(strings.tr('Aktifkan kembali', 'Reactivate')),
            )
          else ...[
            PopupMenuItem(
              value: 'suspend',
              child: Text(strings.tr('Disuspen', 'Suspend')),
            ),
            PopupMenuItem(
              value: 'ban',
              child: Text(strings.tr('Blokir', 'Ban')),
            ),
          ],
        ];
      },
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
