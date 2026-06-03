import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../shared/presentation/widgets/admin_nav_bar.dart';
import '../providers/admin_overview_providers.dart';
import '../../../booking/presentation/providers/booking_admin_providers.dart';

class AdminCalendarScreen extends ConsumerWidget {
  const AdminCalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsValue = ref.watch(agencyBookingsProvider);
    final roomsValue = ref.watch(adminRoomsProvider);

    return AppScaffold(
      title: 'Schedule',
      actions: [
        IconButton(
          onPressed: () => context.push(AppRoutes.profile),
          icon: const Icon(Icons.person_outline),
        ),
      ],
      bottomNavigationBar: const AdminNavBar(currentPath: AppRoutes.adminCalendar),
      body: bookingsValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (bookings) => roomsValue.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text(error.toString())),
          data: (rooms) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _CalendarHeader(
                bookingCount: bookings.length,
                roomCount: rooms.length,
              ),
              const SizedBox(height: 16),
              _WeekStrip(),
              const SizedBox(height: 16),
              for (final booking in bookings.take(8)) ...[
                _EventCard(
                  title: booking.roomId,
                  subtitle: '${booking.startTime} - ${booking.endTime}',
                  color: AppColors.primary,
                ),
                const SizedBox(height: 12),
              ],
              if (bookings.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No schedule data yet. Once bookings exist, they will appear here.'),
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _CalendarHeader extends StatelessWidget {
  const _CalendarHeader({
    required this.bookingCount,
    required this.roomCount,
  });

  final int bookingCount;
  final int roomCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Monthly Schedule', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text('$bookingCount bookings / $roomCount rooms'),
            ],
          ),
          const _RangeChip(label: 'Monthly'),
        ],
      ),
    );
  }
}

class _WeekStrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: Row(
        children: List.generate(
          7,
          (index) => Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Container(
                decoration: BoxDecoration(
                  color: index == 2 ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('D$index', style: TextStyle(color: index == 2 ? Colors.white : AppColors.onSurfaceVariant)),
                    const SizedBox(height: 6),
                    Text('${12 + index}', style: TextStyle(color: index == 2 ? Colors.white : AppColors.onSurface)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 52,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(subtitle),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label),
    );
  }
}
