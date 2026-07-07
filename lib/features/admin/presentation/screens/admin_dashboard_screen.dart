import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../core/constants/app_routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_scaffold.dart';
import '../../../../features/booking/domain/entities/booking.dart';
import '../../../../features/booking/presentation/providers/booking_admin_providers.dart';
import '../../../../features/notifications/presentation/providers/notification_providers.dart';
import '../../../../features/notifications/presentation/widgets/notification_badge.dart';
import '../../../../features/rooms/domain/entities/room.dart';
import '../../../../../shared/presentation/widgets/admin_nav_bar.dart';
import '../providers/admin_overview_providers.dart';
import 'admin_withdrawal_screen.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(adminRoomsProvider);
    final bookingsAsync = ref.watch(agencyBookingsProvider);
    final unreadNotifications = ref.watch(unreadCountProvider).valueOrNull ?? 0;

    return AppScaffold(
      title: 'Dashboard',
      actions: [
        IconButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const AdminWithdrawalScreen(),
            ),
          ),
          icon: const Icon(Icons.account_balance_wallet_outlined),
          tooltip: 'Pencairan Dana',
        ),
        IconButton(
          onPressed: () => context.push(AppRoutes.notifications),
          icon: NotificationBadge(
            count: unreadNotifications,
            child: const Icon(Icons.notifications_none),
          ),
        ),
        IconButton(
          onPressed: () => context.push(AppRoutes.profile),
          icon: const Icon(Icons.person_outline),
        ),
      ],
      bottomNavigationBar: const AdminNavBar(currentPath: AppRoutes.admin),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminRoomsProvider);
          ref.invalidate(agencyBookingsProvider);
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _AdminHeroCard(
                roomsAsync: roomsAsync, bookingsAsync: bookingsAsync),
            const SizedBox(height: 16),
            _AsyncStatsGrid(
                roomsAsync: roomsAsync, bookingsAsync: bookingsAsync),
            const SizedBox(height: 20),
            _BookingAnalyticsCard(
                roomsAsync: roomsAsync, bookingsAsync: bookingsAsync),
            const SizedBox(height: 20),
            _SectionHeader(
              title: 'Ruangan Terbaru',
              actionLabel: 'Lihat semua',
              onTap: () => context.push(AppRoutes.roomManagement),
            ),
            const SizedBox(height: 12),
            roomsAsync.when(
              data: (rooms) => rooms.isEmpty
                  ? const _EmptyRoomPanel()
                  : Column(
                      children: rooms.take(5).map(_RoomCard.new).toList(),
                    ),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, _) => Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(error.toString(),
                    style: const TextStyle(color: AppColors.error)),
              ),
            ),
            const SizedBox(height: 20),
            const _QuickActionsCard(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _AdminHeroCard extends StatelessWidget {
  const _AdminHeroCard({
    required this.roomsAsync,
    required this.bookingsAsync,
  });

  final AsyncValue<List<Room>> roomsAsync;
  final AsyncValue<List<Booking>> bookingsAsync;

  @override
  Widget build(BuildContext context) {
    final activeRooms =
        (roomsAsync.valueOrNull ?? []).where((room) => room.isActive).length;
    final pendingBookings = (bookingsAsync.valueOrNull ?? [])
        .where((booking) => booking.status.toLowerCase().contains('pending'))
        .length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xff153f9f)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A2354C5),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.dashboard_customize_outlined,
                    color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Pusat Operasional Agency',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Pantau ruangan, pesanan, dan performa harian dalam satu layar yang siap ditindaklanjuti.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.84),
                  height: 1.45,
                ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeroPill(
                  icon: Icons.meeting_room_outlined,
                  label: '$activeRooms ruang aktif'),
              _HeroPill(
                  icon: Icons.hourglass_bottom_outlined,
                  label: '$pendingBookings menunggu'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

// ─── Async Stats Grid ────────────────────────────────────────────────────────

class _AsyncStatsGrid extends StatelessWidget {
  const _AsyncStatsGrid({
    required this.roomsAsync,
    required this.bookingsAsync,
  });

  final AsyncValue<List<Room>> roomsAsync;
  final AsyncValue<List<Booking>> bookingsAsync;

  @override
  Widget build(BuildContext context) {
    final currency =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    final rooms = roomsAsync.valueOrNull ?? [];
    final bookings = bookingsAsync.valueOrNull ?? [];

    final totalBookings = bookings.length;
    final availableRooms = rooms.where((r) => r.isActive).length;
    final pendingBookings = bookings
        .where((b) => b.status.toLowerCase().contains('pending'))
        .length;
    final totalRevenue = bookings
        .where((b) =>
            b.status == 'confirmed' ||
            b.status == 'completed' ||
            b.status == 'checked_in' ||
            b.status == 'checked_out')
        .fold<double>(0, (sum, b) => sum + b.finalPrice);

    final tiles = [
      _StatTile(
        title: 'Total Booking',
        value: totalBookings.toString(),
        icon: Icons.calendar_month_outlined,
        isLoading: roomsAsync.isLoading || bookingsAsync.isLoading,
      ),
      _StatTile(
        title: 'Ruangan Aktif',
        value: availableRooms.toString(),
        icon: Icons.meeting_room_outlined,
        isLoading: roomsAsync.isLoading,
      ),
      _StatTile(
        title: 'Total Pendapatan',
        value: totalRevenue > 0 ? currency.format(totalRevenue) : 'Rp 0',
        icon: Icons.payments_outlined,
        isLoading: bookingsAsync.isLoading,
      ),
      _StatTile(
        title: 'Menunggu Konfirmasi',
        value: pendingBookings.toString(),
        icon: Icons.hourglass_bottom_outlined,
        isLoading: bookingsAsync.isLoading,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 720 ? 4 : 2;
        return GridView.builder(
          itemCount: tiles.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisExtent: 150,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (_, index) => tiles[index],
        );
      },
    );
  }
}

// ─── Stat Tile ───────────────────────────────────────────────────────────────

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.title,
    required this.value,
    required this.icon,
    this.isLoading = false,
  });

  final String title;
  final String value;
  final IconData icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: isLoading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(icon, color: AppColors.primary),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  isLoading ? '...' : value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Booking Analytics Card ──────────────────────────────────────────────────

