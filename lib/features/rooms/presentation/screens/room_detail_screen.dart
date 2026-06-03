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
import '../../../../shared/presentation/widgets/role_aware_nav_bar.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../booking/presentation/providers/booking_admin_providers.dart';
import '../../domain/entities/room.dart';
import '../../../booking/domain/entities/booking.dart';
import '../providers/rooms_providers.dart';

class RoomDetailScreen extends ConsumerWidget {
  const RoomDetailScreen({required this.roomId, super.key});

  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomValue = ref.watch(roomDetailProvider(roomId));
    final user = ref.watch(currentUserProvider);
    final isAdmin = user?.role == UserRole.admin || user?.role == UserRole.superAdmin;

    return AppScaffold(
      title: 'Room Detail',
      actions: [
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
                  child: _RoomHero(room: room),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _TabHeader(
                  const TabBar(
                    tabs: [
                      Tab(text: 'Overview'),
                      Tab(text: 'Facilities'),
                      Tab(text: 'Schedule'),
                      Tab(text: 'Bookings'),
                    ],
                    labelColor: AppColors.primary,
                    indicatorColor: AppColors.primary,
                  ),
                ),
              ),
            ],
            body: TabBarView(
              children: [
                _OverviewTab(room: room),
                _FacilitiesTab(roomId: room.id, isAdmin: isAdmin),
                _ScheduleTab(roomId: room.id, isAdmin: isAdmin),
                _BookingsTab(roomId: room.id, isAdmin: isAdmin),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoomHero extends StatelessWidget {
  const _RoomHero({required this.room});

  final Room room;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.14),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.meeting_room_outlined, size: 72, color: AppColors.primary),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(room.name, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 6),
                Text('${room.city} • ${room.capacity} seats'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Chip(text: room.roomType == null ? 'CLASSROOM' : room.roomType!.toUpperCase()),
                    _Chip(text: room.isActive ? 'ACTIVE' : 'INACTIVE'),
                    _Chip(text: money.format(room.hourlyRate)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(room.description ?? 'Room description will come from Supabase.'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    FilledButton.icon(
                      onPressed: () => context.push(AppRoutes.bookingCreate),
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: const Text('Start Booking'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit Room'),
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

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.room});

  final Room room;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _DetailCard(
          title: 'Room Information',
          children: [
            _DetailRow(label: 'Capacity', value: '${room.capacity} people'),
            _DetailRow(label: 'City', value: room.city),
            _DetailRow(label: 'Hourly rate', value: NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(room.hourlyRate)),
            _DetailRow(label: 'Approval', value: room.requiresApproval ? 'Required' : 'Not required'),
          ],
        ),
      ],
    );
  }
}

class _FacilitiesTab extends ConsumerWidget {
  const _FacilitiesTab({required this.roomId, required this.isAdmin});

  final String roomId;
  final bool isAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facilitiesValue = ref.watch(roomFacilitiesProvider(roomId));

