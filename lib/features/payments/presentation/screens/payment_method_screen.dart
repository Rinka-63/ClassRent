import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../booking/presentation/providers/booking_admin_providers.dart';
import '../../data/services/midtrans_service.dart';

class PaymentMethodScreen extends ConsumerWidget {
  const PaymentMethodScreen({required this.bookingId, super.key});

  final String bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Payment illustration
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.account_balance_wallet_outlined, size: 48, color: AppColors.primary),
              ),
              const SizedBox(height: 24),
              Text(
                'Lanjutkan Pembayaran',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              const Text(
                'Anda akan diarahkan ke halaman pembayaran Midtrans untuk memilih metode pembayaran (Transfer Bank, E-Wallet, QRIS, dll).',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.onSurfaceVariant, height: 1.5),
              ),
              const SizedBox(height: 8),
              // Payment method icons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _PaymentBadge(icon: Icons.account_balance, label: 'Bank'),
                  const SizedBox(width: 12),
                  _PaymentBadge(icon: Icons.wallet, label: 'E-Wallet'),
                  const SizedBox(width: 12),
                  _PaymentBadge(icon: Icons.qr_code_2, label: 'QRIS'),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _processPayment(context, ref),
                  icon: const Icon(Icons.lock_outline, size: 18),
                  label: const Text('Bayar Sekarang'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shield_outlined, size: 14, color: AppColors.onSurfaceVariant.withValues(alpha: 0.6)),
                  const SizedBox(width: 6),
                  Text(
                    'Pembayaran aman & terenkripsi',
                    style: TextStyle(color: AppColors.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _processPayment(BuildContext context, WidgetRef ref) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final user = ref.read(currentUserProvider);

      // Fetch actual booking from DB to get the correct finalPrice
      final bookingResult = await ref.read(bookingRepositoryProvider).getBookingById(bookingId);
      
      double grossAmount = 50000; // fallback
      bookingResult.fold(
        (failure) => null,
        (booking) => grossAmount = booking.finalPrice > 0 ? booking.finalPrice : booking.basePrice,
      );

      final midtrans = MidtransService();
      final url = await midtrans.createTransaction(
        orderId: 'CLASSRENT-$bookingId',
        grossAmount: grossAmount,
        firstName: user?.fullName ?? 'User',
        email: user?.email ?? 'user@example.com',
      );

      if (context.mounted) Navigator.pop(context); // hide loading

      if (context.mounted) {
        // Navigate to in-app WebView instead of external browser
        context.push(
          '/payments/webview/$bookingId',
          extra: url,
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // hide loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memproses pembayaran: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

class _PaymentBadge extends StatelessWidget {
  const _PaymentBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant)),
        ],
      ),
    );
  }
}
