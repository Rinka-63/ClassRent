// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../core/constants/app_routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_scaffold.dart';
import '../../../../../core/widgets/error_card.dart';
import '../../../../../shared/domain/entities/app_user.dart';
import '../../../../../shared/presentation/widgets/admin_nav_bar.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../rooms/domain/entities/room.dart';
import '../../../rooms/presentation/providers/rooms_providers.dart';
import '../providers/admin_overview_providers.dart';

// Daftar fasilitas standar yang tersedia
const _kFacilityOptions = [
  _FacilityOption(tag: 'wifi', label: 'WiFi', icon: Icons.wifi),
  _FacilityOption(tag: 'ac', label: 'AC', icon: Icons.ac_unit),
  _FacilityOption(tag: 'projector', label: 'Proyektor', icon: Icons.cast),
  _FacilityOption(tag: 'whiteboard', label: 'Whiteboard', icon: Icons.edit_note_outlined),
  _FacilityOption(tag: 'sound_system', label: 'Sound System', icon: Icons.speaker_outlined),
  _FacilityOption(tag: 'microphone', label: 'Mikrofon', icon: Icons.mic_outlined),
  _FacilityOption(tag: 'tv', label: 'Smart TV', icon: Icons.smart_display_outlined),
  _FacilityOption(tag: 'parking', label: 'Parkir', icon: Icons.local_parking_outlined),
  _FacilityOption(tag: 'toilet', label: 'Toilet', icon: Icons.wc_outlined),
  _FacilityOption(tag: 'kitchen', label: 'Dapur', icon: Icons.kitchen_outlined),
  _FacilityOption(tag: 'camera', label: 'Kamera', icon: Icons.videocam_outlined),
  _FacilityOption(tag: 'printer', label: 'Printer', icon: Icons.print_outlined),
];

class _FacilityOption {
  const _FacilityOption({
    required this.tag,
    required this.label,
    required this.icon,
  });
  final String tag;
  final String label;
  final IconData icon;
}

// Provider untuk filter kategori dan pencarian
final _categoryFilterProvider = StateProvider<String>((ref) => 'All Rooms');
final _searchQueryProvider = StateProvider<String>((ref) => '');

class RoomManagementScreen extends ConsumerWidget {
  const RoomManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsValue = ref.watch(adminRoomsProvider);
    final user = ref.watch(currentUserProvider);
    final searchQuery = ref.watch(_searchQueryProvider);
    final selectedCategory = ref.watch(_categoryFilterProvider);