class _BookingAnalyticsCard extends StatelessWidget {
  const _BookingAnalyticsCard({
    required this.roomsAsync,
    required this.bookingsAsync,
  });

  final AsyncValue<List<Room>> roomsAsync;
  final AsyncValue<List<Booking>> bookingsAsync;

  @override
  Widget build(BuildContext context) {
    final rooms = roomsAsync.valueOrNull ?? [];
    final bookings = bookingsAsync.valueOrNull ?? [];

    // Hitung booking per room - hanya status valid
    final validStatuses = {
      'confirmed',
      'completed',
      'checked_in',
      'checked_out'
    };
    final bookingCountByRoom = <String, int>{};
    for (final b in bookings) {
      if (validStatuses.contains(b.status.toLowerCase())) {
        bookingCountByRoom[b.roomId] = (bookingCountByRoom[b.roomId] ?? 0) + 1;
      }
    }

    final maxCount = bookingCountByRoom.values.isEmpty
        ? 1
        : bookingCountByRoom.values.reduce((a, b) => a > b ? a : b);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Booking per Ruangan',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Semua waktu',
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: rooms.isEmpty
                ? const Center(child: Text('Belum ada ruangan'))
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: rooms.take(6).map((room) {
                      final count = bookingCountByRoom[room.id] ?? 0;
                      final ratio = maxCount > 0 ? count / maxCount : 0.1;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                count.toString(),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                height:
                                    (90 * ratio.clamp(0.05, 1.0)).toDouble(),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                room.name.split(' ').first,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Section Header ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onTap,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        TextButton(onPressed: onTap, child: Text(actionLabel)),
      ],
    );
  }
}

// ─── Room Card ───────────────────────────────────────────────────────────────

class _RoomCard extends StatelessWidget {
  const _RoomCard(this.room);

  final Room room;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.primaryContainer.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(14),
          ),
          child:
              const Icon(Icons.meeting_room_outlined, color: AppColors.primary),
        ),
        title: Text(
          room.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${(room.roomType ?? 'classroom').toUpperCase()} • ${room.city} • ${room.capacity} kursi',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppColors.onSurfaceVariant),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: room.isActive
                    ? AppColors.secondary.withValues(alpha: 0.12)
                    : AppColors.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                room.isActive ? 'Aktif' : 'Nonaktif',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: room.isActive ? AppColors.secondary : AppColors.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty Room Panel ─────────────────────────────────────────────────────────

class _EmptyRoomPanel extends StatelessWidget {
  const _EmptyRoomPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        children: [
          const Icon(Icons.meeting_room_outlined,
              size: 48, color: AppColors.onSurfaceVariant),
          const SizedBox(height: 12),
          Text('Belum ada ruangan',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            'Gunakan Room Management untuk menambahkan ruangan pertama.',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ─── Quick Actions Card ───────────────────────────────────────────────────────

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aksi Cepat',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => context.push(AppRoutes.roomManagement),
            icon: const Icon(Icons.add),
            label: const Text('Tambah Ruangan Baru'),
            style:
                FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => context.push(AppRoutes.bookingManagement),
            icon: const Icon(Icons.book_outlined),
            label: const Text('Kelola Booking'),
            style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48)),
          ),
        ],
      ),
    );
  }
}
