import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/error_card.dart';
import '../../../../shared/presentation/widgets/role_aware_nav_bar.dart';
import '../../domain/entities/payment.dart';
import '../providers/payment_providers.dart';
import 'payment_widgets.dart';

class PaymentHistoryScreen extends ConsumerWidget {
  const PaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsValue = ref.watch(paymentHistoryProvider);

    return AppScaffold(
      title: 'Payment History',
      bottomNavigationBar: const RoleAwareNavBar(currentPath: AppRoutes.payments),
      body: paymentsValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(16),
          child: ErrorCard(
            message: error.toString(),
            onRetry: () => ref.invalidate(paymentHistoryProvider),
          ),
        ),
        data: (payments) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Track Midtrans-compatible payment states for your bookings.',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            if (payments.isEmpty)
              const PaymentEmptyPanel(
                title: 'No payment records yet',
                message:
                    'Payments will appear here after the Midtrans backend creates real payment transactions.',
              )
            else
              for (final payment in payments) ...[
                _PaymentHistoryCard(payment: payment),
                const SizedBox(height: 12),
              ],
          ],
        ),
      ),
    );
  }
}

class _PaymentHistoryCard extends StatelessWidget {
  const _PaymentHistoryCard({required this.payment});

  final Payment payment;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.receipt_long_outlined),
        title: Text(formatPaymentAmount(payment.amount)),
        subtitle: Text(
          '${payment.orderId ?? 'No order id'}\n'
          '${payment.paymentMethod ?? payment.paymentType ?? 'No method'} • '
          '${formatPaymentDate(payment.createdAt)}',
        ),
        isThreeLine: true,
        trailing: PaymentStatusChip(status: payment.status),
        onTap: () => context.push(AppRoutes.paymentDetailPath(payment.id)),
      ),
    );
  }
}
