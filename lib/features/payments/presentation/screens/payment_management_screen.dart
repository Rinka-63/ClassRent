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
    final selectedStatus = ref.watch(adminPaymentStatusFilterProvider);
    final summary = ref.watch(adminPaymentSummaryProvider);

    return AppScaffold(
      title: 'Payment Management',
      actions: [
        IconButton(
          onPressed: () => ref.invalidate(agencyPaymentsProvider),
          icon: const Icon(Icons.refresh),
        ),
      ],
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
              _StatusFilter(selectedStatus: selectedStatus),
              const SizedBox(height: 16),
              _StatsGrid(summary: summary),
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
      paid: payments.where((payment) => payment.status == PaymentStatus.settlement).length,
      failed:
          payments.where((payment) => payment.status == PaymentStatus.failure).length,
      totalAmount: payments.fold<double>(
        0,
        (total, payment) =>
            payment.status == PaymentStatus.settlement ? total + payment.amount : total,
      ),
    );
  }

  final int pending;
  final int paid;
  final int failed;
  final double totalAmount;
}

class _StatusFilter extends ConsumerWidget {
  const _StatusFilter({required this.selectedStatus});

  final String? selectedStatus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const statuses = [
      null,
      'pending',
      'settlement',
      'capture',
      'cancel',
      'expire',
      'failure',
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: statuses.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final status = statuses[index];
          final selected = status == selectedStatus;
          return ChoiceChip(
            selected: selected,
            label: Text(status == null ? 'All' : status),
            onSelected: (_) {
              ref.read(adminPaymentStatusFilterProvider.notifier).state = status;
              ref.invalidate(agencyPaymentsProvider);
            },
          );
        },
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.summary});

  final AdminPaymentSummary summary;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _StatTile(label: 'Total Payment', value: summary.totalPayment.toString()),
      _StatTile(label: 'Total Pending', value: summary.totalPending.toString()),
      _StatTile(label: 'Total Settlement', value: summary.totalSettlement.toString()),
      _StatTile(label: 'Total Revenue', value: formatPaymentAmount(summary.totalRevenue)),
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
        subtitle: Text(
          '${payment.orderId ?? payment.bookingId}\n'
          '${payment.paymentMethod ?? payment.paymentType ?? 'No method'} • '
          '${formatPaymentDate(payment.createdAt)}',
        ),
        isThreeLine: true,
        trailing: PaymentStatusChip(status: payment.status),
        onTap: () => context.push(AppRoutes.adminPaymentDetailPath(payment.id)),
      ),
    );
  }
}
