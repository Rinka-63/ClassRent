import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/presentation/widgets/role_aware_nav_bar.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../rooms/presentation/providers/rooms_providers.dart';
import '../providers/booking_admin_providers.dart';
import '../providers/booking_flow_provider.dart';

class BookingFlowScreen extends ConsumerStatefulWidget {
  const BookingFlowScreen({required this.roomId, super.key});

  final String roomId;

  @override
  ConsumerState<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends ConsumerState<BookingFlowScreen> {
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _checkedPendingBooking = false;

  @override
  void initState() {
    super.initState();
    // Room will be initialized via the listener in build
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch room from rooms provider and auto-init the flow
    final roomAsync = ref.watch(roomDetailProvider(widget.roomId));

    return roomAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        body: Center(
          child: Text('${AppStrings.of(context).tr('Gagal', 'Error')}: $e'),
        ),
      ),
      data: (room) {
        // Initialize flow when room is loaded
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final state = ref.read(bookingFlowProvider);
          if (state.room?.id != room.id) {
            ref.read(bookingFlowProvider.notifier).init(room);
          }
          if (!_checkedPendingBooking) {
            _checkedPendingBooking = true;
            _redirectSameRoomPendingBooking();
          }
        });
        return _buildContent(context, room);
      },
    );
  }

  Widget _buildContent(BuildContext context, _) {
    final state = ref.watch(bookingFlowProvider);
    final strings = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          state.step == BookingStep.selectDate
              ? strings.tr('Pilih Jadwal', 'Choose Schedule')
              : strings.confirm,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (state.step == BookingStep.confirmDetails) {
              ref
                  .read(bookingFlowProvider.notifier)
                  .goTo(BookingStep.selectDate);
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress
            LinearProgressIndicator(
              value: (state.step.index + 1) / BookingStep.values.length,
              backgroundColor: AppColors.surfaceContainer,
              color: AppColors.primary,
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: state.step == BookingStep.selectDate
                    ? _buildStep1SelectDate()
                    : _buildStep2Confirm(state),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const RoleAwareNavBar(currentPath: ''),
    );
  }

  Future<bool> _redirectSameRoomPendingBooking() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return false;

    final repository = ref.read(bookingRepositoryProvider);
    final result = await repository.getBookingsForUser(user.id);
    final pendingBooking = result.match(
      (_) => null,
      (bookings) => bookings.where((booking) {
        return booking.roomId == widget.roomId &&
            booking.status == 'pending_payment';
      }).firstOrNull,
    );

    if (pendingBooking == null || !mounted) return false;

    final strings = AppStrings.of(context);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          strings.tr(
            'Booking belum dibayar',
            'Unpaid booking found',
          ),
        ),
        content: Text(
          strings.tr(
            'Masih ada booking untuk ruangan ini yang belum dibayar. Selesaikan pembayaran booking tersebut sebelum membuat booking baru di ruangan yang sama.',
            'There is an unpaid booking for this room. Complete that payment before creating another booking for the same room.',
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(strings.tr('Bayar Sekarang', 'Pay Now')),
          ),
        ],
      ),
    );

    if (!mounted) return true;
    context.pushReplacement(
      AppRoutes.paymentMethod.replaceFirst(':bookingId', pendingBooking.id),
    );
    return true;
  }

  Widget _buildStep1SelectDate() {
    final bookingsAsync = ref.watch(roomBookingsProvider(widget.roomId));
    final bookedDates = bookingsAsync.maybeWhen(
      data: (bookings) => bookings
          .where((booking) => _blocksBookingSlot(booking.status))
          .map((booking) => DateTime(
                booking.bookingDate.year,
                booking.bookingDate.month,
                booking.bookingDate.day,
              ))
          .toSet(),
      orElse: () => <DateTime>{},
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          AppStrings.of(context).tr('Tanggal Pemesanan', 'Booking Date'),
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.outlineVariant),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              TableCalendar<void>(
                firstDay: DateTime.now(),
                lastDay: DateTime.now().add(const Duration(days: 90)),
                focusedDay: _selectedDate ?? DateTime.now(),
                selectedDayPredicate: (day) =>
                    _selectedDate != null && isSameDay(_selectedDate, day),
                eventLoader: (day) {
                  final normalized = DateTime(day.year, day.month, day.day);
                  return bookedDates.contains(normalized)
                      ? const [null]
                      : const [];
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDate = DateTime(
                      selectedDay.year,
                      selectedDay.month,
                      selectedDay.day,
                    );
                  });
                },
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.circle,
                    size: 10,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppStrings.of(context).tr(
                        'Tanggal bertanda memiliki booking aktif.',
                        'Marked dates have active bookings.',
                      ),
                      style: const TextStyle(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          AppStrings.of(context).tr(
            'Waktu Mulai & Selesai',
            'Start & End Time',
          ),
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _TimePickerCard(
                label: AppStrings.of(context).tr('Mulai', 'Start'),
                time: _startTime,
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime:
                        _startTime ?? const TimeOfDay(hour: 8, minute: 0),
                  );
                  if (time != null) setState(() => _startTime = time);
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _TimePickerCard(
                label: AppStrings.of(context).tr('Selesai', 'End'),
                time: _endTime,
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime:
                        _endTime ?? const TimeOfDay(hour: 10, minute: 0),
                  );
                  if (time != null) setState(() => _endTime = time);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 48),
        FilledButton(
          onPressed: _selectedDate != null &&
                  _startTime != null &&
                  _endTime != null
              ? () async {
                  final handledPendingBooking =
                      await _redirectSameRoomPendingBooking();
                  if (!mounted) return;
                  if (handledPendingBooking) return;

                  final startMin = _startTime!.hour * 60 + _startTime!.minute;
                  final endMin = _endTime!.hour * 60 + _endTime!.minute;
                  if (endMin <= startMin) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppStrings.of(context).tr(
                            'Waktu selesai harus setelah waktu mulai.',
                            'End time must be after start time.',
                          ),
                        ),
                      ),
                    );
                    return;
                  }

                  // Check availability before proceeding
                  final bookingRepo = ref.read(bookingRepositoryProvider);
                  final roomBookings =
                      await bookingRepo.getBookingsForRoom(widget.roomId);
                  if (!mounted) return;

                  final hasConflict = roomBookings.match(
                    (failure) => false,
                    (bookings) {
                      return bookings.any((booking) {
                        if (!_blocksBookingSlot(booking.status)) {
                          return false;
                        }
                        if (booking.bookingDate.year != _selectedDate!.year ||
                            booking.bookingDate.month != _selectedDate!.month ||
                            booking.bookingDate.day != _selectedDate!.day) {
                          return false;
                        }

                        // Check for time overlap by converting to minutes
                        final bookingStartParts = booking.startTime.split(':');
                        final bookingEndParts = booking.endTime.split(':');
                        final bookingStartMin =
                            int.parse(bookingStartParts[0]) * 60 +
                                int.parse(bookingStartParts[1]);
                        final bookingEndMin =
                            int.parse(bookingEndParts[0]) * 60 +
                                int.parse(bookingEndParts[1]);

                        return (startMin < bookingEndMin &&
                            endMin > bookingStartMin);
                      });
                    },
                  );

                  if (hasConflict && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppStrings.of(context).tr(
                            'Jadwal ini sudah dibooking. Silakan pilih waktu lain.',
                            'This schedule is already booked. Please choose another time.',
                          ),
                        ),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    return;
                  }

                  ref
                      .read(bookingFlowProvider.notifier)
                      .setDateAndTime(_selectedDate!, _startTime!, _endTime!);
                  ref
                      .read(bookingFlowProvider.notifier)
                      .goTo(BookingStep.confirmDetails);
                }
              : null,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          child: Text(AppStrings.of(context).continueLabel),
        ),
      ],
    );
  }

  Widget _buildStep2Confirm(BookingFlowState state) {
    final money =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    final isProcessing = state.isProcessing;
    final strings = AppStrings.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Rincian Pemesanan
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.outlineVariant),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(strings.tr('Rincian Pemesanan', 'Booking Details'),
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const Divider(height: 24),
              _DetailRow(label: strings.rooms, value: state.room!.name),
              _DetailRow(
                  label: strings.tr('Tanggal', 'Date'),
                  value: DateFormat('dd MMM yyyy').format(state.selectedDate!)),
              _DetailRow(
                label: strings.time,
                value:
                    '${state.startTime!.hour.toString().padLeft(2, '0')}:${state.startTime!.minute.toString().padLeft(2, '0')} - ${state.endTime!.hour.toString().padLeft(2, '0')}:${state.endTime!.minute.toString().padLeft(2, '0')}',
              ),
              _DetailRow(
                label: strings.tr('Durasi', 'Duration'),
                value: strings.tr(
                  '${state.durationHours.toStringAsFixed(1)} jam',
                  '${state.durationHours.toStringAsFixed(1)} hours',
                ),
              ),
            ],
          ),
        ),

        // Ringkasan Pembayaran
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(strings.tr('Ringkasan Pembayaran', 'Payment Summary'),
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(strings.tr('Total Harga Dasar', 'Base Price Total')),
                  Text(money.format(state.basePrice)),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(strings.tr('Total Pembayaran', 'Total Payment'),
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  Text(money.format(state.finalPrice),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        FilledButton(
          onPressed: isProcessing ? null : () => _submitBooking(state),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          child: isProcessing
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(strings.tr('Buat Pesanan', 'Create Booking')),
        ),
      ],
    );
  }

  Future<void> _submitBooking(BookingFlowState state) async {
    ref.read(bookingFlowProvider.notifier).setProcessing(true);
    final user = ref.read(currentUserProvider);
    final payload = {
      'user_id': user?.id,
      'room_id': state.room!.id,
      'booking_date': state.selectedDate!.toIso8601String().split('T')[0],
      'start_time':
          '${state.startTime!.hour.toString().padLeft(2, '0')}:${state.startTime!.minute.toString().padLeft(2, '0')}',
      'end_time':
          '${state.endTime!.hour.toString().padLeft(2, '0')}:${state.endTime!.minute.toString().padLeft(2, '0')}',
      'base_price': state.basePrice,
      'final_price': state.finalPrice,
      'status': 'pending_payment',
    };

    final result =
        await ref.read(bookingRepositoryProvider).createBooking(payload);
    ref.read(bookingFlowProvider.notifier).setProcessing(false);

    result.match(
      (failure) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failure.message)));
      },
      (booking) {
        if (!mounted) return;
        // Go to payment screen
        context.pushReplacement(
            AppRoutes.paymentMethod.replaceFirst(':bookingId', booking.id));
      },
    );
  }
}

bool _blocksBookingSlot(String status) {
  return !{
    'cancelled',
    'rejected',
    'expired',
    'refunded',
    'draft',
  }.contains(status.toLowerCase());
}

class _TimePickerCard extends StatelessWidget {
  const _TimePickerCard(
      {required this.label, required this.time, required this.onTap});

  final String label;
  final TimeOfDay? time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.outlineVariant),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text(
              time == null
                  ? '--:--'
                  : '${time!.hour.toString().padLeft(2, '0')}:${time!.minute.toString().padLeft(2, '0')}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
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
              width: 100,
              child: Text(label,
                  style: const TextStyle(color: AppColors.onSurfaceVariant))),
          Expanded(
              child: Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
