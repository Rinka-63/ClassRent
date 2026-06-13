import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/payment.dart';

final _currencyFormat = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp',
  decimalDigits: 0,
);

String formatPaymentAmount(double amount) => _currencyFormat.format(amount);

String formatPaymentDate(DateTime? date) {
  if (date == null) return '-';
  return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(date);
}

String paymentStatusLabel(PaymentStatus status) {
  return switch (status) {
    PaymentStatus.pending => 'Pending',
    PaymentStatus.capture => 'Capture',
    PaymentStatus.settlement => 'Settlement',
    PaymentStatus.deny => 'Deny',
    PaymentStatus.cancel => 'Cancel',
    PaymentStatus.expire => 'Expire',
    PaymentStatus.failure => 'Failure',
    PaymentStatus.refund => 'Refund',
  };
}

Color paymentStatusColor(PaymentStatus status) {
  return switch (status) {
    PaymentStatus.pending => AppColors.primaryContainer,
    PaymentStatus.capture => AppColors.secondary,
    PaymentStatus.settlement => AppColors.secondary,
    PaymentStatus.deny => AppColors.error,
    PaymentStatus.cancel => AppColors.tertiary,
    PaymentStatus.expire => AppColors.outline,
    PaymentStatus.failure => AppColors.error,
    PaymentStatus.refund => AppColors.primary,
  };
}

class PaymentStatusChip extends StatelessWidget {
  const PaymentStatusChip({required this.status, super.key});

  final PaymentStatus status;

  @override
  Widget build(BuildContext context) {
    final color = paymentStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        paymentStatusLabel(status),
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class PaymentInfoRow extends StatelessWidget {
  const PaymentInfoRow({
    required this.label,
    required this.value,
    super.key,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class PaymentEmptyPanel extends StatelessWidget {
  const PaymentEmptyPanel({
    required this.title,
    required this.message,
    this.action,
    super.key,
  });

  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        children: [
          const Icon(Icons.payments_outlined, size: 48, color: AppColors.primary),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
          ),
          if (action != null) ...[
            const SizedBox(height: 16),
            action!,
          ],
        ],
      ),
    );
  }
}
