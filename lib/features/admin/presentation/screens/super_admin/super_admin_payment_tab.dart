import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/empty_state.dart';
import '../../../../../core/widgets/error_card.dart';
import '../../providers/super_admin_providers.dart';

class SuperAdminPaymentTab extends ConsumerWidget {
  const SuperAdminPaymentTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(platformPaymentsProvider);
    final money =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    final dateFmt = DateFormat('dd MMM yyyy, HH:mm');

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(platformPaymentsProvider),
      child: paymentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Padding(
          padding: const EdgeInsets.all(16),
          child: ErrorCard(message: err.toString()),
        ),
        data: (payments) {
          if (payments.isEmpty) {
            return const EmptyState(
              title: 'Belum ada transaksi',
              message: 'Transaksi pembayaran platform akan tampil di sini.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: payments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final payment = payments[index];
              final (statusColor, statusIcon) = _statusStyle(payment.status);

              return InkWell(
                onTap: () => _showDetail(context, payment, money, dateFmt),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(statusIcon, color: statusColor, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              payment.userName ?? 'Pengguna',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          Text(
                            _statusLabel(payment.status),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        money.format(payment.amount),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _Row('ID Pesanan', payment.bookingId),
                      _Row('Faktur',
                          'INV-${payment.id.substring(0, 8).toUpperCase()}'),
                      _Row(
                          'Waktu Transaksi', dateFmt.format(payment.createdAt)),
                      if (payment.paymentMethod != null)
                        _Row('Metode', payment.paymentMethod!),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  (Color, IconData) _statusStyle(String status) {
    switch (status) {
      case 'settlement':
      case 'capture':
        return (AppColors.success, Icons.check_circle_outline);
      case 'pending':
        return (AppColors.warning, Icons.schedule);
      case 'cancel':
      case 'deny':
      case 'expire':
        return (AppColors.error, Icons.cancel_outlined);
      default:
        return (AppColors.onSurfaceVariant, Icons.info_outline);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'settlement':
      case 'capture':
        return 'Selesai';
      case 'pending':
        return 'Menunggu';
      case 'cancel':
      case 'deny':
      case 'expire':
        return 'Dibatalkan';
      default:
        return status.toUpperCase();
    }
  }

  void _showDetail(
    BuildContext context,
    dynamic payment,
    NumberFormat money,
    DateFormat dateFmt,
  ) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Detail Pembayaran',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _Row('Nama Pengguna', payment.userName ?? '-'),
            _Row('ID Pesanan', payment.bookingId),
            _Row('Faktur', 'INV-${payment.id.substring(0, 8).toUpperCase()}'),
            _Row('Nominal', money.format(payment.amount)),
            _Row('Status', payment.status),
            _Row('Metode', payment.paymentMethod ?? '-'),
            _Row('Tanggal Transaksi', dateFmt.format(payment.createdAt)),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(color: AppColors.onSurfaceVariant)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
