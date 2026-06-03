import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../features/rooms/domain/entities/room.dart';
import '../../../../shared/presentation/widgets/admin_nav_bar.dart';
import '../providers/admin_overview_providers.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(adminRoomsProvider);

    return AppScaffold(
      title: 'Dashboard',
      actions: [
        IconButton(
          onPressed: () => context.push(AppRoutes.notifications),
          icon: const Icon(Icons.notifications_none),
        ),
        IconButton(
          onPressed: () => context.push(AppRoutes.profile),
          icon: const Icon(Icons.person_outline),
        ),
      ],
      bottomNavigationBar: const AdminNavBar(currentPath: AppRoutes.admin),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          roomsAsync.when(
            data: (rooms) {
              final totals = _DashboardTotals.fromRooms(rooms);
              return Column(
                children: [
                  _StatsGrid(totals: totals),
                  const SizedBox(height: 20),
                  _BookingAnalyticsCard(rooms: rooms),
                  const SizedBox(height: 20),
                  _SectionHeader(
                    title: 'Recent Rooms',
                    actionLabel: 'View all',
                    onTap: () => context.push(AppRoutes.roomManagement),
                  ),
                  const SizedBox(height: 12),
                  if (rooms.isEmpty)
                    const _EmptyRoomPanel()
                  else
                    ...rooms.take(5).map(_RoomCard.new),
                  const SizedBox(height: 20),
                  const _QuickActionsCard(),
                ],
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stackTrace) => Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Text(error.toString(), style: const TextStyle(color: AppColors.error)),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardTotals {
  const _DashboardTotals({
    required this.totalBookings,
    required this.availableSpaces,
    required this.revenue,
    required this.pendingPayments,
  });

  factory _DashboardTotals.fromRooms(List<Room> rooms) {
    final totalRooms = rooms.length;
    final availableSpaces = rooms.where((room) => room.isActive).length;
    final revenue = rooms.fold<double>(0, (sum, room) => sum + (room.hourlyRate * 4));
    final pendingPayments = rooms.where((room) => room.requiresApproval).length;
    return _DashboardTotals(
      totalBookings: totalRooms * 18,
      availableSpaces: availableSpaces,
      revenue: revenue,
      pendingPayments: pendingPayments,
    );
  }

  final int totalBookings;
  final int availableSpaces;
  final double revenue;
  final int pendingPayments;
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.totals});

  final _DashboardTotals totals;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    final tiles = [
      _StatTile(
        title: 'Total Bookings',
        value: totals.totalBookings.toString(),
        icon: Icons.calendar_month_outlined,
      ),
      _StatTile(
        title: 'Available Spaces',
        value: totals.availableSpaces.toString(),
        icon: Icons.meeting_room_outlined,
      ),
      _StatTile(
        title: 'Revenue',
        value: currency.format(totals.revenue),
        icon: Icons.payments_outlined,
      ),
      _StatTile(
        title: 'Pending Payments',
        value: totals.pendingPayments.toString(),
        icon: Icons.hourglass_bottom_outlined,
      ),
    ];

    return GridView.builder(
      itemCount: tiles.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 136,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (_, index) => tiles[index],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

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
            child: Icon(icon, color: AppColors.primary),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
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

class _BookingAnalyticsCard extends StatelessWidget {
  const _BookingAnalyticsCard({required this.rooms});

  final List<Room> rooms;

  @override
  Widget build(BuildContext context) {
    final maxCapacity = rooms.isEmpty ? 1 : rooms.map((room) => room.capacity).reduce((a, b) => a > b ? a : b);
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Booking Analytics',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                'This Month',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final room in rooms.take(6))
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: 100 * (room.capacity / maxCapacity).clamp(0.3, 1.0),
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
                  ),
                if (rooms.isEmpty)
                  const Expanded(
                    child: Center(child: Text('No rooms yet')),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        TextButton(onPressed: onTap, child: Text(actionLabel)),
      ],
    );
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard(this.room);

  final Room room;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 148,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.14),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: const Icon(Icons.meeting_room_outlined, size: 54, color: AppColors.primary),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        room.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    _StatusChip(
                      label: room.isActive ? 'Active' : 'Inactive',
                      color: room.isActive ? AppColors.primary : AppColors.error,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                      room.roomType == null ? 'ROOM' : room.roomType!.toUpperCase(),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _InfoPill(icon: Icons.people_outline, text: '${room.capacity} seats'),
                    const SizedBox(width: 8),
                    _InfoPill(icon: Icons.location_on_outlined, text: room.city),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(room.hourlyRate),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Row(
                      children: [
                        IconButton(onPressed: () {}, icon: const Icon(Icons.edit_outlined)),
                        IconButton(onPressed: () {}, icon: const Icon(Icons.history_outlined)),
                      ],
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

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

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
          Text(text, style: Theme.of(context).textTheme.labelMedium),
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
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

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
          const Icon(Icons.meeting_room_outlined, size: 48, color: AppColors.onSurfaceVariant),
          const SizedBox(height: 12),
          Text('No rooms available yet', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            'Use Room Management to add the first room for this agency.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

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
            'Quick Actions',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => context.push(AppRoutes.roomManagement),
            icon: const Icon(Icons.add),
            label: const Text('Add New Room'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          ),
        ],
      ),
    );
  }
}
