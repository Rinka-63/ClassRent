import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../core/constants/app_routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_scaffold.dart';
import '../../../../../core/widgets/error_card.dart';
import '../../../../../shared/presentation/widgets/admin_nav_bar.dart';
import '../../../booking/domain/entities/booking.dart';
import '../../../booking/presentation/providers/booking_admin_providers.dart';
import '../../../rooms/domain/entities/room.dart';
import '../providers/admin_overview_providers.dart';

class BookingManagementScreen extends ConsumerWidget {
  const BookingManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsValue = ref.watch(agencyBookingsProvider);
    final roomsValue = ref.watch(adminRoomsProvider);

    return AppScaffold(
      title: 'Manajemen Pesanan',
      actions: [
        IconButton(
          onPressed: () => context.push(AppRoutes.profile),
          icon: const Icon(Icons.person_outline),
        ),
        IconButton(
          onPressed: () => context.push(AppRoutes.adminReports),
          icon: const Icon(Icons.analytics_outlined),
        ),
      ],
      bottomNavigationBar:
          const AdminNavBar(currentPath: AppRoutes.bookingManagement),
      body: bookingsValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(16),
          child: ErrorCard(message: error.toString()),
        ),
        data: (bookings) {
          final stats = _BookingStats.fromBookings(bookings);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Kelola dan pantau semua pesanan ruangan di seluruh agensi Anda.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 12),
              const _SearchBar(),
              const SizedBox(height: 12),
              _CompactStatsGrid(stats: stats),
              const SizedBox(height: 16),
              // --- Live Room Status Section ---
              Text(
                'Status Ruangan Langsung',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              roomsValue.when(
                data: (rooms) =>
                    _LiveRoomStatusList(rooms: rooms, bookings: bookings),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Gagal memuat ruangan: $e'),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pesanan Terbaru',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  TextButton(
                    onPressed: () => context.push(AppRoutes.adminCalendar),
                    child: const Text('Kalender'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (bookings.isEmpty)
                const _EmptyState()
              else
                for (final booking in bookings) ...[
                  _BookingCard(booking: booking),
                  const SizedBox(height: 12),
                ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/admin/scanner'),
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Pindai QR'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _BookingStats {
  const _BookingStats({
    required this.pending,
    required this.active,
    required this.revenueLabel,
    required this.occupiedLabel,
  });

  factory _BookingStats.fromBookings(List<Booking> bookings) {
    final pending = bookings
        .where((booking) => booking.status.toLowerCase().contains('pending'))
        .length;
    final active = bookings
        .where((booking) =>
            booking.status.toLowerCase().contains('confirm') ||
            booking.status.toLowerCase().contains('check'))
        .length;

    final validStatuses = {
      'confirmed',
      'completed',
      'checked_in',
      'checked_out'
    };
    final revenue = bookings
        .where((b) => validStatuses.contains(b.status.toLowerCase()))
        .fold<double>(0, (sum, b) => sum + b.finalPrice);

    final occupied =
        bookings.isEmpty ? 0 : (active / bookings.length * 100).round();

    return _BookingStats(
      pending: pending,
      active: active,
      revenueLabel:
          NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0)
              .format(revenue),
      occupiedLabel: '$occupied%',
    );
  }

  final int pending;
  final int active;
  final String revenueLabel;
  final String occupiedLabel;
}

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Cari pesanan...',
            prefixIcon: Icon(Icons.search),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }
}

class _CompactStatsGrid extends StatelessWidget {
  const _CompactStatsGrid({required this.stats});

  final _BookingStats stats;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.4,
      children: [
        _CompactStat(
            label: 'Menunggu',
            value: '${stats.pending}',
            color: AppColors.primary),
        _CompactStat(
            label: 'Aktif', value: '${stats.active}', color: AppColors.success),
        _CompactStat(
            label: 'Pendapatan',
            value: stats.revenueLabel,
            color: AppColors.accent),
        _CompactStat(
            label: 'Terpakai',
            value: stats.occupiedLabel,
            color: AppColors.tertiary),
      ],
    );
  }
}

class _CompactStat extends StatelessWidget {
  const _CompactStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  )),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              )),
        ],
      ),
    );
  }
}

class _BookingCard extends ConsumerWidget {
  const _BookingCard({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userName = (booking.userName?.trim().isNotEmpty ?? false)
        ? booking.userName!.trim()
        : 'Pengguna';
    final statusColor = switch (booking.status.toLowerCase()) {
      'confirmed' => AppColors.secondary,
      'pending_payment' || 'pending_approval' => AppColors.tertiary,
      'cancelled' => AppColors.error,
      _ => AppColors.primary,
    };

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/bookings/${booking.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    child: Text(userName.characters.first.toUpperCase()),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(userName,
                            style: Theme.of(context).textTheme.titleMedium),
                        Text(
                          booking.roomName ?? 'Ruangan',
                          style: const TextStyle(
                              color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  _Chip(label: booking.status, color: statusColor),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${DateFormat('dd MMM yyyy').format(booking.bookingDate)}  •  ${booking.startTime} - ${booking.endTime}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 12),
              const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

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
          style: TextStyle(color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
            'No bookings yet. Bookings will appear here once users start reserving rooms.'),
      ),
    );
  }
}

class _LiveRoomStatusList extends StatelessWidget {
  const _LiveRoomStatusList({required this.rooms, required this.bookings});

  final List<Room> rooms;
  final List<Booking> bookings;

  @override
  Widget build(BuildContext context) {
    if (rooms.isEmpty) return const Text('Belum ada ruangan.');

    // Cek booking yang statusnya checked_in
    final checkedInBookings =
        bookings.where((b) => b.status == 'checked_in').toList();

    return Column(
      children: rooms.map<Widget>((room) {
        final activeBooking =
            checkedInBookings.where((b) => b.roomId == room.id).firstOrNull;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: room.previewUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      room.previewUrl!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.meeting_room,
                        color: activeBooking != null
                            ? AppColors.error
                            : Colors.green,
                        size: 32,
                      ),
                    ),
                  )
                : Icon(
                    Icons.meeting_room,
                    color:
                        activeBooking != null ? AppColors.error : Colors.green,
                    size: 32,
                  ),
            title: Text(room.name,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: activeBooking != null
                ? Text(
                    '🔴 Sedang digunakan oleh ${activeBooking.userName ?? "Pengguna"}')
                : const Text('🟢 Tersedia',
                    style: TextStyle(color: Colors.green)),
          ),
        );
      }).toList(),
    );
  }
}
