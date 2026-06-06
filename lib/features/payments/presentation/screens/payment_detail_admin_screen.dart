import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/error_card.dart';
import '../providers/payment_providers.dart';
import 'payment_widgets.dart';

class PaymentDetailAdminScreen extends ConsumerWidget {
  const PaymentDetailAdminScreen({required this.paymentId, super.key});

  final String paymentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentValue = ref.watch(paymentDetailProvider(paymentId));

    return AppScaffold(
      title: 'Admin Payment Detail',
      body: paymentValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(16),
          child: ErrorCard(message: error.toString()),
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
                    PaymentInfoRow(label: 'Payment ID', value: payment.id),
                    PaymentInfoRow(label: 'Booking ID', value: payment.bookingId),
                    PaymentInfoRow(label: 'User ID', value: payment.userId),
                    PaymentInfoRow(
                      label: 'Agency ID',
                      value: payment.agencyId ?? '-',
                    ),
                    PaymentInfoRow(
                      label: 'Midtrans Order',
                      value: payment.midtransOrderId ?? '-',
                    ),
                    PaymentInfoRow(
                      label: 'Transaction ID',
                      value: payment.midtransTransactionId ?? '-',
                    ),
                    PaymentInfoRow(
                      label: 'Method',
                      value: payment.paymentMethod ?? '-',
                    ),
                    PaymentInfoRow(
                      label: 'Created at',
                      value: formatPaymentDate(payment.createdAt),
                    ),
                    PaymentInfoRow(
                      label: 'Expires at',
                      value: formatPaymentDate(payment.expiredAt),
                    ),
                    PaymentInfoRow(
                      label: 'Settlement',
                      value: formatPaymentDate(payment.settlementTime),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
