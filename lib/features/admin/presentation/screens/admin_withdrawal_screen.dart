import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../booking/domain/entities/booking.dart';
import '../../../booking/presentation/providers/booking_admin_providers.dart';
import '../../domain/entities/agency_withdrawal.dart';
import '../providers/agency_providers.dart';

class AdminWithdrawalScreen extends ConsumerStatefulWidget {
  const AdminWithdrawalScreen({super.key});

  @override
  ConsumerState<AdminWithdrawalScreen> createState() =>
      _AdminWithdrawalScreenState();
}

class _AdminWithdrawalScreenState extends ConsumerState<AdminWithdrawalScreen> {
  final _accountNameCtrl = TextEditingController();
  final _accountNumberCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String? _selectedBank;
  bool _isSubmitting = false;

  static const _bankOptions = [
    'BCA',
    'BRI',
    'BNI',
    'Mandiri',
    'CIMB Niaga',
    'BTN',
    'BSI',
    'Danamon',
    'Permata',
    'OCBC',
    'SeaBank',
    'Jago',
  ];

  @override
  void dispose() {
    _accountNameCtrl.dispose();
    _accountNumberCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final bookingsAsync = ref.watch(agencyBookingsProvider);
    final withdrawalsAsync = user == null
        ? const AsyncValue<List<AgencyWithdrawal>>.data([])
        : ref.watch(myAgencyWithdrawalsProvider(user.id));
    final money =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return AppScaffold(
      title: 'Pencairan Dana',
      showBrandLogo: false,
      actions: [
        TextButton(
          onPressed: () => _showHistory(context, withdrawalsAsync),
          child: const Text('Riwayat'),
        ),
      ],
      body: bookingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (bookings) {
          final withdrawals = withdrawalsAsync.valueOrNull ?? const [];
          final summary = _WithdrawalSummary.fromBookings(
            bookings,
            withdrawals,
          );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _BalanceGrid(summary: summary, money: money),
              const SizedBox(height: 20),
              Text(
                'Form Pengajuan',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _accountNameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nama Pemilik Rekening',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedBank,
                decoration: const InputDecoration(labelText: 'Nama Bank'),
                items: _bankOptions
                    .map(
                      (bank) => DropdownMenuItem(
                        value: bank,
                        child: Text(bank),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _selectedBank = value),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _accountNumberCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'Nomor Rekening'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: const [_ThousandsInputFormatter()],
                decoration: InputDecoration(
                  labelText: 'Nominal',
                  helperText:
                      'Maksimal ${money.format(summary.availableBalance)}',
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _isSubmitting || user == null
                    ? null
                    : () => _submit(user.id, summary.availableBalance, money),
                child: _isSubmitting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Ajukan Pencairan'),
              ),
              const SizedBox(height: 20),
              withdrawalsAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text(
                  'Gagal memuat riwayat: $e',
                  style: const TextStyle(color: AppColors.error),
                ),
                data: (items) => _RecentWithdrawals(
                  withdrawals: items.take(3).toList(),
                  money: money,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _submit(
    String adminId,
    double maxAmount,
    NumberFormat money,
  ) async {
    final amount = double.tryParse(_amountCtrl.text.replaceAll('.', '')) ?? 0;
    if (_accountNameCtrl.text.trim().isEmpty ||
        _selectedBank == null ||
        _accountNumberCtrl.text.trim().isEmpty) {
      _toast('Lengkapi semua field rekening.');
      return;
    }
    if (amount <= 0 || amount > maxAmount) {
      _toast('Nominal tidak valid. Maksimal ${money.format(maxAmount)}.');
      return;
    }

    setState(() => _isSubmitting = true);
    final result = await ref.read(agencyRepositoryProvider).createWithdrawal(
          adminId: adminId,
          amount: amount,
          bankName: _selectedBank!,
          accountName: _accountNameCtrl.text.trim(),
          accountNumber: _accountNumberCtrl.text.trim(),
        );
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    result.match(
      (failure) => _toast(failure.message),
      (_) {
        _amountCtrl.clear();
        ref.invalidate(myAgencyWithdrawalsProvider(adminId));
        _toast('Pengajuan pencairan berhasil dikirim.');
      },
    );
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _showHistory(
    BuildContext context,
    AsyncValue<List<AgencyWithdrawal>> withdrawalsAsync,
  ) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final withdrawals = withdrawalsAsync.valueOrNull ?? const [];
        if (withdrawals.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Text('Belum ada riwayat pencairan.'),
          );
        }
        final money = NumberFormat.currency(
          locale: 'id_ID',
          symbol: 'Rp ',
          decimalDigits: 0,
        );
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: withdrawals.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (_, index) {
            final item = withdrawals[index];
            return ListTile(
              title: Text(money.format(item.amount)),
              subtitle: Text(
                '${item.bankName} • ${item.accountNumber}\n${DateFormat('dd MMM yyyy, HH:mm').format(item.createdAt)}',
              ),
              trailing: Text(item.statusLabel),
            );
          },
        );
      },
    );
  }
}

class _WithdrawalSummary {
  const _WithdrawalSummary({
    required this.availableBalance,
    required this.totalRevenue,
    required this.totalWithdrawn,
    required this.pendingBalance,
  });

  final double availableBalance;
  final double totalRevenue;
  final double totalWithdrawn;
  final double pendingBalance;

  factory _WithdrawalSummary.fromBookings(
    List<Booking> bookings,
    List<AgencyWithdrawal> withdrawals,
  ) {
    final completedStatuses = {
      'confirmed',
      'checked_in',
      'checked_out',
      'completed',
    };
    final confirmed =
        bookings.where((b) => completedStatuses.contains(b.status));
    final pending = bookings.where(
      (b) => b.status == 'pending_payment' || b.status == 'pending_approval',
    );
    final totalRevenue =
        confirmed.fold<double>(0, (sum, b) => sum + b.finalPrice);
    final withdrawn = withdrawals
        .where((item) => item.status != 'rejected')
        .fold<double>(0, (sum, item) => sum + item.amount);
    final pendingBalance =
        pending.fold<double>(0, (sum, b) => sum + b.finalPrice);
    return _WithdrawalSummary(
      availableBalance: totalRevenue - withdrawn,
      totalRevenue: totalRevenue,
      totalWithdrawn: withdrawn,
      pendingBalance: pendingBalance,
    );
  }
}

class _BalanceGrid extends StatelessWidget {
  const _BalanceGrid({required this.summary, required this.money});

  final _WithdrawalSummary summary;
  final NumberFormat money;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _StatTile(
          'Saldo Tersedia',
          money.format(summary.availableBalance),
          AppColors.success,
        ),
        _StatTile(
          'Total Pendapatan',
          money.format(summary.totalRevenue),
          AppColors.primary,
        ),
        _StatTile(
          'Sudah/Dalam Proses',
          money.format(summary.totalWithdrawn),
          AppColors.onSurfaceVariant,
        ),
        _StatTile(
          'Saldo Menunggu',
          money.format(summary.pendingBalance),
          AppColors.warning,
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile(this.label, this.value, this.color);

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentWithdrawals extends StatelessWidget {
  const _RecentWithdrawals({required this.withdrawals, required this.money});

  final List<AgencyWithdrawal> withdrawals;
  final NumberFormat money;

  @override
  Widget build(BuildContext context) {
    if (withdrawals.isEmpty) {
      return const Text(
        'Belum ada riwayat pencairan.',
        style: TextStyle(color: AppColors.onSurfaceVariant),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Riwayat Terbaru', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final item in withdrawals)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(money.format(item.amount)),
            subtitle: Text('${item.bankName} • ${item.accountNumber}'),
            trailing: Text(item.statusLabel),
          ),
      ],
    );
  }
}

class _ThousandsInputFormatter extends TextInputFormatter {
  const _ThousandsInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue();
    final number = int.parse(digits);
    final formatted = NumberFormat.decimalPattern('id_ID').format(number);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
