import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

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
        final agencyOptions = rooms.map((room) => room.agencyName).toSet().toList()..sort();
        final filtered = _applyFilters(rooms);
        final paged = paginateList(filtered, _page, _pageSize);
        final totalPages = totalPagesFor(filtered.length, _pageSize);

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(platformRoomsProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SuperAdminListControls(
                searchHint: 'Cari room atau agency...',
                onSearchChanged: (value) => setState(() {
                  _search = value.toLowerCase();
                  _page = 0;
                }),
                filterOptions: agencyOptions,
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
                const EmptyState(title: 'Room tidak ditemukan')
              else ...[
                for (final item in paged) ...[
                  _RoomListTile(
                    item: item,
                    currency: currency,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => SuperAdminRoomDetailScreen(roomId: item.room.id),
                      ),
                    ),
                    onEdit: () => _editRoom(context, item),
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
      result = result.where((item) => item.agencyName == _filterAgency).toList();
    }

    result.sort((a, b) {
      return switch (_sort) {
        SuperAdminSortOption.nameAsc => a.room.name.compareTo(b.room.name),
        SuperAdminSortOption.nameDesc => b.room.name.compareTo(a.room.name),
        SuperAdminSortOption.newest => b.room.hourlyRate.compareTo(a.room.hourlyRate),
        SuperAdminSortOption.oldest => a.room.hourlyRate.compareTo(b.room.hourlyRate),
      };
    });

    return result;
  }

  Future<void> _editRoom(BuildContext context, PlatformRoom item) async {
    final nameController = TextEditingController(text: item.room.name);
    final capacityController = TextEditingController(text: '${item.room.capacity}');
    final rateController = TextEditingController(text: item.room.hourlyRate.toStringAsFixed(0));
    var isActive = item.room.isActive;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Room'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nama Room')),
              TextField(controller: capacityController, decoration: const InputDecoration(labelText: 'Kapasitas')),
              TextField(controller: rateController, decoration: const InputDecoration(labelText: 'Harga/jam')),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: isActive,
                onChanged: (value) => setState(() => isActive = value),
                title: const Text('Active'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Batal')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Simpan')),
          ],
        ),
      ),
    );

    if (saved == true) {
      await ref.read(superAdminRepositoryProvider).updateRoom(item.room.id, {
        'name': nameController.text.trim(),
        'capacity': int.tryParse(capacityController.text.trim()) ?? item.room.capacity,
        'hourly_rate': double.tryParse(rateController.text.trim()) ?? item.room.hourlyRate,
        'is_active': isActive,
      });
      invalidateSuperAdminData(ref);
    }
  }

  Future<void> _deleteRoom(BuildContext context, PlatformRoom item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Room?'),
        content: Text('Room "${item.room.name}" akan diarsipkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Hapus')),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(superAdminRepositoryProvider).deleteRoom(item.room.id);
      invalidateSuperAdminData(ref);
    }
  }
}

class _RoomListTile extends StatelessWidget {
  const _RoomListTile({
    required this.item,
    required this.currency,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final PlatformRoom item;
  final NumberFormat currency;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.room.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                SuperAdminStatusChip(
                  label: item.room.isActive ? 'Active' : 'Inactive',
                  color: item.room.isActive ? AppColors.secondary : AppColors.onSurfaceVariant,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.apartment_outlined, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item.agencyName,
                    style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Kapasitas: ${item.room.capacity} • ${currency.format(item.room.hourlyRate)}/jam'),
            if (item.facilities.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final facility in item.facilities.take(4))
                      Chip(label: Text(facility), visualDensity: VisualDensity.compact),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: onEdit, child: const Text('Edit')),
                TextButton(onPressed: onDelete, child: const Text('Hapus')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
