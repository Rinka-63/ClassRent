import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../shared/presentation/widgets/role_aware_nav_bar.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/booking.dart';
import '../providers/booking_admin_providers.dart';

final userBookingsProvider = FutureProvider<List<Booking>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const [];
  
  final result = await ref.read(bookingRepositoryProvider).getBookingsForUser(user.id);
  return result.fold((l) => throw Exception(l.message), (r) => r);
});

class BookingsScreen extends ConsumerWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(userBookingsProvider);

    return AppScaffold(
      title: 'Pemesanan Saya',
      bottomNavigationBar: const RoleAwareNavBar(currentPath: AppRoutes.bookings),
      body: bookingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Terjadi kesalahan: $error')),
        data: (bookings) {
          if (bookings.isEmpty) {
            return const EmptyState(
              title: 'Belum ada pemesanan',
              message: 'Pemesanan ruangan Anda akan muncul di sini.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return _BookingItemCard(booking: booking);
            },
          );
        },
      ),
    );
  }
}

class _BookingItemCard extends ConsumerWidget {
  const _BookingItemCard({required this.booking});
  final Booking booking;

  Future<void> _cancelBooking(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.cancel_outlined, color: Colors.orange),
            SizedBox(width: 10),
            Text('Batalkan Pesanan?'),
          ],
        ),
        content: const Text(
          'Apakah Anda yakin ingin membatalkan pesanan ini? Tindakan ini tidak dapat dibatalkan.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Kembali'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final result = await ref.read(bookingRepositoryProvider).cancelBooking(booking.id);
    if (!context.mounted) return;
    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: ${failure.message}'), backgroundColor: AppColors.error),
      ),
      (_) {
        ref.invalidate(userBookingsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Text('Pesanan berhasil dibatalkan.'),
              ],
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      },
    );
  }

  Future<void> _deleteBooking(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: AppColors.error),
            SizedBox(width: 10),
            Text('Hapus Pesanan?'),
          ],
        ),
        content: const Text(
          'Pesanan yang dihapus tidak dapat dipulihkan. Lanjutkan?',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final result = await ref.read(bookingRepositoryProvider).deleteBooking(booking.id);
    if (!context.mounted) return;
    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: ${failure.message}'), backgroundColor: AppColors.error),
      ),
      (_) {
        ref.invalidate(userBookingsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.delete, color: Colors.white),
                SizedBox(width: 10),
                Text('Pesanan berhasil dihapus.'),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final money = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    final dateFormatted = DateFormat('dd MMM yyyy').format(booking.bookingDate);

    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (booking.status) {
      case 'pending_payment':
        statusColor = Colors.orange;
        statusText = 'Menunggu Pembayaran';
        statusIcon = Icons.payment_outlined;
        break;
      case 'pending_approval':
        statusColor = Colors.amber;
        statusText = 'Menunggu Persetujuan';
        statusIcon = Icons.hourglass_top_outlined;
        break;
      case 'confirmed':
        statusColor = AppColors.secondary;
        statusText = 'Berhasil';
        statusIcon = Icons.check_circle_outline;
        break;
      case 'cancelled':
      case 'rejected':
        statusColor = AppColors.error;
        statusText = booking.status == 'cancelled' ? 'Dibatalkan' : 'Ditolak';
        statusIcon = Icons.cancel_outlined;
        break;
      default:
        statusColor = AppColors.onSurfaceVariant;
        statusText = booking.status;
        statusIcon = Icons.info_outline;
    }

    final isCancellable = booking.status == 'pending_payment' || booking.status == 'pending_approval';
    final isDeletable = booking.status == 'cancelled' || booking.status == 'rejected';

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isDeletable ? AppColors.error.withValues(alpha: 0.3) : AppColors.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/bookings/${booking.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateFormatted,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 12, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                booking.roomName ?? 'Ruangan',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.schedule_outlined, size: 14, color: AppColors.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    '${booking.startTime} - ${booking.endTime}',
                    style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Pembayaran', style: TextStyle(color: AppColors.onSurfaceVariant)),
                  Text(
                    money.format(booking.finalPrice),
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                ],
              ),
              // --- Action Buttons ---
              if (booking.status == 'pending_payment') ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _cancelBooking(context, ref),
                        icon: const Icon(Icons.cancel_outlined, size: 16),
                        label: const Text('Batalkan'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange,
                          side: const BorderSide(color: Colors.orange),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: () => context.push(AppRoutes.paymentMethod.replaceFirst(':bookingId', booking.id)),
                        icon: const Icon(Icons.payment, size: 16),
                        label: const Text('Bayar Sekarang'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else if (isCancellable) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _cancelBooking(context, ref),
                    icon: const Icon(Icons.cancel_outlined, size: 16),
                    label: const Text('Batalkan Pesanan'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ] else if (isDeletable) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _deleteBooking(context, ref),
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Hapus Pesanan'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

