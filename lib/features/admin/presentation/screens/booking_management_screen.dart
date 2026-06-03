import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/error_card.dart';
import '../../../../shared/presentation/widgets/admin_nav_bar.dart';
import '../../../booking/domain/entities/booking.dart';
import '../../../booking/presentation/providers/booking_admin_providers.dart';

class BookingManagementScreen extends ConsumerWidget {
  const BookingManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsValue = ref.watch(agencyBookingsProvider);

    return AppScaffold(
      title: 'Booking Management',
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
      bottomNavigationBar: const AdminNavBar(currentPath: AppRoutes.bookingManagement),
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
                'Manage and monitor all room reservations across your agency.',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              const _SearchBar(),
              const SizedBox(height: 16),
              _MetricCard(label: 'TOTAL PENDING', value: stats.pending.toString(), accent: AppColors.primary),
              const SizedBox(height: 12),
              _MetricCard(label: 'ACTIVE BOOKINGS', value: stats.active.toString(), accent: AppColors.secondary),
              const SizedBox(height: 12),
              _MetricCard(label: 'REVENUE TODAY', value: stats.revenueLabel, accent: AppColors.primaryContainer),
              const SizedBox(height: 12),
              _MetricCard(label: 'ROOMS OCCUPIED', value: stats.occupiedLabel, accent: AppColors.tertiary),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Bookings',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  TextButton(
                    onPressed: () => context.push(AppRoutes.adminCalendar),
                    child: const Text('Calendar'),
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
    final pending = bookings.where((booking) => booking.status.toLowerCase().contains('pending')).length;
    final active = bookings.where((booking) => booking.status.toLowerCase().contains('confirm') || booking.status.toLowerCase().contains('check')).length;
    final revenue = bookings.fold<double>(0, (sum, booking) => sum + booking.finalPrice);
    final occupied = bookings.isEmpty ? 0 : (active / bookings.length * 100).round();

    return _BookingStats(
      pending: pending,
      active: active,
      revenueLabel: NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(revenue),
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
            hintText: 'Search bookings...',
            prefixIcon: Icon(Icons.search),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (booking.status.toLowerCase()) {
      'confirmed' => AppColors.secondary,
      'pending_payment' || 'pending_approval' => AppColors.tertiary,
      'cancelled' => AppColors.error,
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
                CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  child: Text(booking.userId.characters.first.toUpperCase()),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Booking ${booking.id.substring(0, 8)}', style: Theme.of(context).textTheme.titleMedium),
                      Text(
                        booking.roomId,
                        style: const TextStyle(color: AppColors.onSurfaceVariant),
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
            Row(
              children: [
                FilledButton(
                  onPressed: () {},
                  child: const Text('Confirm Payment'),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.visibility_outlined),
                ),
              ],
            ),
          ],
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
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
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
        child: Text('No bookings yet. Bookings will appear here once users start reserving rooms.'),
      ),
    );
  }
}
