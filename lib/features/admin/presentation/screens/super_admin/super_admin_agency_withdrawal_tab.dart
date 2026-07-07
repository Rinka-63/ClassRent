import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/empty_state.dart';
import '../../../../../core/widgets/error_card.dart';
import '../../../domain/entities/agency_withdrawal.dart';
import '../../providers/super_admin_providers.dart';
import 'super_admin_withdrawal_transfer_screen.dart';

class SuperAdminAgencyWithdrawalTab extends ConsumerWidget {
  const SuperAdminAgencyWithdrawalTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final withdrawalsAsync = ref.watch(agencyWithdrawalsProvider);
    final money =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return withdrawalsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: ErrorCard(
          message: error.toString(),
          onRetry: () => ref.invalidate(agencyWithdrawalsProvider),
        ),
      ),
      data: (requests) {
        if (requests.isEmpty) {
          return const EmptyState(
            title: 'Belum ada pengajuan',
            message: 'Pengajuan pencairan agency akan muncul di sini.',
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(agencyWithdrawalsProvider),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = requests[index];
              final canReview = item.status == 'pending';
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.agencyName ?? 'Agensi',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                          _StatusPill(status: item.statusLabel),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _Line('Nominal Pengajuan', money.format(item.amount)),
                      _Line('Bank', item.bankName),
                      _Line('Nama Pemilik Rekening', item.accountName),
                      _Line('Nomor Rekening', item.accountNumber),
                      _Line(
                        'Diajukan',
                        DateFormat('dd MMM yyyy, HH:mm').format(item.createdAt),
                      ),
                      if (canReview) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _review(
                                  context,
                                  ref,
                                  item,
                                  'rejected',
                                ),
                                child: const Text('Tolak'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FilledButton(
                                onPressed: () => _review(
                                  context,
                                  ref,
                                  item,
                                  'approved',
                                ),
                                child: const Text('Setujui'),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (item.status == 'approved') ...[
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () => _openTransferPage(context, item),
                          icon: const Icon(Icons.account_balance_outlined),
                          label: const Text('Transfer Dana'),
                        ),
                      ],
                      if (item.status == 'paid') ...[
                        const SizedBox(height: 12),
                        const _TransferDoneBanner(),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _review(
    BuildContext context,
    WidgetRef ref,
    AgencyWithdrawal item,
    String status,
  ) async {
    final result = await ref
        .read(superAdminRepositoryProvider)
        .updateAgencyWithdrawalStatus(
          withdrawalId: item.id,
          status: status,
        );
    if (!context.mounted) return;
    result.match(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message)),
      ),
      (_) {
        ref.invalidate(agencyWithdrawalsProvider);
        if (status == 'approved') {
          _openTransferPage(context, item.copyWith(status: 'approved'));
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'approved'
                  ? 'Pengajuan pencairan disetujui.'
                  : 'Pengajuan pencairan ditolak.',
            ),
          ),
        );
      },
    );
  }

  Future<void> _openTransferPage(
    BuildContext context,
    AgencyWithdrawal item,
  ) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => SuperAdminWithdrawalTransferScreen(withdrawal: item),
      ),
    );
  }
}

class _TransferDoneBanner extends StatelessWidget {
  const _TransferDoneBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.successContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Dana sudah ditransfer.',
        style: TextStyle(
          color: AppColors.success,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.onSurfaceVariant),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