    return AppScaffold(
      title: 'Room Management',
      actions: [
        IconButton(
          onPressed: () => context.push(AppRoutes.profile),
          icon: const Icon(Icons.person_outline),
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context, ref, user: user),
        icon: const Icon(Icons.add),
        label: const Text('Add Room'),
      ),
      bottomNavigationBar: const AdminNavBar(currentPath: AppRoutes.roomManagement),
      body: roomsValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(16),
          child: ErrorCard(message: error.toString()),
        ),
        data: (rooms) {
          final categories = ['All Rooms', 'classroom', 'meeting_room', 'studio', 'hall'];
          final categoryLabels = {
            'All Rooms': 'All Rooms',
            'classroom': 'Classroom',
            'meeting_room': 'Meeting',
            'studio': 'Studio',
            'hall': 'Hall',
          };

          // Filter berdasarkan pencarian dan kategori
          var filtered = rooms.where((room) {
            final q = searchQuery.toLowerCase();
            final matchesSearch = q.isEmpty ||
                room.name.toLowerCase().contains(q) ||
                room.city.toLowerCase().contains(q) ||
                (room.roomType?.toLowerCase().contains(q) ?? false);
            final matchesCategory =
                selectedCategory == 'All Rooms' || room.roomType == selectedCategory;
            return matchesSearch && matchesCategory;
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: _SearchBar(
                  onChanged: (q) => ref.read(_searchQueryProvider.notifier).state = q,
                ),
              ),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, index) {
                    final cat = categories[index];
                    return _CategoryChip(
                      label: categoryLabels[cat] ?? cat,
                      selected: selectedCategory == cat,
                      onTap: () =>
                          ref.read(_categoryFilterProvider.notifier).state = cat,
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: filtered.isEmpty
                    ? const _EmptyRoomsState()
                    : RefreshIndicator(
                        onRefresh: () async => ref.invalidate(adminRoomsProvider),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, index) => _RoomCard(
                            room: filtered[index],
                            onEdit: () => _openEditor(context, ref,
                                room: filtered[index], user: user),
                            onDelete: () => _deleteRoom(context, ref, filtered[index].id),
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref, {
    Room? room,
    AppUser? user,
  }) async {
    // Ambil fasilitas existing jika edit mode
    List<String> existingFacilities = [];
    if (room != null) {
      final result = await ref.read(roomsRepositoryProvider).getRoomFacilities(room.id);
      existingFacilities = result.match((_) => [], (data) => data);
    }

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: room?.name ?? '');
    final capacityController = TextEditingController(text: room?.capacity.toString() ?? '');
    final hourlyRateController = TextEditingController(
      text: room?.hourlyRate.toStringAsFixed(0) ?? '',
    );
    final cityController = TextEditingController(text: room?.city ?? '');
    final descriptionController = TextEditingController(text: room?.description ?? '');
    final previewUrlController = TextEditingController(text: room?.previewUrl ?? '');
    String selectedType = room?.roomType ?? 'classroom';
    bool isActive = room?.isActive ?? true;
    bool requiresApproval = room?.requiresApproval ?? false;
    final selectedFacilities = Set<String>.from(existingFacilities);

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
                top: 8,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        room == null ? 'Tambah Room' : 'Edit Room',
                        style: Theme.of(sheetContext)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 16),
                      _Field(controller: nameController, label: 'Nama room'),
                      _Field(controller: cityController, label: 'Kota'),
                      _Field(
                          controller: capacityController,
                          label: 'Kapasitas',
                          keyboardType: TextInputType.number),
                      _Field(
                          controller: hourlyRateController,
                          label: 'Tarif per jam (Rp)',
                          keyboardType: TextInputType.number),
                      _Field(
                          controller: descriptionController,
                          label: 'Deskripsi',
                          maxLines: 3,
                          required: false),
                      _Field(
                          controller: previewUrlController,
                          label: 'URL Gambar/Video Ruangan (Preview)',
                          required: false),
                      // Dropdown tipe ruangan
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedType,
                          decoration: const InputDecoration(labelText: 'Tipe ruangan'),
                          items: const [
                            DropdownMenuItem(value: 'classroom', child: Text('Classroom')),
                            DropdownMenuItem(value: 'meeting_room', child: Text('Meeting Room')),
                            DropdownMenuItem(value: 'studio', child: Text('Studio')),
                            DropdownMenuItem(value: 'hall', child: Text('Hall / Aula')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => selectedType = val);
                          },
                        ),
                      ),
                      // Switch aktif/approval
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: isActive,
                        onChanged: (val) => setState(() => isActive = val),
                        title: const Text('Aktif'),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: requiresApproval,
                        onChanged: (val) => setState(() => requiresApproval = val),
                        title: const Text('Perlu persetujuan'),
                      ),
                      // Fasilitas
                      const SizedBox(height: 8),
                      Text(
                        'Fasilitas',
                        style: Theme.of(sheetContext)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _kFacilityOptions.map((opt) {
                          final selected = selectedFacilities.contains(opt.tag);
                          return FilterChip(
                            avatar: Icon(
                              opt.icon,
                              size: 16,
                              color: selected
                                  ? Colors.white
                                  : AppColors.onSurfaceVariant,
                            ),
                            label: Text(opt.label),
                            selected: selected,
                            onSelected: (_) => setState(() {
                              if (selected) {
                                selectedFacilities.remove(opt.tag);
                              } else {
                                selectedFacilities.add(opt.tag);
                              }
                            }),
                            selectedColor: AppColors.primary,
                            checkmarkColor: Colors.white,
                            labelStyle: TextStyle(
                              color:
                                  selected ? Colors.white : AppColors.onSurface,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          final repo = ref.read(roomsRepositoryProvider);
                          final payload = <String, dynamic>{
                            'admin_id': user?.id,
                            'name': nameController.text.trim(),
                            'description': descriptionController.text.trim().isEmpty
                                ? null
                                : descriptionController.text.trim(),
                            'room_type': selectedType,
                            'capacity': int.parse(capacityController.text.trim()),
                            'hourly_rate': double.parse(hourlyRateController.text.trim()),
                            'city': cityController.text.trim(),
                            'is_active': isActive,
                            'requires_approval': requiresApproval,
                            'preview_url': previewUrlController.text.trim().isEmpty
                                ? null
                                : previewUrlController.text.trim(),
                          };
                          final saveResult = room == null
                              ? await repo.createRoom(payload)
                              : await repo.updateRoom(room.id, payload);

                          await saveResult.match(
                            (_) async {},
                            (savedRoom) async {
                              // Simpan fasilitas setelah room berhasil disimpan
                              await repo.saveRoomFacilities(
                                  savedRoom.id, selectedFacilities.toList());
                            },
                          );

                          if (sheetContext.mounted) {
                            Navigator.pop(sheetContext, saveResult.isRight());
                          }
                        },
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                        ),
                        child: const Text('Simpan'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (result == true) {
      ref.invalidate(adminRoomsProvider);
      // Invalidate room facilities untuk semua room yang diketahui
      ref.invalidate(roomFacilitiesProvider);
    }
  }

  Future<void> _deleteRoom(BuildContext context, WidgetRef ref, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus room?'),
        content:
            const Text('Room akan diarsipkan (soft delete). Data booking tetap tersimpan.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Hapus')),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await ref.read(roomsRepositoryProvider).deleteRoom(id);
      result.match(
        (failure) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        ),
        (_) => ref.invalidate(adminRoomsProvider),
      );
    }
  }
}

