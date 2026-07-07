import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../booking/presentation/providers/booking_admin_providers.dart';
import '../../data/services/midtrans_service.dart';
import '../providers/payment_providers.dart';

class PaymentMethodScreen extends ConsumerWidget {
  const PaymentMethodScreen({required this.bookingId, super.key});

  final String bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(strings.payments)),
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
                child: const Icon(Icons.account_balance_wallet_outlined,
                    size: 48, color: AppColors.primary),
              ),
              const SizedBox(height: 24),
              Text(
                strings.tr('Lanjutkan Pembayaran', 'Continue Payment'),
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Text(
                strings.tr(
                  'Anda akan diarahkan ke halaman pembayaran Midtrans untuk memilih metode pembayaran (Transfer Bank, E-Wallet, QRIS, dll).',
                  'You will be directed to the Midtrans payment page to choose a payment method (bank transfer, e-wallet, QRIS, etc.).',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.onSurfaceVariant,
                  height: 1.5,
                ),
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
                  label: Text(strings.tr('Bayar Sekarang', 'Pay Now')),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shield_outlined,
                      size: 14,
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.6)),
                  const SizedBox(width: 6),
                  Text(
                    strings.tr(
                      'Pembayaran aman & terenkripsi',
                      'Secure and encrypted payment',
                    ),
                    style: TextStyle(
                        color:
                            AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                        fontSize: 12),
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
    final strings = AppStrings.of(context);
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final user = ref.read(currentUserProvider);

      // Check if payment already exists for this booking
      final existingPaymentResult = await ref
          .read(paymentRepositoryProvider)
          .getPaymentByBookingId(bookingId);

      // If payment exists and is already completed, redirect to booking detail
      existingPaymentResult.fold(
        (failure) {
          // Payment not found, proceed to create new transaction
        },
        (payment) {
          // Payment exists
          if (context.mounted) Navigator.pop(context); // hide loading

          if (payment.status == 'settlement' || payment.status == 'capture') {
            // Payment already completed
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    strings.tr(
                      'Pembayaran sudah selesai',
                      'Payment is already complete',
                    ),
                  ),
                  backgroundColor: AppColors.secondary,
                ),
              );
              context.pop(); // Go back to booking detail
            }
            return;
          }

          // Payment is pending/failed, allow retry
          // Continue to create new transaction
        },
      );

      // Fetch actual booking from DB to get the correct finalPrice
      final bookingResult =
          await ref.read(bookingRepositoryProvider).getBookingById(bookingId);

      double grossAmount = 50000; // fallback
      bookingResult.fold(
        (failure) => null,
        (booking) => grossAmount =
            booking.finalPrice > 0 ? booking.finalPrice : booking.basePrice,
      );

      final timestamp = DateTime.now()
          .millisecondsSinceEpoch
          .toString()
          .substring(5); // shorter timestamp
      final uuid32 = bookingId.replaceAll('-', ''); // 32 chars
      final midtrans = MidtransService();
      final url = await midtrans.createTransaction(
        orderId: '$uuid32-$timestamp', // 32 + 1 + 8 = 41 chars (< 50)
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
            content: Text(
              strings.tr(
                'Gagal memproses pembayaran: $e',
                'Failed to process payment: $e',
              ),
            ),
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
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.onSurfaceVariant)),
        ],
      ),
    );
  }
}
