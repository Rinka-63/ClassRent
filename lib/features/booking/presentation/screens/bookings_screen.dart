import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_card.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../shared/presentation/widgets/role_aware_nav_bar.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/booking.dart';
import '../providers/booking_admin_providers.dart';
import 'dart:async';

final bookingFilterProvider = StateProvider<String>((ref) => 'all');
final bookingSortProvider = StateProvider<String>((ref) => 'newest');

final userBookingsProvider =
    StreamProvider.autoDispose<List<Booking>>((ref) async* {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    yield const [];
    return;
  }

  final client = ref.watch(supabaseClientProvider);
  if (client == null) {
    yield const [];
    return;
  }

  final controller = StreamController<List<Booking>>();

  final repository = ref.read(bookingRepositoryProvider);
  await repository.expirePastBookings();

  // Initial fetch
  final result = await repository.getBookingsForUser(user.id);
  final initialData = result.fold((l) => throw Exception(l.message), (r) => r);
  controller.add(initialData);
  yield* controller.stream;

  // Subscribe to realtime changes using RealtimeChannel
  final channel = client.channel('public:bookings:user_id=eq.${user.id}');
  channel
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'bookings',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: user.id,
        ),
        callback: (payload) async {
          // Refetch and yield new data on any change
          await repository.expirePastBookings();
          final newResult = await repository.getBookingsForUser(user.id);
          controller
              .add(newResult.fold((l) => throw Exception(l.message), (r) => r));
        },
      )
      .subscribe();

  ref.onDispose(() {
    channel.unsubscribe();
    controller.close();
  });
});