// ─── Search Bar ──────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: TextField(
          onChanged: onChanged,
          decoration: const InputDecoration(
            hintText: 'Cari room, kota, atau tipe...',
            prefixIcon: Icon(Icons.search),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }
}

// ─── Category Chip ───────────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
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

// ─── Empty State ─────────────────────────────────────────────────────────────

class _EmptyRoomsState extends StatelessWidget {
  const _EmptyRoomsState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.meeting_room_outlined, size: 64, color: AppColors.onSurfaceVariant),
            const SizedBox(height: 16),
            Text('Belum ada room', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Tekan tombol "Add Room" untuk menambahkan room pertama.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Room Card ───────────────────────────────────────────────────────────────

class _RoomCard extends ConsumerWidget {
  const _RoomCard({
    required this.room,
    required this.onEdit,
    required this.onDelete,
  });

  final Room room;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    final statusColor = room.isActive ? AppColors.secondary : AppColors.tertiary;
    final facilitiesAsync = ref.watch(roomFacilitiesProvider(room.id));

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: const [
          BoxShadow(color: Color(0x12000000), blurRadius: 20, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header thumbnail
          Container(
            height: 140,
            color: AppColors.primaryContainer.withValues(alpha: 0.14),
            alignment: Alignment.center,
            child: const Icon(Icons.meeting_room_outlined, size: 56, color: AppColors.primary),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nama + status chip
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        room.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusChip(
                        label: room.isActive ? 'Aktif' : 'Nonaktif',
                        color: statusColor),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  (room.roomType ?? 'classroom').toUpperCase(),
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                // Info row
                Row(
                  children: [
                    const Icon(Icons.people_outline, size: 16),
                    const SizedBox(width: 4),
                    Text('${room.capacity} orang'),
                    const SizedBox(width: 12),
                    const Icon(Icons.location_on_outlined, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        room.city,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${currency.format(room.hourlyRate)} / jam',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
                const SizedBox(height: 10),
                // Fasilitas real-time
                facilitiesAsync.when(
                  loading: () => const SizedBox(
                    height: 28,
                    child: Center(
                        child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (facilities) {
                    if (facilities.isEmpty) {
                      return Text(
                        'Belum ada fasilitas — edit untuk menambahkan',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.onSurfaceVariant),
                      );
                    }
                    final display = facilities.take(4).toList();
                    final extra = facilities.length - display.length;
                    return Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        ...display.map((tag) => _FacilityPill(tag: tag)),
                        if (extra > 0)
                          _FacilityPill(tag: '+$extra', isExtra: true),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Edit'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.outlined(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline, size: 18),
                      style: IconButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(color: AppColors.error.withValues(alpha: 0.4)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Facility Pill ───────────────────────────────────────────────────────────

class _FacilityPill extends StatelessWidget {
  const _FacilityPill({required this.tag, this.isExtra = false});

  final String tag;
  final bool isExtra;

  @override
  Widget build(BuildContext context) {
    if (isExtra) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          tag,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: AppColors.onSurfaceVariant),
        ),
      );
    }

    final opt = _kFacilityOptions.where((o) => o.tag == tag).firstOrNull;
    final icon = opt?.icon ?? Icons.check_circle_outline;
    final label = opt?.label ?? tag;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ─── Status Chip ─────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}

// ─── Field ───────────────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.maxLines = 1,
    this.required = true,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: required
            ? (value) =>
                (value == null || value.trim().isEmpty) ? '$label wajib diisi' : null
            : null,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
