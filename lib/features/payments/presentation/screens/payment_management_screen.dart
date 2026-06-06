import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/error_card.dart';
import '../../../../shared/presentation/widgets/admin_nav_bar.dart';
import '../../domain/entities/payment.dart';
import '../providers/payment_providers.dart';
import 'payment_widgets.dart';

class PaymentManagementScreen extends ConsumerWidget {
  const PaymentManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsValue = ref.watch(agencyPaymentsProvider);

    return AppScaffold(
      title: 'Payment Management',
      bottomNavigationBar: const AdminNavBar(
        currentPath: AppRoutes.paymentManagement,
      ),
      body: paymentsValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(16),
          child: ErrorCard(
            message: error.toString(),
            onRetry: () => ref.invalidate(agencyPaymentsProvider),
          ),
        ),
        data: (payments) {
          final stats = _PaymentStats.fromPayments(payments);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Monitor Midtrans-ready transactions across agency bookings.',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              _StatsGrid(stats: stats),
              const SizedBox(height: 16),
              if (payments.isEmpty)
                const PaymentEmptyPanel(
                  title: 'No agency payments yet',
                  message:
                      'Real Midtrans transactions will appear here after the payment backend is connected.',
                )
              else
                for (final payment in payments) ...[
                  _AdminPaymentCard(payment: payment),
                  const SizedBox(height: 12),
                ],
            ],
          );
        },
      ),
    );
  }
}

class _PaymentStats {
  const _PaymentStats({
    required this.pending,
    required this.paid,
    required this.failed,
    required this.totalAmount,
  });

  factory _PaymentStats.fromPayments(List<Payment> payments) {
    return _PaymentStats(
      pending:
          payments.where((payment) => payment.status == PaymentStatus.pending).length,
      paid: payments.where((payment) => payment.status == PaymentStatus.paid).length,
      failed:
          payments.where((payment) => payment.status == PaymentStatus.failed).length,
      totalAmount: payments.fold<double>(
        0,
        (total, payment) =>
            payment.status == PaymentStatus.paid ? total + payment.amount : total,
      ),
    );
  }

  final int pending;
  final int paid;
  final int failed;
  final double totalAmount;
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});

  final _PaymentStats stats;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _StatTile(label: 'Pending', value: stats.pending.toString()),
      _StatTile(label: 'Paid', value: stats.paid.toString()),
      _StatTile(label: 'Failed', value: stats.failed.toString()),
      _StatTile(label: 'Revenue', value: formatPaymentAmount(stats.totalAmount)),
    ];

    return GridView.builder(
      itemCount: tiles.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 96,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (_, index) => tiles[index],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminPaymentCard extends StatelessWidget {
  const _AdminPaymentCard({required this.payment});

  final Payment payment;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.payments_outlined),
        title: Text(formatPaymentAmount(payment.amount)),
        subtitle: Text('Booking ${payment.bookingId}'),
        trailing: PaymentStatusChip(status: payment.status),
        onTap: () => context.push(AppRoutes.adminPaymentDetailPath(payment.id)),
      ),
    );
  }
}
