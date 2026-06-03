// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/error_card.dart';
import '../../../../shared/domain/entities/app_user.dart';
import '../../../../shared/presentation/widgets/admin_nav_bar.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../rooms/domain/entities/room.dart';
import '../../../rooms/presentation/providers/rooms_providers.dart';
import '../providers/admin_overview_providers.dart';

class RoomManagementScreen extends ConsumerWidget {
  const RoomManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsValue = ref.watch(adminRoomsProvider);
    final user = ref.watch(currentUserProvider);

    return AppScaffold(
      title: 'Room Management',
      actions: [
        IconButton(
          onPressed: () => context.push(AppRoutes.profile),
          icon: const Icon(Icons.person_outline),
        ),
      ],
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(context, ref, user: user),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: const AdminNavBar(currentPath: AppRoutes.roomManagement),
      body: roomsValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(16),
          child: ErrorCard(message: error.toString()),
        ),
        data: (rooms) {
          final categories = ['All Rooms', 'Lecture Hall', 'Lab', 'Studio', 'Meeting'];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const _SearchBar(),
              const SizedBox(height: 12),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, index) => _CategoryChip(
                    label: categories[index],
                    selected: index == 0,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (rooms.isEmpty)
                const _EmptyRoomsState()
              else
                for (final room in rooms) ...[
                  _RoomCard(
                    room: room,
                    onEdit: () => _openEditor(context, ref, room: room, user: user),
                    onDelete: () => _deleteRoom(context, ref, room.id),
                  ),
                  const SizedBox(height: 12),
                ],
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
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: room?.name ?? '');
    final capacityController = TextEditingController(text: room?.capacity.toString() ?? '');
    final hourlyRateController = TextEditingController(
      text: room?.hourlyRate.toStringAsFixed(0) ?? '',
    );
    final cityController = TextEditingController(text: room?.city ?? '');
    final typeController = TextEditingController(text: room?.roomType ?? 'classroom');
    final descriptionController = TextEditingController(text: room?.description ?? '');
    bool isActive = room?.isActive ?? true;
    bool requiresApproval = room?.requiresApproval ?? false;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
            top: 8,
          ),
          child: Form(
            key: formKey,
            child: ListView(
              shrinkWrap: true,
              children: [
                Text(
                  room == null ? 'Add Room' : 'Edit Room',
                  style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                _Field(controller: nameController, label: 'Room name'),
                _Field(controller: typeController, label: 'Room type'),
                _Field(controller: cityController, label: 'City'),
                _Field(controller: capacityController, label: 'Capacity', keyboardType: TextInputType.number),
                _Field(controller: hourlyRateController, label: 'Hourly rate', keyboardType: TextInputType.number),
                _Field(controller: descriptionController, label: 'Description', maxLines: 3),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: isActive,
                  onChanged: (value) => isActive = value,
                  title: const Text('Active'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: requiresApproval,
                  onChanged: (value) => requiresApproval = value,
                  title: const Text('Requires approval'),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final repo = ref.read(roomsRepositoryProvider);
                    final payload = <String, dynamic>{
                      'admin_id': user?.id,
                      'name': nameController.text.trim(),
                      'description': descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
                      'room_type': typeController.text.trim().isEmpty ? 'classroom' : typeController.text.trim(),
                      'capacity': int.parse(capacityController.text.trim()),
                      'hourly_rate': double.parse(hourlyRateController.text.trim()),
                      'city': cityController.text.trim(),
                      'is_active': isActive,
                      'requires_approval': requiresApproval,
                      'facility_id': room?.facilityId,
                    };
                    final result = room == null
                        ? await repo.createRoom(payload)
                        : await repo.updateRoom(room.id, payload);
                    if (context.mounted) {
                      Navigator.pop(sheetContext, result.isRight());
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result == true) {
      ref.invalidate(adminRoomsProvider);
    }
  }

  Future<void> _deleteRoom(BuildContext context, WidgetRef ref, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete room?'),
        content: const Text('This will archive the room by setting deleted_at.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Delete')),
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

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: TextField(
          decoration: const InputDecoration(
            hintText: 'Search rooms, types, or facilities...',
            prefixIcon: Icon(Icons.search),
            border: InputBorder.none,
          ),
          onChanged: (_) {},
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
  });

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      label: Text(label),
      onSelected: (_) {},
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(color: selected ? Colors.white : AppColors.onSurface),
    );
  }
}

class _EmptyRoomsState extends StatelessWidget {
  const _EmptyRoomsState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        children: [
          const Icon(Icons.meeting_room_outlined, size: 54, color: AppColors.onSurfaceVariant),
          const SizedBox(height: 12),
          Text('No rooms yet', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            'Press the + button to add the first room for this agency.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({
    required this.room,
    required this.onEdit,
    required this.onDelete,
  });

  final Room room;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    final statusColor = room.isActive ? AppColors.secondary : AppColors.tertiary;

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
          Container(
            height: 220,
            color: AppColors.primaryContainer.withValues(alpha: 0.14),
            alignment: Alignment.center,
            child: const Icon(Icons.meeting_room_outlined, size: 72, color: AppColors.primary),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        room.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    _StatusChip(label: room.isActive ? 'Available' : 'Inactive', color: statusColor),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  room.roomType == null ? 'CLASSROOM' : room.roomType!.toUpperCase(),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.people_outline, size: 18),
                    const SizedBox(width: 6),
                    Text('${room.capacity} people'),
                    const SizedBox(width: 12),
                    const Icon(Icons.location_on_outlined, size: 18),
                    const SizedBox(width: 6),
                    Expanded(child: Text(room.city)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(currency.format(room.hourlyRate), style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const _InfoChip(icon: Icons.wifi, label: 'WiFi'),
                    const SizedBox(width: 8),
                    const _InfoChip(icon: Icons.smart_display_outlined, label: 'Display'),
                    const SizedBox(width: 8),
                    const _InfoChip(icon: Icons.ac_unit, label: 'AC'),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    TextButton.icon(onPressed: onEdit, icon: const Icon(Icons.edit_outlined), label: const Text('Edit')),
                    const SizedBox(width: 8),
                    TextButton.icon(onPressed: onDelete, icon: const Icon(Icons.delete_outline), label: const Text('Delete')),
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
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: (value) => (value == null || value.trim().isEmpty) ? '$label is required' : null,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
