import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/error_card.dart';
import '../../../../booking/presentation/providers/booking_admin_providers.dart';
import '../../providers/super_admin_providers.dart';

class SuperAdminRoomDetailScreen extends ConsumerWidget {
  const SuperAdminRoomDetailScreen({required this.roomId, super.key});

  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomAsync = ref.watch(platformRoomDetailProvider(roomId));
    final bookingsAsync = ref.watch(roomBookingsProvider(roomId));
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Room')),
      body: roomAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(16),
          child: ErrorCard(message: error.toString()),
        ),
        data: (item) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.room.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text('Agency: ${item.agencyName}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  _Row('Kapasitas', '${item.room.capacity} orang'),
                  _Row('Tipe', item.room.roomType ?? '-'),
                  _Row('Kota', item.room.city),
                  _Row('Alamat', item.room.address ?? '-'),
                  _Row('Harga', '${currency.format(item.room.hourlyRate)}/jam'),
                  _Row('Status', item.room.isActive ? 'Active' : 'Inactive'),
                  if (item.facilities.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text('Fasilitas', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [for (final facility in item.facilities) Chip(label: Text(facility))],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('Jadwal Room', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              'Kalender jadwal detail dapat diintegrasikan dengan modul booking agency.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            Text('Riwayat Booking', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            bookingsAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Text('Gagal memuat booking'),
              data: (bookings) => bookings.isEmpty
                  ? const Text('Belum ada booking untuk room ini')
                  : Column(
                      children: [
                        for (final booking in bookings)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.event_note_outlined),
                            title: Text('${booking.bookingDate} • ${booking.startTime}-${booking.endTime}'),
                            subtitle: Text(booking.status),
                            trailing: Text(currency.format(booking.finalPrice)),
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

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: Text(label, style: const TextStyle(color: AppColors.onSurfaceVariant))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
