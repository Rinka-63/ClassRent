import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../rooms/presentation/providers/rooms_providers.dart';
import '../../domain/entities/booking.dart';
import '../providers/booking_admin_providers.dart';
import 'bookings_screen.dart';

class BookingDetailScreen extends ConsumerWidget {
  const BookingDetailScreen({required this.bookingId, super.key});

  final String bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userBookingsAsync = ref.watch(userBookingsProvider);
    final agencyBookingsAsync = ref.watch(agencyBookingsProvider);

    final isLoading = userBookingsAsync.isLoading || agencyBookingsAsync.isLoading;
    final hasError = userBookingsAsync.hasError && agencyBookingsAsync.hasError;
    final error = userBookingsAsync.error ?? agencyBookingsAsync.error;

    if (isLoading) {
      return const AppScaffold(
        title: 'Invoice & Tiket',
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (hasError) {
      return AppScaffold(
        title: 'Invoice & Tiket',
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Terjadi kesalahan:\n$error', textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    final userBookings = userBookingsAsync.valueOrNull ?? [];
    final agencyBookings = agencyBookingsAsync.valueOrNull ?? [];
    final allBookings = [...userBookings, ...agencyBookings];
    final booking = allBookings.where((b) => b.id == bookingId).firstOrNull;
    final isAdminView = agencyBookings.any((b) => b.id == bookingId) && !userBookings.any((b) => b.id == bookingId);

    return AppScaffold(
      title: 'Invoice & Tiket',
      body: booking == null || booking.id.isEmpty
          ? const Center(child: Text('Pemesanan tidak ditemukan'))
          : _InvoiceContent(booking: booking, isAdminView: isAdminView),
    );
  }
}

class _InvoiceContent extends ConsumerWidget {
  const _InvoiceContent({required this.booking, this.isAdminView = false});

  final Booking booking;
  final bool isAdminView;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomAsync = ref.watch(roomDetailProvider(booking.roomId));
    final money = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    final dateFormatter = DateFormat('dd MMM yyyy', 'id_ID');

    final isConfirmed = booking.status.toLowerCase() == 'confirmed';
    final isPending = booking.status.toLowerCase() == 'pending_payment' || booking.status.toLowerCase() == 'pending_approval';

    final statusColor = switch (booking.status.toLowerCase()) {
      'confirmed' => Colors.green.shade600,
      'pending_payment' || 'pending_approval' => Colors.orange.shade600,
      'cancelled' || 'rejected' => AppColors.error,
      _ => AppColors.onSurfaceVariant,
    };

    final statusIcon = switch (booking.status.toLowerCase()) {
      'confirmed' => Icons.check_circle_outline,
      'pending_payment' || 'pending_approval' => Icons.schedule,
      'cancelled' || 'rejected' => Icons.cancel_outlined,
      _ => Icons.info_outline,
    };

    final statusText = switch (booking.status.toLowerCase()) {
      'confirmed' => 'LUNAS & DIKONFIRMASI',
      'pending_payment' => 'MENUNGGU PEMBAYARAN',
      'pending_approval' => 'MENUNGGU PERSETUJUAN',
      'cancelled' => 'DIBATALKAN',
      'rejected' => 'DITOLAK',
      _ => booking.status.toUpperCase(),
    };

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      children: [
        // Status Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: statusColor.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusText,
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID Pesanan: ${booking.id.substring(0, 8).toUpperCase()}',
                      style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Ticket / Invoice Card
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Ticket Header - QR Code
              if (isConfirmed && !isAdminView) ...[
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.05),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'E-Ticket Check-In / Out',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: QrImageView(
                          data: 'CLASSRENT-CHECKIN-${booking.id}',
                          version: QrVersions.auto,
                          size: 180.0,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Tunjukkan kode QR ini kepada resepsionis',
                        style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ] else if (isPending) ...[
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: const Center(
                    child: Column(
                      children: [
                        Icon(Icons.hourglass_empty, size: 48, color: Colors.orange),
                        SizedBox(height: 12),
                        Text(
                          'Selesaikan pembayaran untuk\nmendapatkan E-Ticket',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Dashed Separator
              Row(
                children: [
                  SizedBox(
                    height: 20,
                    width: 10,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: const BorderRadius.horizontal(right: Radius.circular(10)),
                      ),
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Flex(
                          direction: Axis.horizontal,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          mainAxisSize: MainAxisSize.max,
                          children: List.generate(
                            (constraints.constrainWidth() / 10).floor(),
                            (index) => SizedBox(
                              width: 5,
                              height: 1.5,
                              child: DecoratedBox(decoration: BoxDecoration(color: Colors.grey.shade300)),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(
                    height: 20,
                    width: 10,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),

              // Room & Schedule Details
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('DETAIL RUANGAN', style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
                    const SizedBox(height: 12),
                    roomAsync.when(
                      loading: () => const SizedBox(
                        height: 60,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (e, _) => SizedBox(
                        height: 60,
                        child: Text('Gagal memuat info ruangan: $e', style: const TextStyle(color: AppColors.error)),
                      ),
                      data: (room) => Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.meeting_room, color: AppColors.primary),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(room.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                                const SizedBox(height: 4),
                                Text(
                                  '${room.city} • Kapasitas ${room.capacity} org',
                                  style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text('JADWAL', style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _ScheduleBox(
                            label: 'Check-In',
                            date: dateFormatter.format(booking.bookingDate),
                            time: booking.startTime,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ScheduleBox(
                            label: 'Check-Out',
                            date: dateFormatter.format(booking.bookingDate),
                            time: booking.endTime,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Divider
              Divider(height: 1, color: Colors.grey.shade200),

              // Payment Summary
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('RINCIAN PEMBAYARAN', style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
                    const SizedBox(height: 16),
                    _SummaryRow(label: 'Total Harga Ruangan', value: money.format(booking.basePrice)),
                    const SizedBox(height: 8),
                    if (booking.basePrice > booking.finalPrice) ...[
                      _SummaryRow(
                        label: 'Diskon / Voucher',
                        value: '- ${money.format(booking.basePrice - booking.finalPrice)}',
                        isDiscount: true,
                      ),
                      const SizedBox(height: 16),
                    ],
                    const Divider(),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Pembayaran', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                        Text(
                          money.format(booking.finalPrice),
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Download / Action Buttons
        if (isConfirmed)
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Invoice berhasil diunduh ke perangkat Anda.')),
              );
            },
            icon: const Icon(Icons.download),
            label: const Text('Unduh PDF Invoice'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: AppColors.primary),
            ),
          ),
      ],
    );
  }
}

class _ScheduleBox extends StatelessWidget {
  const _ScheduleBox({required this.label, required this.date, required this.time});

  final String label;
  final String date;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12)),
          const SizedBox(height: 4),
          Text(date, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 2),
          Text(time, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.primary)),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value, this.isDiscount = false});

  final String label;
  final String value;
  final bool isDiscount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13)),
        Text(
          value,
          style: TextStyle(
            fontWeight: isDiscount ? FontWeight.w700 : FontWeight.w600,
            fontSize: 13,
            color: isDiscount ? Colors.green.shade600 : AppColors.onSurface,
          ),
        ),
      ],
    );
  }
}
