import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/widgets/error_card.dart';
import '../../../../booking/presentation/providers/booking_admin_providers.dart';
import '../../../../rooms/presentation/providers/rooms_providers.dart';
import '../../providers/super_admin_providers.dart';
import '../../../../../shared/presentation/widgets/image_preview_dialog.dart';

class SuperAdminRoomDetailScreen extends ConsumerWidget {
  const SuperAdminRoomDetailScreen({required this.roomId, super.key});

  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomAsync = ref.watch(platformRoomDetailProvider(roomId));
    final bookingsAsync = ref.watch(roomBookingsProvider(roomId));
    final imagesAsync = ref.watch(roomImagesProvider(roomId));
    final schedulesAsync = ref.watch(roomSchedulesProvider(roomId));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final strings = AppStrings.of(context);
    final currency =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: Text(strings.roomDetail)),
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
              clipBehavior: Clip.antiAlias,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.45)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      height: 190,
                      width: double.infinity,
                      child: item.room.previewUrl != null &&
                              item.room.previewUrl!.isNotEmpty
                          ? GestureDetector(
                              onTap: () => showImagePreview(
                                  context, item.room.previewUrl!),
                              child: Image.network(
                                item.room.previewUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const _RoomImageFallback(),
                              ),
                            )
                          : const _RoomImageFallback(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    item.room.name,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text('${strings.agencyLabel}: ${item.agencyName}',
                      style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  _Row(strings.capacity, '${item.room.capacity} orang'),
                  _Row(strings.type, item.room.roomType ?? '-'),
                  _Row(strings.city, item.room.city),
                  _Row(strings.address, item.room.address ?? '-'),
                  _Row(strings.price,
                      '${currency.format(item.room.hourlyRate)}/jam'),
                  _Row(strings.status,
                      item.room.isActive ? strings.available : strings.full),
                  if (item.facilities.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(strings.facilities,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final facility in item.facilities)
                          Chip(label: Text(facility))
                      ],
                    ),
                  ],
                ],
              ),
            ),
            imagesAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (images) {
                if (images.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.roomImages,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 112,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: images.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 10),
                          itemBuilder: (context, index) => ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              images[index],
                              width: 148,
                              height: 112,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const SizedBox(
                                width: 148,
                                height: 112,
                                child: _RoomImageFallback(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Text(strings.roomSchedule,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            schedulesAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Gagal memuat jadwal room'),
              data: (schedules) => schedules.isEmpty
                  ? const Text('Jadwal belum tersedia.')
                  : Column(
                      children: [
                        for (final schedule in schedules)
                          _Row(
                            _dayName(schedule['day_of_week'] as int? ?? 0),
                            (schedule['is_closed'] as bool? ?? false)
                                ? 'Tutup'
                                : '${schedule['open_time']} - ${schedule['close_time']}',
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: 20),
            Text(strings.bookingHistory,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
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
                            title: Text(
                                '${booking.bookingDate} • ${booking.startTime}-${booking.endTime}'),
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

String _dayName(int day) {
  const days = [
    'Minggu',
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
  ];
  return day >= 0 && day < days.length ? days[day] : 'Hari $day';
}

class _RoomImageFallback extends StatelessWidget {
  const _RoomImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primaryContainer,
      alignment: Alignment.center,
      child: const Icon(
        Icons.meeting_room_outlined,
        color: AppColors.primary,
        size: 52,
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
          SizedBox(
              width: 90,
              child: Text(label,
                  style: const TextStyle(color: AppColors.onSurfaceVariant))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
