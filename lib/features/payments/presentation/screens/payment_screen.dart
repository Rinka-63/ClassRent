import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/error_card.dart';
import '../../../../shared/presentation/widgets/role_aware_nav_bar.dart';
import '../providers/payment_providers.dart';
import 'payment_widgets.dart';

class PaymentScreen extends ConsumerWidget {
  const PaymentScreen({required this.bookingId, super.key});

  final String bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentValue = ref.watch(paymentByBookingProvider(bookingId));

    return AppScaffold(
      title: 'Payment',
      bottomNavigationBar: const RoleAwareNavBar(currentPath: AppRoutes.payments),
      body: paymentValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Booking $bookingId',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'This screen is prepared for Midtrans Snap checkout.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            ErrorCard(message: error.toString()),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: null,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open Midtrans Payment'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => context.push(AppRoutes.payments),
              icon: const Icon(Icons.history_outlined),
              label: const Text('View Payment History'),
            ),
          ],
        ),
        data: (payment) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          formatPaymentAmount(payment.amount),
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        PaymentStatusChip(status: payment.status),
                      ],
                    ),
                    const SizedBox(height: 16),
                    PaymentInfoRow(label: 'Booking ID', value: payment.bookingId),
                    PaymentInfoRow(
                      label: 'Order ID',
                      value: payment.midtransOrderId ?? '-',
                    ),
                    PaymentInfoRow(
                      label: 'Expires at',
                      value: formatPaymentDate(payment.expiredAt),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: payment.canOpenPaymentPage ? () {} : null,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open Midtrans Payment'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => context.push(AppRoutes.paymentDetailPath(payment.id)),
              icon: const Icon(Icons.receipt_long_outlined),
              label: const Text('Payment Detail'),
            ),
          ],
        ),
      ),
    );
  }
}
