// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../core/constants/app_routes.dart';
import '../../../../../core/providers/storage_provider.dart';
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
  _FacilityOption(
      tag: 'whiteboard', label: 'Whiteboard', icon: Icons.edit_note_outlined),
  _FacilityOption(
      tag: 'sound_system', label: 'Sound System', icon: Icons.speaker_outlined),
  _FacilityOption(
      tag: 'microphone', label: 'Mikrofon', icon: Icons.mic_outlined),
  _FacilityOption(
      tag: 'tv', label: 'Smart TV', icon: Icons.smart_display_outlined),
  _FacilityOption(
      tag: 'parking', label: 'Parkir', icon: Icons.local_parking_outlined),
  _FacilityOption(tag: 'toilet', label: 'Toilet', icon: Icons.wc_outlined),
  _FacilityOption(tag: 'kitchen', label: 'Dapur', icon: Icons.kitchen_outlined),
  _FacilityOption(
      tag: 'camera', label: 'Kamera', icon: Icons.videocam_outlined),
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
      bottomNavigationBar:
          const AdminNavBar(currentPath: AppRoutes.roomManagement),
      body: roomsValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(16),
          child: ErrorCard(message: error.toString()),
        ),
        data: (rooms) {
          final categories = [
            'All Rooms',
            'classroom',
            'meeting_room',
            'studio',
            'hall'
          ];
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
            final matchesCategory = selectedCategory == 'All Rooms' ||
                room.roomType == selectedCategory;
            return matchesSearch && matchesCategory;
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: _SearchBar(
                  onChanged: (q) =>
                      ref.read(_searchQueryProvider.notifier).state = q,
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
                      onTap: () => ref
                          .read(_categoryFilterProvider.notifier)
                          .state = cat,
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: filtered.isEmpty
                    ? const _EmptyRoomsState()
                    : RefreshIndicator(
                        onRefresh: () async =>
                            ref.invalidate(adminRoomsProvider),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, index) => _RoomCard(
                            room: filtered[index],
                            onTap: () => context.push(
                              AppRoutes.roomDetail.replaceFirst(
                                ':roomId',
                                filtered[index].id,
                              ),
                            ),
                            onEdit: () => _openEditor(context, ref,
                                room: filtered[index], user: user),
                            onDelete: () =>
                                _deleteRoom(context, ref, filtered[index].id),
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
    List<String> existingImages = [];
    if (room != null) {
      final result =
          await ref.read(roomsRepositoryProvider).getRoomFacilities(room.id);
      existingFacilities = result.match((_) => [], (data) => data);
      final imagesResult =
          await ref.read(roomsRepositoryProvider).getRoomImages(room.id);
      existingImages = imagesResult.match((_) => [], (data) => data);
    }

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: room?.name ?? '');
    final capacityController =
        TextEditingController(text: room?.capacity.toString() ?? '');
    final hourlyRateController = TextEditingController(
      text: room?.hourlyRate.toStringAsFixed(0) ?? '',
    );
    final cityController = TextEditingController(text: room?.city ?? '');
    final descriptionController =
        TextEditingController(text: room?.description ?? '');
    String selectedType = room?.roomType ?? 'classroom';
    bool isActive = room?.isActive ?? true;
    bool requiresApproval = room?.requiresApproval ?? false;
    final selectedFacilities = Set<String>.from(existingFacilities);
    final roomImages = <String>[
      ...existingImages,
      if (existingImages.isEmpty &&
          room?.previewUrl != null &&
          room!.previewUrl!.isNotEmpty)
        room.previewUrl!,
    ];

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) => _RoomEditorSheet(
        room: room,
        user: user,
        formKey: formKey,
        nameController: nameController,
        cityController: cityController,
        capacityController: capacityController,
        hourlyRateController: hourlyRateController,
        descriptionController: descriptionController,
        selectedType: selectedType,
        isActive: isActive,
        requiresApproval: requiresApproval,
        selectedFacilities: selectedFacilities,
        roomImages: roomImages,
      ),
    );

    if (result == true) {
      ref.invalidate(adminRoomsProvider);
      // Invalidate room facilities untuk semua room yang diketahui
      ref.invalidate(roomFacilitiesProvider);
      ref.invalidate(roomImagesProvider);
    }
  }

  Future<void> _deleteRoom(
      BuildContext context, WidgetRef ref, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus room?'),
        content: const Text(
            'Room akan diarsipkan (soft delete). Data booking tetap tersimpan.'),
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

class _RoomEditorSheet extends ConsumerStatefulWidget {
  const _RoomEditorSheet({
    required this.room,
    required this.user,
    required this.formKey,
    required this.nameController,
    required this.cityController,
    required this.capacityController,
    required this.hourlyRateController,
    required this.descriptionController,
    required this.selectedType,
    required this.isActive,
    required this.requiresApproval,
    required this.selectedFacilities,
    required this.roomImages,
  });

  final Room? room;
  final AppUser? user;
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController cityController;
  final TextEditingController capacityController;
  final TextEditingController hourlyRateController;
  final TextEditingController descriptionController;
  final String selectedType;
  final bool isActive;
  final bool requiresApproval;
  final Set<String> selectedFacilities;
  final List<String> roomImages;

  @override
  ConsumerState<_RoomEditorSheet> createState() => _RoomEditorSheetState();
}

class _RoomEditorSheetState extends ConsumerState<_RoomEditorSheet> {
  late String _selectedType;
  late bool _isActive;
  late bool _requiresApproval;
  late final Set<String> _selectedFacilities;
  late final List<String> _roomImages;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.selectedType;
    _isActive = widget.isActive;
    _requiresApproval = widget.requiresApproval;
    _selectedFacilities = Set<String>.from(widget.selectedFacilities);
    _roomImages = List<String>.from(widget.roomImages);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      minChildSize: 0.55,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Form(
          key: widget.formKey,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.meeting_room_outlined,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.room == null ? 'Tambah Room' : 'Edit Room',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            'Lengkapi detail, foto, status, dan fasilitas.',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(
                    20,
                    0,
                    20,
                    MediaQuery.viewInsetsOf(context).bottom + 16,
                  ),
                  children: [
                    _EditorSection(
                      title: 'Informasi Dasar',
                      icon: Icons.edit_note_outlined,
                      children: [
                        _Field(
                          controller: widget.nameController,
                          label: 'Nama room',
                        ),
                        _Field(
                          controller: widget.cityController,
                          label: 'Kota',
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: _Field(
                                controller: widget.capacityController,
                                label: 'Kapasitas',
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _Field(
                                controller: widget.hourlyRateController,
                                label: 'Tarif / jam',
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        _Field(
                          controller: widget.descriptionController,
                          label: 'Deskripsi',
                          maxLines: 4,
                          required: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _EditorSection(
                      title: 'Foto Ruangan',
                      icon: Icons.photo_library_outlined,
                      trailing: Text(
                        '${_roomImages.length} foto',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      children: [
                        _RoomImagePicker(
                          images: _roomImages,
                          onRemove: (index) =>
                              setState(() => _roomImages.removeAt(index)),
                          onPickGallery: () => _pickImage(isCamera: false),
                          onPickCamera: () => _pickImage(isCamera: true),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _EditorSection(
                      title: 'Tipe & Status',
                      icon: Icons.tune_outlined,
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: _selectedType,
                          decoration: const InputDecoration(
                            labelText: 'Tipe ruangan',
                            prefixIcon: Icon(Icons.category_outlined),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'classroom',
                              child: Text('Classroom'),
                            ),
                            DropdownMenuItem(
                              value: 'meeting_room',
                              child: Text('Meeting Room'),
                            ),
                            DropdownMenuItem(
                              value: 'studio',
                              child: Text('Studio'),
                            ),
                            DropdownMenuItem(
                              value: 'hall',
                              child: Text('Hall / Aula'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _selectedType = value);
                          },
                        ),
                        const SizedBox(height: 10),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _isActive,
                          onChanged: (value) =>
                              setState(() => _isActive = value),
                          title: const Text('Aktif'),
                          subtitle: const Text(
                            'Room bisa dilihat dan dipesan user.',
                          ),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _requiresApproval,
                          onChanged: (value) =>
                              setState(() => _requiresApproval = value),
                          title: const Text('Perlu persetujuan'),
                          subtitle: const Text(
                            'Booking harus dikonfirmasi admin agency.',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _EditorSection(
                      title: 'Fasilitas',
                      icon: Icons.widgets_outlined,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _kFacilityOptions.map((option) {
                            final selected =
                                _selectedFacilities.contains(option.tag);
                            return FilterChip(
                              avatar: Icon(
                                option.icon,
                                size: 16,
                                color: selected
                                    ? Colors.white
                                    : AppColors.onSurfaceVariant,
                              ),
                              label: Text(option.label),
                              selected: selected,
                              selectedColor: AppColors.primary,
                              checkmarkColor: Colors.white,
                              labelStyle: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : AppColors.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                              onSelected: (_) {
                                setState(() {
                                  if (selected) {
                                    _selectedFacilities.remove(option.tag);
                                  } else {
                                    _selectedFacilities.add(option.tag);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    border: Border(
                      top: BorderSide(
                        color: AppColors.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  child: FilledButton.icon(
                    onPressed: _isSaving ? null : _saveRoom,
                    icon: _isSaving
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(widget.room == null ? 'Tambah Room' : 'Simpan'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage({required bool isCamera}) async {
    final storageService = ref.read(storageServiceProvider);
    final result = isCamera
        ? await storageService.pickImageFromCamera()
        : await storageService.pickImageFromGallery();

    if (!mounted) return;
    result.match(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(failure.message),
          backgroundColor: AppColors.error,
        ),
      ),
      (file) => setState(() => _roomImages.add(file.path)),
    );
  }

  Future<void> _saveRoom() async {
    if (!widget.formKey.currentState!.validate()) return;
    final capacity = int.tryParse(widget.capacityController.text.trim());
    final hourlyRate = double.tryParse(widget.hourlyRateController.text.trim());
    if (capacity == null || hourlyRate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Kapasitas dan tarif harus berupa angka.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final repo = ref.read(roomsRepositoryProvider);
    final storageService = ref.read(storageServiceProvider);
    final uploadedImages = <String>[];

    for (final imagePath in _roomImages) {
      if (imagePath.startsWith('http')) {
        uploadedImages.add(imagePath);
        continue;
      }
      final uploadResult = await storageService.uploadRoomImage(
        File(imagePath),
        widget.room?.id ?? 'room_${DateTime.now().millisecondsSinceEpoch}',
      );
      final imageUrl = uploadResult.match(
        (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Gagal upload gambar: ${failure.message}')),
            );
          }
          return null;
        },
        (url) => url,
      );
      if (imageUrl == null) {
        if (mounted) setState(() => _isSaving = false);
        return;
      }
      uploadedImages.add(imageUrl);
    }

    final payload = <String, dynamic>{
      'admin_id': widget.user?.id,
      'name': widget.nameController.text.trim(),
      'description': widget.descriptionController.text.trim().isEmpty
          ? null
          : widget.descriptionController.text.trim(),
      'room_type': _selectedType,
      'capacity': capacity,
      'hourly_rate': hourlyRate,
      'city': widget.cityController.text.trim(),
      'is_active': _isActive,
      'requires_approval': _requiresApproval,
      'preview_url': uploadedImages.isEmpty ? null : uploadedImages.first,
    };

    final saveResult = widget.room == null
        ? await repo.createRoom(payload)
        : await repo.updateRoom(widget.room!.id, payload);

    await saveResult.match(
      (failure) async {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
      },
      (savedRoom) async {
        await repo.saveRoomFacilities(
          savedRoom.id,
          _selectedFacilities.toList(),
        );
        await repo.saveRoomImages(savedRoom.id, uploadedImages);
        if (mounted) Navigator.pop(context, true);
      },
    );

    if (mounted) setState(() => _isSaving = false);
  }
}

class _EditorSection extends StatelessWidget {
  const _EditorSection({
    required this.title,
    required this.icon,
    required this.children,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _RoomImagePicker extends StatelessWidget {
  const _RoomImagePicker({
    required this.images,
    required this.onRemove,
    required this.onPickGallery,
    required this.onPickCamera,
  });

  final List<String> images;
  final ValueChanged<int> onRemove;
  final VoidCallback onPickGallery;
  final VoidCallback onPickCamera;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (images.isEmpty)
          Container(
            height: 118,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Text(
              'Belum ada foto. Tambahkan minimal satu foto utama.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
            ),
          )
        else
          SizedBox(
            height: 118,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final imagePath = images[index];
                final provider = imagePath.startsWith('http')
                    ? NetworkImage(imagePath) as ImageProvider
                    : FileImage(File(imagePath));
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image(
                        image: provider,
                        width: 132,
                        height: 118,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: IconButton.filledTonal(
                        onPressed: () => onRemove(index),
                        icon: const Icon(Icons.close, size: 16),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black54,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.square(30),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPickGallery,
                icon: const Icon(Icons.photo_library_outlined, size: 18),
                label: const Text('Galeri'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPickCamera,
                icon: const Icon(Icons.camera_alt_outlined, size: 18),
                label: const Text('Kamera'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

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
      labelStyle:
          TextStyle(color: selected ? Colors.white : AppColors.onSurface),
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
            const Icon(Icons.meeting_room_outlined,
                size: 64, color: AppColors.onSurfaceVariant),
            const SizedBox(height: 16),
            Text('Belum ada room',
                style: Theme.of(context).textTheme.titleMedium),
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
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final Room room;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    final statusColor =
        room.isActive ? AppColors.secondary : AppColors.tertiary;
    final facilitiesAsync = ref.watch(roomFacilitiesProvider(room.id));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.outlineVariant),
          boxShadow: const [
            BoxShadow(
                color: Color(0x12000000), blurRadius: 20, offset: Offset(0, 8)),
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
              child: room.previewUrl != null && room.previewUrl!.isNotEmpty
                  ? Image.network(
                      room.previewUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 140,
                      errorBuilder: (_, __, ___) => const Icon(
                          Icons.meeting_room_outlined,
                          size: 56,
                          color: AppColors.primary),
                    )
                  : const Icon(Icons.meeting_room_outlined,
                      size: 56, color: AppColors.primary),
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
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700, color: AppColors.primary),
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
                              child:
                                  CircularProgressIndicator(strokeWidth: 2))),
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
                          side: BorderSide(
                              color: AppColors.error.withValues(alpha: 0.4)),
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
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.primary, fontWeight: FontWeight.w600),
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
      child: Text(label,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w700, fontSize: 12)),
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
            ? (value) => (value == null || value.trim().isEmpty)
                ? '$label wajib diisi'
                : null
            : null,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
