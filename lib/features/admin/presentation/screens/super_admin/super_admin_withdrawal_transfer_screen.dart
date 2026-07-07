import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_scaffold.dart';
import '../../../domain/entities/agency_withdrawal.dart';
import '../../providers/super_admin_providers.dart';

class SuperAdminWithdrawalTransferScreen extends ConsumerStatefulWidget {
  const SuperAdminWithdrawalTransferScreen({
    required this.withdrawal,
    super.key,
  });

  final AgencyWithdrawal withdrawal;

  @override
  ConsumerState<SuperAdminWithdrawalTransferScreen> createState() =>
      _SuperAdminWithdrawalTransferScreenState();
}

class _SuperAdminWithdrawalTransferScreenState
    extends ConsumerState<SuperAdminWithdrawalTransferScreen> {
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final withdrawal = widget.withdrawal;
    final money =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return AppScaffold(
      title: 'Transfer Pencairan',
      showBrandLogo: false,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.22),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.account_balance_outlined,
                  color: Colors.white,
                  size: 30,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Silakan transfer dana ke rekening agensi.',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Setelah transfer selesai, tandai pencairan sebagai sudah ditransfer.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.84),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _AmountPanel(amount: money.format(withdrawal.amount)),
          const SizedBox(height: 16),
          _DetailPanel(
            children: [
              _TransferLine('Agensi', withdrawal.agencyName ?? 'Agensi'),
              _TransferLine('Bank', withdrawal.bankName),
              _TransferLine('Nama Rekening', withdrawal.accountName),
              _TransferLine('Nomor Rekening', withdrawal.accountNumber),
              _TransferLine(
                'Diajukan',
                DateFormat('dd MMM yyyy, HH:mm').format(withdrawal.createdAt),
              ),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _isSubmitting ? null : _markAsPaid,
            icon: _isSubmitting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      color: AppColors.onPrimary,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.check_circle_outline),
            label: const Text('Tandai Sudah Ditransfer'),
          ),
        ],
      ),
    );
  }

  Future<void> _markAsPaid() async {
    setState(() => _isSubmitting = true);
    final result = await ref
        .read(superAdminRepositoryProvider)
        .updateAgencyWithdrawalStatus(
          withdrawalId: widget.withdrawal.id,
          status: 'paid',
        );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.match(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message)),
      ),
      (_) {
        ref.invalidate(agencyWithdrawalsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pencairan ditandai sudah ditransfer.')),
        );
        Navigator.of(context).pop();
      },
    );
  }
}

class _AmountPanel extends StatelessWidget {
  const _AmountPanel({required this.amount});

  final String amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nominal Transfer',
            style: TextStyle(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            amount,
            style: const TextStyle(
              color: AppColors.primaryDeep,
              fontWeight: FontWeight.w900,
              fontSize: 26,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailPanel extends StatelessWidget {
  const _DetailPanel({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(children: children),
    );
  }
}

class _TransferLine extends StatelessWidget {
  const _TransferLine(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
