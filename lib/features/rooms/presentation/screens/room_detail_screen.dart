import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/error_card.dart';
import '../../../../shared/domain/entities/app_user.dart';
import '../../../../shared/presentation/widgets/admin_nav_bar.dart';
import '../../../../shared/presentation/widgets/role_aware_nav_bar.dart';
import '../../../../shared/presentation/widgets/image_preview_dialog.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../booking/presentation/providers/booking_admin_providers.dart';
import '../../domain/entities/room.dart';
import '../../../booking/domain/entities/booking.dart';
import '../providers/rooms_providers.dart';
import '../providers/favorites_provider.dart';

// ─── Definisi fasilitas dengan ikon ──────────────────────────────────────────

const _kFacilityMeta = <String, _FacilityMeta>{
  'wifi': _FacilityMeta(label: 'WiFi', icon: Icons.wifi),
  'ac': _FacilityMeta(label: 'AC', icon: Icons.ac_unit),
  'projector': _FacilityMeta(label: 'Proyektor', icon: Icons.cast),
  'whiteboard':
      _FacilityMeta(label: 'Whiteboard', icon: Icons.edit_note_outlined),
  'sound_system':
      _FacilityMeta(label: 'Sound System', icon: Icons.speaker_outlined),
  'microphone': _FacilityMeta(label: 'Mikrofon', icon: Icons.mic_outlined),
  'tv': _FacilityMeta(label: 'Smart TV', icon: Icons.smart_display_outlined),
  'parking': _FacilityMeta(label: 'Parkir', icon: Icons.local_parking_outlined),
  'toilet': _FacilityMeta(label: 'Toilet', icon: Icons.wc_outlined),
  'kitchen': _FacilityMeta(label: 'Dapur', icon: Icons.kitchen_outlined),
  'camera': _FacilityMeta(label: 'Kamera', icon: Icons.videocam_outlined),
  'printer': _FacilityMeta(label: 'Printer', icon: Icons.print_outlined),
};