    return facilitiesValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(error.toString())),
      data: (facilities) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _DetailCard(
            title: 'Facilities',
            trailing: isAdmin
                ? TextButton.icon(
                    onPressed: () async {
                      final edited = await _editFacilities(context, facilities);
                      if (edited == null) return;
                      await ref.read(roomsRepositoryProvider).saveRoomFacilities(roomId, edited);
                      ref.invalidate(roomFacilitiesProvider(roomId));
                    },
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit'),
                  )
                : null,
            children: [
              if (facilities.isEmpty)
                const Text('No facilities yet.')
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: facilities.map((item) => _Chip(text: item)).toList(),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<List<String>?> _editFacilities(BuildContext context, List<String> existing) async {
    final controller = TextEditingController(text: existing.join(', '));
    return showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Edit Facilities', style: Theme.of(sheetContext).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Separate by comma, e.g. Projector, AC, WiFi',
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                final parsed = controller.text
                    .split(',')
                    .map((item) => item.trim())
                    .where((item) => item.isNotEmpty)
                    .toList();
                Navigator.pop(sheetContext, parsed);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleTab extends ConsumerWidget {
  const _ScheduleTab({required this.roomId, required this.isAdmin});

  final String roomId;
  final bool isAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleValue = ref.watch(roomSchedulesProvider(roomId));

    return scheduleValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(error.toString())),
      data: (schedules) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _DetailCard(
            title: 'Schedule',
            trailing: isAdmin
                ? TextButton.icon(
                    onPressed: () async {
                      final edited = await _editSchedules(context, schedules);
                      if (edited == null) return;
                      await ref.read(roomsRepositoryProvider).saveRoomSchedules(roomId, edited);
                      ref.invalidate(roomSchedulesProvider(roomId));
                    },
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit'),
                  )
                : null,
            children: [
              if (schedules.isEmpty)
                const Text('No schedule yet.')
              else
                for (final schedule in schedules)
                  _DetailRow(
                    label: 'Day ${schedule['day_of_week']}',
                    value: '${schedule['open_time']} - ${schedule['close_time']}',
                  ),
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
    final controller = TextEditingController(
      text: existing.isEmpty
          ? '1,08:00,17:00,false'
          : existing
              .map(
                (item) => '${item['day_of_week']},${item['open_time']},${item['close_time']},${item['is_closed']}',
              )
              .join('\n'),
    );

    return showModalBottomSheet<List<Map<String, dynamic>>>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Edit Schedule', style: Theme.of(sheetContext).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'Format: day_of_week,08:00,17:00,false',
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                final parsed = controller.text
                    .split('\n')
                    .where((line) => line.trim().isNotEmpty)
                    .map((line) {
                      final parts = line.split(',');
                      return <String, dynamic>{
                        'day_of_week': int.parse(parts[0].trim()),
                        'open_time': parts[1].trim(),
                        'close_time': parts[2].trim(),
                        'is_closed': parts.length > 3 ? parts[3].trim() == 'true' : false,
                      };
                    })
                    .toList();
                Navigator.pop(sheetContext, parsed);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingsTab extends ConsumerWidget {
  const _BookingsTab({required this.roomId, required this.isAdmin});

  final String roomId;
  final bool isAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsValue = ref.watch(roomBookingsProvider(roomId));

    return bookingsValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(error.toString())),
      data: (bookings) {
        if (bookings.isEmpty) {
          return const Center(child: Text('No bookings for this room yet.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, index) {
            final booking = bookings[index];
            return _BookingRow(
              booking: booking,
              isAdmin: isAdmin,
              onConfirm: () async {
                await ref.read(bookingRepositoryProvider).updateBooking(
                  booking.id,
                  {'status': 'confirmed'},
                );
                ref.invalidate(roomBookingsProvider(roomId));
              },
              onCancel: () async {
                await ref.read(bookingRepositoryProvider).cancelBooking(booking.id);
                ref.invalidate(roomBookingsProvider(roomId));
              },
            );
          },
        );
      },
    );
  }
}

class _BookingRow extends StatelessWidget {
  const _BookingRow({
    required this.booking,
    required this.isAdmin,
    required this.onConfirm,
    required this.onCancel,
  });

  final Booking booking;
  final bool isAdmin;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Booking ${booking.id.substring(0, 8)}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('${booking.bookingDate.toIso8601String().split('T').first} ${booking.startTime} - ${booking.endTime}'),
            const SizedBox(height: 8),
            Text('Status: ${booking.status}'),
            if (isAdmin) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  FilledButton(onPressed: onConfirm, child: const Text('Confirm')),
                  const SizedBox(width: 8),
                  OutlinedButton(onPressed: onCancel, child: const Text('Cancel')),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

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
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.onSurfaceVariant)),
          Flexible(
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

class _Chip extends StatelessWidget {
  const _Chip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text),
    );
  }
}

class _TabHeader extends SliverPersistentHeaderDelegate {
  _TabHeader(this.tabBar);

  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: Theme.of(context).scaffoldBackgroundColor, child: tabBar);
  }

  @override
  bool shouldRebuild(covariant _TabHeader oldDelegate) => false;
}
