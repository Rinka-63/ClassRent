import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/error_card.dart';
import '../providers/payment_providers.dart';
import 'payment_widgets.dart';

class PaymentDetailScreen extends ConsumerWidget {
  const PaymentDetailScreen({required this.paymentId, super.key});

  final String paymentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentValue = ref.watch(paymentDetailProvider(paymentId));

    return AppScaffold(
      title: 'Payment Detail',
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
                    PaymentInfoRow(
                      label: 'Method',
                      value: payment.paymentMethod ?? '-',
                    ),
                    PaymentInfoRow(
                      label: 'Order ID',
                      value: payment.midtransOrderId ?? '-',
                    ),
                    PaymentInfoRow(
                      label: 'Transaction ID',
                      value: payment.midtransTransactionId ?? '-',
                    ),
                    PaymentInfoRow(
                      label: 'Created at',
                      value: formatPaymentDate(payment.createdAt),
                    ),
                    PaymentInfoRow(
                      label: 'Updated at',
                      value: formatPaymentDate(payment.updatedAt),
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