class _FacilityMeta {
  const _FacilityMeta({required this.label, required this.icon});
  final String label;
  final IconData icon;
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class RoomDetailScreen extends ConsumerWidget {
  const RoomDetailScreen({required this.roomId, super.key});

  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomValue = ref.watch(roomDetailProvider(roomId));
    final user = ref.watch(currentUserProvider);
    final isAdmin =
        user?.role == UserRole.admin || user?.role == UserRole.superAdmin;
    final strings = AppStrings.of(context);

    return AppScaffold(
      title: strings.roomDetail,
      actions: [
        if (!isAdmin)
          Consumer(
            builder: (context, ref, _) {
              final favoriteIds =
                  ref.watch(favoritesProvider).valueOrNull ?? {};
              final isFav = favoriteIds.contains(roomId);
              return IconButton(
                onPressed: () =>
                    ref.read(favoritesProvider.notifier).toggleFavorite(roomId),
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? Colors.red : null,
                ),
              );
            },
          ),
        IconButton(
          onPressed: () => context.push(AppRoutes.profile),
          icon: const Icon(Icons.person_outline),
        ),
      ],
      bottomNavigationBar: isAdmin
          ? const AdminNavBar(currentPath: AppRoutes.roomManagement)
          : const RoleAwareNavBar(currentPath: AppRoutes.home),
      body: roomValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(16),
          child: ErrorCard(message: error.toString()),
        ),
        data: (room) => DefaultTabController(
          length: 4,
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _RoomHero(room: room, isAdmin: isAdmin),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _TabHeader(
                  TabBar(
                    tabs: [
                      Tab(text: strings.tr('Overview', 'Overview')),
                      Tab(text: strings.facilities),
                      Tab(text: strings.tr('Jadwal', 'Schedule')),
                      Tab(text: strings.bookings),
                    ],
                    labelColor: AppColors.primary,
                    indicatorColor: AppColors.primary,
                    isScrollable: false,
                  ),
                ),
              ),
            ],
            body: TabBarView(
              children: [
                _OverviewTab(room: room),
                _FacilitiesTab(roomId: room.id, isAdmin: isAdmin),
                _ScheduleTab(roomId: room.id, isAdmin: isAdmin),
                _BookingsTab(roomId: room.id),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Room Hero ───────────────────────────────────────────────────────────────

class _RoomHero extends StatelessWidget {
  const _RoomHero({required this.room, required this.isAdmin});

  final Room room;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final strings = AppStrings.of(context);
    final money =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x10000000), blurRadius: 16, offset: Offset(0, 6)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          Container(
            height: 200,
            width: double.infinity,
            color: colorScheme.primaryContainer.withValues(alpha: 0.14),
            alignment: Alignment.center,
            child: room.previewUrl != null
                ? GestureDetector(
                    onTap: () => showImagePreview(context, room.previewUrl!),
                    child: Image.network(
                      room.previewUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 200,
                      errorBuilder: (_, __, ___) => const Icon(
                          Icons.meeting_room_outlined,
                          size: 72,
                          color: AppColors.primary),
                    ),
                  )
                : const Icon(Icons.meeting_room_outlined,
                    size: 72, color: AppColors.primary),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nama room
                Text(
                  room.name,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 16, color: AppColors.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      room.city,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.people_outline,
                        size: 16, color: AppColors.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      strings.tr(
                        '${room.capacity} kursi',
                        '${room.capacity} seats',
                      ),
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Chips info
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoChip(
                      text: (room.roomType ?? 'classroom').toUpperCase(),
                      icon: Icons.meeting_room_outlined,
                    ),
                    _InfoChip(
                      text: room.isActive
                          ? strings.available
                          : strings.tr('Tidak Aktif', 'Inactive'),
                      icon: room.isActive
                          ? Icons.check_circle_outline
                          : Icons.cancel_outlined,
                      color:
                          room.isActive ? AppColors.secondary : AppColors.error,
                    ),
                    if (room.avgRating > 0)
                      _InfoChip(
                        text: room.avgRating.toStringAsFixed(1),
                        icon: Icons.star_outline,
                        color: Colors.amber,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // Harga
                Text(
                  '${money.format(room.hourlyRate)} / jam',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                ),
                if (room.description != null &&
                    room.description!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    room.description!,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ],
                const SizedBox(height: 16),
                // Action buttons
                if (!isAdmin)
                  FilledButton.icon(
                    onPressed: () => context.push(AppRoutes.bookingCreate
                        .replaceFirst(':roomId', room.id)),
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(strings.tr('Pesan Sekarang', 'Book Now')),
                    style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Overview Tab ────────────────────────────────────────────────────────────

class _OverviewTab extends ConsumerWidget {
  const _OverviewTab({required this.room});

  final Room room;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final money =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    final imagesValue = ref.watch(roomImagesProvider(room.id));
    final strings = AppStrings.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _DetailCard(
          title: strings.tr('Informasi Ruangan', 'Room Information'),
          children: [
            _DetailRow(
              label: strings.capacity,
              value: strings.tr(
                  '${room.capacity} orang', '${room.capacity} people'),
            ),
            _DetailRow(label: strings.city, value: room.city),
            if (room.address != null && room.address!.isNotEmpty)
              _DetailRow(label: strings.address, value: room.address!),
            _DetailRow(
                label: strings.type,
                value: (room.roomType ?? 'classroom').toUpperCase()),
            _DetailRow(
              label: strings.tr('Tarif per jam', 'Hourly Rate'),
              value: money.format(room.hourlyRate),
            ),
            if (room.dailyRate != null)
              _DetailRow(
                label: strings.tr('Tarif harian', 'Daily Rate'),
                value: money.format(room.dailyRate),
              ),
            _DetailRow(
              label: strings.tr('Persetujuan', 'Approval'),
              value: room.requiresApproval
                  ? strings.tr('Diperlukan', 'Required')
                  : strings.tr('Tidak diperlukan', 'Not required'),
            ),
            _DetailRow(
              label: strings.tr('Minimum jam', 'Minimum Hours'),
              value: strings.tr(
                '${room.minimumHours} jam',
                '${room.minimumHours} hours',
              ),
            ),
            _DetailRow(
              label: strings.tr('Buffer waktu', 'Buffer Time'),
              value: strings.tr(
                '${room.bufferMinutes} menit',
                '${room.bufferMinutes} minutes',
              ),
            ),
            if (room.avgRating > 0)
              _DetailRow(
                label: 'Rating',
                value:
                    '${room.avgRating.toStringAsFixed(1)} ★ (${room.reviewCount} ulasan)',
              ),
          ],
        ),
        const SizedBox(height: 16),
        imagesValue.when(
          loading: () => const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => const SizedBox.shrink(),
          data: (images) {
            if (images.isEmpty) return const SizedBox.shrink();
            return _DetailCard(
              title: strings.roomImages,
              children: [
                SizedBox(
                  height: 120,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: images.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) => InkWell(
                      onTap: () => showImagePreview(context, images[index]),
                      borderRadius: BorderRadius.circular(14),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          images[index],
                          width: 150,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 150,
                            height: 120,
                            color: AppColors.primaryContainer,
                            child: const Icon(
                              Icons.image_not_supported_outlined,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

// ─── Facilities Tab ──────────────────────────────────────────────────────────

class _FacilitiesTab extends ConsumerWidget {
  const _FacilitiesTab({required this.roomId, required this.isAdmin});

  final String roomId;
  final bool isAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facilitiesValue = ref.watch(roomFacilitiesProvider(roomId));
    final strings = AppStrings.of(context);

    return facilitiesValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
          child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '${strings.tr('Gagal memuat', 'Failed to load')}: $error',
              ))),
      data: (facilities) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _DetailCard(
            title: strings.tr('Fasilitas Ruangan', 'Room Facilities'),
            trailing: isAdmin
                ? TextButton.icon(
                    onPressed: () async {
                      final edited =
                          await _editFacilitiesDialog(context, facilities);
                      if (edited == null) return;
                      await ref
                          .read(roomsRepositoryProvider)
                          .saveRoomFacilities(roomId, edited);
                      ref.invalidate(roomFacilitiesProvider(roomId));
                    },
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: Text(strings.edit),
                  )
                : null,
            children: [
              if (facilities.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    isAdmin
                        ? strings.tr(
                            'Belum ada fasilitas. Tekan Edit untuk menambahkan.',
                            'No facilities yet. Tap Edit to add them.',
                          )
                        : strings.tr(
                            'Fasilitas belum tersedia.',
                            'Facilities are not available yet.',
                          ),
                    style: const TextStyle(color: AppColors.onSurfaceVariant),
                  ),
                )
              else
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children:
                      facilities.map((tag) => _FacilityChip(tag: tag)).toList(),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<List<String>?> _editFacilitiesDialog(
      BuildContext context, List<String> existing) async {
    final strings = AppStrings.of(context);
    const options = <String, String>{
      'wifi': 'WiFi',
      'ac': 'AC',
      'projector': 'Proyektor',
      'whiteboard': 'Whiteboard',
      'sound_system': 'Sound System',
      'microphone': 'Mikrofon',
      'tv': 'Smart TV',
      'parking': 'Parkir',
      'toilet': 'Toilet',
      'kitchen': 'Dapur',
      'camera': 'Kamera',
      'printer': 'Printer',
    };
    final selected = Set<String>.from(existing);

    return showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            top: 8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(strings.tr('Edit Fasilitas', 'Edit Facilities'),
                  style: Theme.of(ctx)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: options.entries.map((e) {
                  final isSelected = selected.contains(e.key);
                  final meta = _kFacilityMeta[e.key];
                  return FilterChip(
                    avatar: Icon(
                      meta?.icon ?? Icons.check,
                      size: 16,
                      color: isSelected
                          ? Colors.white
                          : AppColors.onSurfaceVariant,
                    ),
                    label: Text(e.value),
                    selected: isSelected,
                    onSelected: (_) => setState(() {
                      if (isSelected) {
                        selected.remove(e.key);
                      } else {
                        selected.add(e.key);
                      }
                    }),
                    selectedColor: AppColors.primary,
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.onSurface,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, selected.toList()),
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52)),
                child: Text(strings.save),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Facility Chip ───────────────────────────────────────────────────────────

class _FacilityChip extends StatelessWidget {
  const _FacilityChip({required this.tag});

  final String tag;

  @override
  Widget build(BuildContext context) {
    final meta = _kFacilityMeta[tag];
    final label = meta?.label ?? tag;
    final icon = meta?.icon ?? Icons.check_circle_outline;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.primary, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ─── Schedule Tab ────────────────────────────────────────────────────────────

const _kDayNames = [
  'Minggu',
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
  'Sabtu'
];

class _ScheduleTab extends ConsumerWidget {
  const _ScheduleTab({required this.roomId, required this.isAdmin});

  final String roomId;
  final bool isAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleValue = ref.watch(roomSchedulesProvider(roomId));
    final strings = AppStrings.of(context);
    // Provide an empty list while loading bookings, or handle errors silently for the calendar
    final bookingsValue =
        ref.watch(roomBookingsProvider(roomId)).valueOrNull ?? [];

    return scheduleValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(error.toString())),
      data: (schedules) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _DetailCard(
            title: strings.tr('Ketersediaan Jadwal', 'Schedule Availability'),
            children: [
              TableCalendar(
                firstDay: DateTime.now(),
                lastDay: DateTime.now().add(const Duration(days: 90)),
                focusedDay: DateTime.now(),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    // Cek apakah tanggal ini ada booking yang aktif
                    final isBooked = bookingsValue.any((b) {
                      if (b.status == 'cancelled' || b.status == 'rejected')
                        return false;
                      final bDate = b.bookingDate;
                      return bDate.year == date.year &&
                          bDate.month == date.month &&
                          bDate.day == date.day;
                    });

                    if (isBooked) {
                      return Positioned(
                        bottom: 4,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.error,
                          ),
                        ),
                      );
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.circle, size: 10, color: AppColors.error),
                  const SizedBox(width: 8),
                  Text(
                      strings.tr(
                        'Terdapat pesanan pada tanggal ini',
                        'There is a booking on this date',
                      ),
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.onSurfaceVariant)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _DetailCard(
            title: strings.tr('Jadwal Operasional', 'Operating Schedule'),
            trailing: isAdmin
                ? TextButton.icon(
                    onPressed: () async {
                      final edited = await _editSchedules(context, schedules);
                      if (edited == null) return;
                      await ref
                          .read(roomsRepositoryProvider)
                          .saveRoomSchedules(roomId, edited);
                      ref.invalidate(roomSchedulesProvider(roomId));
                    },
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: Text(strings.edit),
                  )
                : null,
            children: [
              if (schedules.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    isAdmin
                        ? strings.tr(
                            'Belum ada jadwal. Tekan Edit untuk menambahkan.',
                            'No schedule yet. Tap Edit to add one.',
                          )
                        : strings.tr(
                            'Jadwal belum tersedia.',
                            'Schedule is not available yet.',
                          ),
                    style: const TextStyle(color: AppColors.onSurfaceVariant),
                  ),
                )
              else
                for (final schedule in schedules)
                  _ScheduleRow(schedule: schedule),
            ],
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>?> _editSchedules(
    BuildContext context,
    List<Map<String, dynamic>> existing,
  ) async {
    final strings = AppStrings.of(context);
    final controller = TextEditingController(
      text: existing.isEmpty
          ? '1,08:00,17:00,false'
          : existing
              .map(
                (item) =>
                    '${item['day_of_week']},${item['open_time']},${item['close_time']},${item['is_closed']}',
              )
              .join('\n'),
    );

    return showModalBottomSheet<List<Map<String, dynamic>>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
          top: 8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.tr('Edit Jadwal', 'Edit Schedule'),
                style: Theme.of(sheetContext)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              strings.tr(
                'Format per baris: hari(0=Min,1=Sen,...),jam_buka,jam_tutup,tutup(true/false)',
                'Format per line: day(0=Sun,1=Mon,...),open_time,close_time,closed(true/false)',
              ),
              style: Theme.of(sheetContext)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 8,
              decoration: InputDecoration(
                hintText: strings.tr(
                  'Contoh:\n1,08:00,17:00,false\n2,08:00,17:00,false',
                  'Example:\n1,08:00,17:00,false\n2,08:00,17:00,false',
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                final parsed = controller.text
                    .split('\n')
                    .where((line) => line.trim().isNotEmpty)
                    .map((line) {
                  final parts = line.split(',');
                  return <String, dynamic>{
                    'day_of_week': int.tryParse(parts[0].trim()) ?? 1,
                    'open_time': parts.length > 1 ? parts[1].trim() : '08:00',
                    'close_time': parts.length > 2 ? parts[2].trim() : '17:00',
                    'is_closed':
                        parts.length > 3 ? parts[3].trim() == 'true' : false,
                  };
                }).toList();
                Navigator.pop(sheetContext, parsed);
              },
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52)),
              child: Text(strings.save),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({required this.schedule});

  final Map<String, dynamic> schedule;

  @override
  Widget build(BuildContext context) {
    final day = schedule['day_of_week'] as int? ?? 0;
    final dayName =
        day >= 0 && day < _kDayNames.length ? _kDayNames[day] : 'Hari $day';
    final isClosed = schedule['is_closed'] as bool? ?? false;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              dayName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          if (isClosed)
            const Text('Tutup', style: TextStyle(color: AppColors.error))
          else
            Text('${schedule['open_time']} - ${schedule['close_time']}'),
        ],
      ),
    );
  }
}

// ─── Bookings Tab ─────────────────────────────────────────────────────────────

class _BookingsTab extends ConsumerWidget {
  const _BookingsTab({required this.roomId});

  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsValue = ref.watch(roomBookingsProvider(roomId));

    return bookingsValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(error.toString())),
      data: (bookings) {
        if (bookings.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                AppStrings.of(context).tr(
                  'Belum ada booking untuk ruangan ini.',
                  'No bookings for this room yet.',
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, index) {
            final booking = bookings[index];
            return _BookingRow(
              booking: booking,
            );
          },
        );
      },
    );
  }
}

class _BookingRow extends StatelessWidget {
  const _BookingRow({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (booking.status.toLowerCase()) {
      'confirmed' => AppColors.secondary,
      'pending_payment' || 'pending_approval' => AppColors.tertiary,
      'cancelled' || 'rejected' => AppColors.error,
      _ => AppColors.primary,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Booking #${booking.id.substring(0, 8).toUpperCase()}',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${DateFormat('dd MMM yyyy').format(booking.bookingDate)} • ${booking.startTime} - ${booking.endTime}',
                        style:
                            const TextStyle(color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    booking.status,
                    style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              NumberFormat.currency(
                      locale: 'id_ID', symbol: 'Rp', decimalDigits: 0)
                  .format(booking.finalPrice),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Detail Card ─────────────────────────────────────────────────────────────

class _DetailCard extends StatelessWidget {
  const _DetailCard({
    required this.title,
    required this.children,
    this.trailing,
  });

  final String title;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: const [
          BoxShadow(
              color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

// ─── Detail Row ──────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Info Chip ───────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.text, required this.icon, this.color});

  final String text;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: effectiveColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: effectiveColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
                color: effectiveColor,
                fontWeight: FontWeight.w600,
                fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ─── Tab Header Delegate ──────────────────────────────────────────────────────

class _TabHeader extends SliverPersistentHeaderDelegate {
  _TabHeader(this.tabBar);

  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _TabHeader oldDelegate) => false;
}
