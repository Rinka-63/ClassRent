import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_scaffold.dart';

class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return AppScaffold(
      title: strings.payments,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _FilterChip(label: strings.all, selected: true),
                _FilterChip(label: strings.tr('Berhasil', 'Success')),
                _FilterChip(label: strings.tr('Pending', 'Pending')),
                _FilterChip(label: strings.tr('Gagal', 'Failed')),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            strings.tr('Riwayat Pembayaran', 'Payment History'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            strings.tr(
              'Transaksi dari Midtrans akan tampil otomatis setelah Anda menyelesaikan pembayaran booking.',
              'Transactions from Midtrans will appear automatically after you complete booking payment.',
            ),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          _PaymentStateCard(
            icon: Icons.receipt_long_outlined,
            title: strings.tr('Belum ada transaksi', 'No transactions yet'),
            message: strings.tr(
              'Mulai dari halaman pemesanan untuk membuat booking dan memilih metode pembayaran.',
              'Start from the bookings page to create a booking and choose a payment method.',
            ),
          ),
          const SizedBox(height: 16),
          _PaymentInfoCard(
            title: strings.tr('Status pembayaran', 'Payment Status'),
            rows: [
              _InfoRowData(
                icon: Icons.check_circle_outline,
                label: strings.tr('Berhasil', 'Success'),
                value: strings.tr(
                  'Booking sudah dikonfirmasi setelah callback Midtrans.',
                  'Booking is confirmed after the Midtrans callback.',
                ),
              ),
              _InfoRowData(
                icon: Icons.schedule_outlined,
                label: strings.tr('Pending', 'Pending'),
                value: strings.tr(
                  'Menunggu penyelesaian pembayaran dari pengguna.',
                  'Waiting for the user to complete payment.',
                ),
              ),
              _InfoRowData(
                icon: Icons.error_outline,
                label: strings.tr('Gagal', 'Failed'),
                value: strings.tr(
                  'Transaksi tidak selesai atau ditolak oleh kanal bayar.',
                  'The transaction was not completed or was rejected by the payment channel.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => context.push(AppRoutes.bookings),
            icon: const Icon(Icons.event_note_outlined),
            label: Text(strings.tr('Lihat Booking', 'View Bookings')),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label),
        backgroundColor: selected
            ? AppColors.primaryContainer
            : AppColors.surfaceContainerHigh,
        labelStyle: TextStyle(
          color: selected
              ? AppColors.onPrimaryContainer
              : AppColors.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
        side: BorderSide.none,
      ),
    );
  }
}

class _PaymentStateCard extends StatelessWidget {
  const _PaymentStateCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: AppColors.primary, size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _PaymentInfoCard extends StatelessWidget {
  const _PaymentInfoCard({required this.title, required this.rows});

  final String title;
  final List<_InfoRowData> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          for (final row in rows) _PaymentInfoRow(row: row),
        ],
      ),
    );
  }
}

class _PaymentInfoRow extends StatelessWidget {
  const _PaymentInfoRow({required this.row});

  final _InfoRowData row;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(row.icon, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(row.label, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 4),
                Text(
                  row.value,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRowData {
  const _InfoRowData({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}
