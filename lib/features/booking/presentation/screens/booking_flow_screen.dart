import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/presentation/widgets/role_aware_nav_bar.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../rooms/presentation/providers/rooms_providers.dart';
import '../providers/booking_admin_providers.dart';
import '../providers/booking_flow_provider.dart';
import '../providers/coupon_providers.dart';

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

  final _couponController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Room will be initialized via the listener in build
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch room from rooms provider and auto-init the flow
    final roomAsync = ref.watch(roomDetailProvider(widget.roomId));
    
    return roomAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (room) {
        // Initialize flow when room is loaded
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final state = ref.read(bookingFlowProvider);
          if (state.room?.id != room.id) {
            ref.read(bookingFlowProvider.notifier).init(room);
          }
        });
        return _buildContent(context, room);
      },
    );
  }

  Widget _buildContent(BuildContext context, _) {
    final state = ref.watch(bookingFlowProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(state.step == BookingStep.selectDate ? 'Pilih Jadwal' : 'Konfirmasi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (state.step == BookingStep.confirmDetails) {
              ref.read(bookingFlowProvider.notifier).goTo(BookingStep.selectDate);
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

  Widget _buildStep1SelectDate() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Tanggal Pemesanan',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _selectedDate ?? DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 90)),
            );
            if (date != null) setState(() => _selectedDate = date);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.outlineVariant),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_month_outlined, color: AppColors.primary),
                const SizedBox(width: 12),
                Text(
                  _selectedDate == null
                      ? 'Pilih tanggal'
                      : DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(_selectedDate!),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Waktu Mulai & Selesai',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _TimePickerCard(
                label: 'Mulai',
                time: _startTime,
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: _startTime ?? const TimeOfDay(hour: 8, minute: 0),
                  );
                  if (time != null) setState(() => _startTime = time);
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _TimePickerCard(
                label: 'Selesai',
                time: _endTime,
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: _endTime ?? const TimeOfDay(hour: 10, minute: 0),
                  );
                  if (time != null) setState(() => _endTime = time);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 48),
        FilledButton(
          onPressed: _selectedDate != null && _startTime != null && _endTime != null
              ? () {
                  final startMin = _startTime!.hour * 60 + _startTime!.minute;
                  final endMin = _endTime!.hour * 60 + _endTime!.minute;
                  if (endMin <= startMin) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Waktu selesai harus setelah waktu mulai.')),
                    );
                    return;
                  }
                  ref.read(bookingFlowProvider.notifier).setDateAndTime(_selectedDate!, _startTime!, _endTime!);
                  ref.read(bookingFlowProvider.notifier).goTo(BookingStep.confirmDetails);
                }
              : null,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          child: const Text('Lanjutkan'),
        ),
      ],
    );
  }

  Widget _buildStep2Confirm(BookingFlowState state) {
    final money = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    final isProcessing = state.isProcessing;

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
              Text('Rincian Pemesanan',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const Divider(height: 24),
              _DetailRow(label: 'Ruangan', value: state.room!.name),
              _DetailRow(label: 'Tanggal', value: DateFormat('dd MMM yyyy').format(state.selectedDate!)),
              _DetailRow(
                label: 'Waktu',
                value:
                    '${state.startTime!.hour.toString().padLeft(2, '0')}:${state.startTime!.minute.toString().padLeft(2, '0')} - ${state.endTime!.hour.toString().padLeft(2, '0')}:${state.endTime!.minute.toString().padLeft(2, '0')}',
              ),
              _DetailRow(label: 'Durasi', value: '${state.durationHours.toStringAsFixed(1)} jam'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Voucher Selection
        Text('Voucher Diskon',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _showVoucherSelectionSheet(context, ref),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: state.appliedCoupon != null ? AppColors.secondary : AppColors.outlineVariant),
              borderRadius: BorderRadius.circular(12),
              color: state.appliedCoupon != null ? AppColors.secondary.withValues(alpha: 0.1) : Colors.transparent,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.local_offer_outlined,
                  color: state.appliedCoupon != null ? AppColors.secondary : AppColors.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    state.appliedCoupon != null 
                        ? '${state.appliedCoupon!.code} - Diskon ${state.appliedCoupon!.discountPercent}%' 
                        : 'Pilih Voucher',
                    style: TextStyle(
                      fontWeight: state.appliedCoupon != null ? FontWeight.w700 : FontWeight.w500,
                      color: state.appliedCoupon != null ? AppColors.secondary : AppColors.onSurface,
                    ),
                  ),
                ),
                if (state.appliedCoupon != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => ref.read(bookingFlowProvider.notifier).removeCoupon(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  )
                else
                  const Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
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
              Text('Ringkasan Pembayaran',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Harga Base'),
                  Text(money.format(state.basePrice)),
                ],
              ),
              if (state.discountAmount > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Diskon Promo', style: TextStyle(color: AppColors.secondary)),
                      Text('- ${money.format(state.discountAmount)}', style: const TextStyle(color: AppColors.secondary)),
                    ],
                  ),
                ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Pembayaran',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  Text(money.format(state.finalPrice),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: AppColors.primary)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        FilledButton(
          onPressed: isProcessing ? null : () => _submitBooking(state),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          child: isProcessing ? const CircularProgressIndicator(color: Colors.white) : const Text('Buat Pesanan'),
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
      'start_time': '${state.startTime!.hour.toString().padLeft(2, '0')}:${state.startTime!.minute.toString().padLeft(2, '0')}',
      'end_time': '${state.endTime!.hour.toString().padLeft(2, '0')}:${state.endTime!.minute.toString().padLeft(2, '0')}',
      'base_price': state.basePrice,
      'final_price': state.finalPrice,
      'status': 'pending_payment',
    };

    if (state.appliedCoupon != null) {
      payload['coupon_id'] = state.appliedCoupon!.id;
      payload['discount_amount'] = state.discountAmount;
    }

    final result = await ref.read(bookingRepositoryProvider).createBooking(payload);
    ref.read(bookingFlowProvider.notifier).setProcessing(false);
    
    result.match(
      (failure) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message)));
      },
      (booking) {
        if (!mounted) return;
        // Go to payment screen
        context.pushReplacement(AppRoutes.paymentMethod.replaceFirst(':bookingId', booking.id));
      },
    );
  }

  void _showVoucherSelectionSheet(BuildContext context, WidgetRef ref) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return FutureBuilder(
          future: ref.read(couponRepositoryProvider).getAllCoupons(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final result = snapshot.data;
            if (result == null || result.isLeft()) {
              return const SizedBox(
                height: 200,
                child: Center(child: Text('Gagal memuat voucher')),
              );
            }

            final coupons = result.getOrElse((l) => []);

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Pilih Voucher Diskon',
                      style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 16),
                    if (coupons.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Text('Voucher kosong', style: TextStyle(color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w600)),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: coupons.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final coupon = coupons[index];
                          return InkWell(
                            onTap: () {
                              ref.read(bookingFlowProvider.notifier).applyCoupon(coupon);
                              Navigator.pop(sheetContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Voucher ${coupon.code} berhasil digunakan!'), backgroundColor: AppColors.secondary),
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.outlineVariant),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.confirmation_number, color: AppColors.primary, size: 32),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(coupon.code, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                                        const SizedBox(height: 4),
                                        Text('Diskon ${coupon.discountPercent}% hingga Rp ${coupon.maxDiscountAmount ?? 'Tanpa batas'}', style: const TextStyle(color: AppColors.onSurfaceVariant)),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _TimePickerCard extends StatelessWidget {
  const _TimePickerCard({required this.label, required this.time, required this.onTap});

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
            Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text(
              time == null ? '--:--' : '${time!.hour.toString().padLeft(2, '0')}:${time!.minute.toString().padLeft(2, '0')}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary),
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
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: AppColors.onSurfaceVariant))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