class BookingsScreen extends ConsumerWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(userBookingsProvider);
    final selectedFilter = ref.watch(bookingFilterProvider);
    final selectedSort = ref.watch(bookingSortProvider);
    final strings = AppStrings.of(context);

    return AppScaffold(
      title: strings.tr('Pemesanan Saya', 'My Bookings'),
      bottomNavigationBar:
          const RoleAwareNavBar(currentPath: AppRoutes.bookings),
      body: bookingsAsync.when(
        loading: () => LoadingView(
          message: strings.tr(
            'Memuat pemesanan Anda...',
            'Loading your bookings...',
          ),
        ),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(16),
          child: ErrorCard(
            message: error.toString(),
            onRetry: () => ref.invalidate(userBookingsProvider),
          ),
        ),
        data: (bookings) {
          final filteredBookings = _applyFilter(bookings, selectedFilter);
          final sortedBookings = _applySort(filteredBookings, selectedSort);

          return Column(
            children: [
              _FilterSortControls(
                selectedFilter: selectedFilter,
                selectedSort: selectedSort,
                onFilterChanged: (value) =>
                    ref.read(bookingFilterProvider.notifier).state = value,
                onSortChanged: (value) =>
                    ref.read(bookingSortProvider.notifier).state = value,
              ),
              Expanded(
                child: sortedBookings.isEmpty
                    ? EmptyState(
                        icon: Icons.event_available_outlined,
                        title: bookings.isEmpty
                            ? strings.tr(
                                'Belum ada pemesanan', 'No bookings yet')
                            : strings.tr(
                                'Tidak ada hasil filter', 'No filter results'),
                        message: bookings.isEmpty
                            ? strings.tr(
                                'Pemesanan ruangan Anda akan muncul di sini setelah booking berhasil dibuat.',
                                'Your room bookings will appear here after a booking is created.',
                              )
                            : strings.tr(
                                'Belum ada pemesanan dengan status "${_filterLabel(selectedFilter, strings)}". Ubah filter untuk melihat pesanan lain.',
                                'No bookings with status "${_filterLabel(selectedFilter, strings)}". Change the filter to view other bookings.',
                              ),
                        actionLabel: bookings.isEmpty || selectedFilter == 'all'
                            ? null
                            : strings.tr('Tampilkan semua', 'Show all'),
                        onAction: bookings.isEmpty || selectedFilter == 'all'
                            ? null
                            : () => ref
                                .read(bookingFilterProvider.notifier)
                                .state = 'all',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: sortedBookings.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final booking = sortedBookings[index];
                          return _BookingItemCard(booking: booking);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Booking> _applyFilter(List<Booking> bookings, String filter) {
    switch (filter) {
      case 'pending':
        return bookings
            .where((b) =>
                b.status == 'pending_payment' ||
                b.status == 'pending_approval' ||
                b.status == 'pending')
            .toList();
      case 'confirmed':
        return bookings.where((b) => b.status == 'confirmed').toList();
      case 'completed':
        return bookings
            .where((b) =>
                b.status == 'completed' ||
                b.status == 'checked_in' ||
                b.status == 'checked_out')
            .toList();
      case 'cancelled':
        return bookings
            .where((b) =>
                b.status == 'cancelled' ||
                b.status == 'rejected' ||
                b.status == 'expired')
            .toList();
      default:
        return bookings;
    }
  }

  List<Booking> _applySort(List<Booking> bookings, String sort) {
    final sorted = List<Booking>.from(bookings);
    switch (sort) {
      case 'newest':
        sorted.sort((a, b) {
          final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bTime.compareTo(aTime);
        });
        break;
      case 'oldest':
        sorted.sort((a, b) {
          final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return aTime.compareTo(bTime);
        });
        break;
      case 'highest':
        sorted.sort((a, b) => b.finalPrice.compareTo(a.finalPrice));
        break;
      case 'lowest':
        sorted.sort((a, b) => a.finalPrice.compareTo(b.finalPrice));
        break;
    }
    return sorted;
  }

  String _filterLabel(String filter, AppStrings strings) {
    switch (filter) {
      case 'pending':
        return strings.tr('menunggu', 'pending');
      case 'confirmed':
        return strings.tr('dikonfirmasi', 'confirmed');
      case 'completed':
        return strings.tr('selesai', 'completed');
      case 'cancelled':
        return strings.tr('dibatalkan', 'cancelled');
      default:
        return strings.all.toLowerCase();
    }
  }
}

class _BookingItemCard extends ConsumerWidget {
  const _BookingItemCard({required this.booking});
  final Booking booking;

  Future<void> _cancelBooking(BuildContext context, WidgetRef ref) async {
    final strings = AppStrings.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.cancel_outlined, color: Colors.orange),
            const SizedBox(width: 10),
            Text(strings.tr('Batalkan Pesanan?', 'Cancel Booking?')),
          ],
        ),
        content: Text(
          strings.tr(
            'Apakah Anda yakin ingin membatalkan pesanan ini? Tindakan ini tidak dapat dibatalkan.',
            'Are you sure you want to cancel this booking? This action cannot be undone.',
          ),
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(strings.tr('Kembali', 'Back')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: Text(strings.tr('Ya, Batalkan', 'Yes, Cancel')),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final result =
        await ref.read(bookingRepositoryProvider).cancelBooking(booking.id);
    if (!context.mounted) return;
    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('${strings.tr('Gagal', 'Failed')}: ${failure.message}'),
            backgroundColor: AppColors.error),
      ),
      (_) {
        ref.invalidate(userBookingsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 10),
                Text(
                  strings.tr(
                    'Pesanan berhasil dibatalkan.',
                    'Booking cancelled successfully.',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      },
    );
  }

  Future<void> _deleteBooking(BuildContext context, WidgetRef ref) async {
    final strings = AppStrings.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.delete_forever, color: AppColors.error),
            const SizedBox(width: 10),
            Text(strings.tr('Hapus Pesanan?', 'Delete Booking?')),
          ],
        ),
        content: Text(
          strings.tr(
            'Pesanan yang dihapus tidak dapat dipulihkan. Lanjutkan?',
            'Deleted bookings cannot be restored. Continue?',
          ),
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(strings.delete),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final result =
        await ref.read(bookingRepositoryProvider).deleteBooking(booking.id);
    if (!context.mounted) return;
    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('${strings.tr('Gagal', 'Failed')}: ${failure.message}'),
            backgroundColor: AppColors.error),
      ),
      (_) {
        ref.invalidate(userBookingsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.delete, color: Colors.white),
                const SizedBox(width: 10),
                Text(
                  strings.tr(
                    'Pesanan berhasil dihapus.',
                    'Booking deleted successfully.',
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final money =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    final dateFormatted = DateFormat('dd MMM yyyy').format(booking.bookingDate);

    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (booking.status) {
      case 'pending_payment':
        statusColor = Colors.orange;
        statusText = strings.tr('Menunggu Pembayaran', 'Awaiting Payment');
        statusIcon = Icons.payment_outlined;
        break;
      case 'pending_approval':
        statusColor = Colors.amber;
        statusText = strings.tr('Menunggu Persetujuan', 'Awaiting Approval');
        statusIcon = Icons.hourglass_top_outlined;
        break;
      case 'confirmed':
        statusColor = AppColors.secondary;
        statusText = strings.tr('Berhasil', 'Confirmed');
        statusIcon = Icons.check_circle_outline;
        break;
      case 'expired':
        statusColor = AppColors.onSurfaceVariant;
        statusText = strings.tr('Kadaluarsa', 'Expired');
        statusIcon = Icons.event_busy_outlined;
        break;
      case 'cancelled':
      case 'rejected':
        statusColor = AppColors.error;
        statusText = booking.status == 'cancelled'
            ? strings.tr('Dibatalkan', 'Cancelled')
            : strings.tr('Ditolak', 'Rejected');
        statusIcon = Icons.cancel_outlined;
        break;
      default:
        statusColor = AppColors.onSurfaceVariant;
        statusText = booking.status;
        statusIcon = Icons.info_outline;
    }

    final isCancellable = booking.status == 'pending_payment' ||
        booking.status == 'pending_approval';
    final isDeletable = booking.status == 'cancelled' ||
        booking.status == 'rejected' ||
        booking.status == 'expired';

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isDeletable
              ? AppColors.error.withValues(alpha: 0.3)
              : AppColors.outlineVariant,
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
                children: [
                  Expanded(
                    child: Text(
                      dateFormatted,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
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
                booking.roomName ?? strings.rooms,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.schedule_outlined,
                      size: 14, color: AppColors.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${booking.startTime} - ${booking.endTime}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.onSurfaceVariant, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _MetaRow(
                label: strings.tr('Invoice', 'Invoice'),
                value: 'INV-${booking.id.substring(0, 8).toUpperCase()}',
              ),
              if (booking.createdAt != null)
                _MetaRow(
                  label: strings.tr('Dibuat', 'Created'),
                  value: DateFormat('dd MMM yyyy, HH:mm')
                      .format(booking.createdAt!),
                ),
              _MetaRow(
                label: strings.tr('Tanggal Booking', 'Booking Date'),
                value: dateFormatted,
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      strings.tr('Total Pembayaran', 'Total Payment'),
                      style: const TextStyle(color: AppColors.onSurfaceVariant),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      money.format(booking.finalPrice),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary),
                    ),
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
                        label: Text(strings.tr('Batalkan', 'Cancel')),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange,
                          side: const BorderSide(color: Colors.orange),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          textStyle: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: () => context.push(AppRoutes.paymentMethod
                            .replaceFirst(':bookingId', booking.id)),
                        icon: const Icon(Icons.payment, size: 16),
                        label: Text(strings.tr('Bayar Sekarang', 'Pay Now')),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          textStyle: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700),
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
                    label:
                        Text(strings.tr('Batalkan Pesanan', 'Cancel Booking')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      textStyle: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
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
                    label: Text(strings.tr('Hapus Pesanan', 'Delete Booking')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      textStyle: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
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

class _FilterSortControls extends StatelessWidget {
  const _FilterSortControls({
    required this.selectedFilter,
    required this.selectedSort,
    required this.onFilterChanged,
    required this.onSortChanged,
  });

  final String selectedFilter;
  final String selectedSort;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<String> onSortChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(
              color: AppColors.outlineVariant.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          // Filter Dropdown
          Expanded(
            child: _FilterDropdown(
              label: strings.status,
              value: selectedFilter,
              options: [
                ('all', strings.all),
                ('pending', strings.tr('Pending', 'Pending')),
                ('confirmed', strings.tr('Dikonfirmasi', 'Confirmed')),
                ('completed', strings.tr('Selesai', 'Completed')),
                ('cancelled', strings.tr('Dibatalkan', 'Cancelled')),
              ],
              onChanged: onFilterChanged,
            ),
          ),
          const SizedBox(width: 12),
          // Sort Dropdown
          Expanded(
            child: _FilterDropdown(
              label: strings.sortBy,
              value: selectedSort,
              options: [
                ('newest', strings.newest),
                ('oldest', strings.oldest),
                ('highest', strings.tr('Termahal', 'Most Expensive')),
                ('lowest', strings.tr('Termurah', 'Cheapest')),
              ],
              onChanged: onSortChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<(String, String)> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              style: Theme.of(context).textTheme.bodyMedium,
              items: options
                  .map((opt) => DropdownMenuItem(
                        value: opt.$1,
                        child: Text(opt.$2),
                      ))
                  .toList(),
              onChanged: (val) {
                if (val != null) onChanged(val);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
