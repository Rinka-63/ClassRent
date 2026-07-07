import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/empty_state.dart';
import '../../../../../core/widgets/error_card.dart';
import '../../../domain/entities/platform_room.dart';
import '../../providers/super_admin_providers.dart';
import '../../widgets/super_admin/super_admin_list_controls.dart';
import 'super_admin_room_detail_screen.dart';

class SuperAdminRoomTab extends ConsumerStatefulWidget {
  const SuperAdminRoomTab({super.key});

  @override
  ConsumerState<SuperAdminRoomTab> createState() => _SuperAdminRoomTabState();
}

class _SuperAdminRoomTabState extends ConsumerState<SuperAdminRoomTab> {
  String _search = '';
  String? _filterAgency;
  SuperAdminSortOption _sort = SuperAdminSortOption.nameAsc;
  int _page = 0;
  static const _pageSize = 8;

  @override
  Widget build(BuildContext context) {
    final roomsAsync = ref.watch(platformRoomsProvider);
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    final strings = AppStrings.of(context);

    return roomsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: ErrorCard(
          message: error.toString(),
          onRetry: () => ref.invalidate(platformRoomsProvider),
        ),
      ),
      data: (rooms) {
        final agencyOptions =
            rooms.map((room) => room.agencyName).toSet().toList()..sort();
        final agencyFilterOptions = [
          for (final agencyName in agencyOptions)
            SuperAdminFilterOption(value: agencyName, label: agencyName),
        ];
        final filtered = _applyFilters(rooms);
        final paged = paginateList(filtered, _page, _pageSize);
        final totalPages = totalPagesFor(filtered.length, _pageSize);

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(platformRoomsProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SuperAdminListControls(
                searchHint: '${strings.rooms} / ${strings.agency}',
                onSearchChanged: (value) => setState(() {
                  _search = value.toLowerCase();
                  _page = 0;
                }),
                filterOptions: agencyFilterOptions,
                selectedFilter: _filterAgency,
                onFilterChanged: (value) => setState(() {
                  _filterAgency = value;
                  _page = 0;
                }),
                selectedSort: _sort,
                onSortChanged: (value) => setState(() => _sort = value),
              ),
              const SizedBox(height: 16),
              if (filtered.isEmpty)
                EmptyState(
                  title: strings.tr('Room tidak ditemukan', 'No rooms found'),
                )
              else ...[
                for (final item in paged) ...[
                  _RoomCard(
                    item: item,
                    currency: currency,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            SuperAdminRoomDetailScreen(roomId: item.room.id),
                      ),
                    ),
                    onSuspend: () => _setRoomSuspended(context, item),
                    onDelete: () => _deleteRoom(context, item),
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

  List<PlatformRoom> _applyFilters(List<PlatformRoom> rooms) {
    var result = rooms.where((item) {
      final query = _search.trim();
      if (query.isEmpty) return true;
      return item.room.name.toLowerCase().contains(query) ||
          item.agencyName.toLowerCase().contains(query) ||
          item.room.city.toLowerCase().contains(query);
    }).toList();

    if (_filterAgency != null) {
      result =
          result.where((item) => item.agencyName == _filterAgency).toList();
    }

    result.sort((a, b) {
      return switch (_sort) {
        SuperAdminSortOption.nameAsc => a.room.name.compareTo(b.room.name),
        SuperAdminSortOption.nameDesc => b.room.name.compareTo(a.room.name),
        SuperAdminSortOption.newest =>
          b.room.hourlyRate.compareTo(a.room.hourlyRate),
        SuperAdminSortOption.oldest =>
          a.room.hourlyRate.compareTo(b.room.hourlyRate),
      };
    });

    return result;
  }

  Future<void> _setRoomSuspended(
    BuildContext context,
    PlatformRoom item,
  ) async {
    final repository = ref.read(superAdminRepositoryProvider);
    final result = item.room.isActive
        ? await repository.suspendRoom(item.room.id)
        : await repository.reactivateRoom(item.room.id);
    if (!context.mounted) return;
    result.match(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message)),
      ),
      (_) {
        invalidateSuperAdminData(ref);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              item.room.isActive
                  ? 'Room berhasil disuspend.'
                  : 'Room berhasil diaktifkan.',
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteRoom(BuildContext context, PlatformRoom item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Room?'),
        content: Text(
          'Room "${item.room.name}" akan diarsipkan. Data booking tetap tersimpan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result =
        await ref.read(superAdminRepositoryProvider).deleteRoom(item.room.id);
    if (!context.mounted) return;
    result.match(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message)),
      ),
      (_) {
        invalidateSuperAdminData(ref);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Room berhasil dihapus.')),
        );
      },
    );
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({
    required this.item,
    required this.currency,
    required this.onTap,
    required this.onSuspend,
    required this.onDelete,
  });

  final PlatformRoom item;
  final NumberFormat currency;
  final VoidCallback onTap;
  final VoidCallback onSuspend;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 150,
              width: double.infinity,
              child: item.room.previewUrl != null &&
                      item.room.previewUrl!.isNotEmpty
                  ? Image.network(
                      item.room.previewUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const _RoomImageFallback(),
                    )
                  : const _RoomImageFallback(),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.room.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ),
                      SuperAdminStatusChip(
                        label: item.room.isActive ? 'Active' : 'Suspended',
                        color: item.room.isActive
                            ? AppColors.primary
                            : AppColors.error,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.apartment_outlined,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item.agencyName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.people_outline, size: 16),
                      const SizedBox(width: 4),
                      Text('${item.room.capacity} orang'),
                      const SizedBox(width: 12),
                      const Icon(Icons.location_on_outlined, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.room.city,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${currency.format(item.room.hourlyRate)}/jam',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  if (item.facilities.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final facility in item.facilities.take(4))
                          Chip(
                            label: Text(facility),
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      IconButton.outlined(
                        tooltip: item.room.isActive
                            ? 'Suspend room'
                            : 'Aktifkan room',
                        onPressed: onSuspend,
                        icon: Icon(
                          item.room.isActive
                              ? Icons.block_outlined
                              : Icons.check_circle_outline,
                          size: 18,
                        ),
                        style: IconButton.styleFrom(
                          foregroundColor: item.room.isActive
                              ? AppColors.error
                              : AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.outlined(
                        tooltip: 'Hapus room',
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline, size: 18),
                        style: IconButton.styleFrom(
                          foregroundColor: AppColors.error,
                        ),
                      ),
                    ],
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

class _RoomImageFallback extends StatelessWidget {
  const _RoomImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primaryContainer,
      alignment: Alignment.center,
      child: const Icon(
        Icons.meeting_room_outlined,
        color: AppColors.primary,
        size: 52,
      ),
    );
  }
}
