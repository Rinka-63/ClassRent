import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../booking/presentation/providers/booking_admin_providers.dart';

class MidtransWebViewScreen extends ConsumerStatefulWidget {
  const MidtransWebViewScreen({
    required this.paymentUrl,
    required this.bookingId,
    super.key,
  });

  final String paymentUrl;
  final String bookingId;

  @override
  ConsumerState<MidtransWebViewScreen> createState() =>
      _MidtransWebViewScreenState();
}

class _MidtransWebViewScreenState extends ConsumerState<MidtransWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onProgress: (progress) {
            if (mounted) setState(() => _progress = progress / 100);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onNavigationRequest: (request) {
            // Handle Midtrans callback URLs
            final url = request.url;
            if (url.contains('transaction_status=settlement') ||
                url.contains('transaction_status=capture') ||
                url.contains('status_code=200')) {
              _onPaymentSuccess();
              return NavigationDecision.prevent;
            }
            if (url.contains('transaction_status=deny') ||
                url.contains('transaction_status=cancel') ||
                url.contains('transaction_status=expire')) {
              _onPaymentFailed();
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  void _onPaymentSuccess() async {
    // Update booking status to confirmed immediately
    try {
      await ref.read(bookingRepositoryProvider).updateBooking(
        widget.bookingId,
        {'status': 'confirmed'},
      );
      await _createPaymentSuccessNotification();
    } catch (_) {}

    if (!mounted) return;
    context.go(AppRoutes.bookings);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
                child: Text(
                    '🎉 Pembayaran berhasil! Booking kamu sudah dikonfirmasi.')),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _onPaymentFailed() {
    if (!mounted) return;
    context.go(AppRoutes.bookings);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text('Pembayaran gagal atau dibatalkan.')),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _createPaymentSuccessNotification() async {
    final client = ref.read(supabaseClientProvider);
    final user = ref.read(currentUserProvider);
    if (client == null || user == null) return;

    final existing = await client
        .from('notifications')
        .select('id')
        .eq('receiver_id', user.id)
        .eq('type', 'payment_success')
        .eq('reference_id', widget.bookingId)
        .maybeSingle();
    if (existing != null) return;

    await client.from('notifications').insert({
      'receiver_id': user.id,
      'user_id': user.id,
      'sender_id': null,
      'title': 'Pembayaran berhasil',
      'body': 'Pembayaran berhasil. Booking kamu sudah dikonfirmasi.',
      'type': 'payment_success',
      'reference_id': widget.bookingId,
      'data': {'reference_id': widget.bookingId},
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppStrings.of(context).tr('Pembayaran Midtrans', 'Midtrans Payment'),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showExitDialog(context),
        ),
        bottom: _isLoading
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: AppColors.surfaceContainer,
                  color: AppColors.primary,
                ),
              )
            : null,
      ),
      body: WebViewWidget(controller: _controller),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Simulasi konfirmasi pembayaran
          _onPaymentSuccess();
        },
        icon: const Icon(Icons.qr_code_scanner),
        label: Text(
          AppStrings.of(context).tr('Simulasi Bayar QR', 'Simulate QR Payment'),
        ),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showExitDialog(BuildContext context) {
    final strings = AppStrings.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(strings.tr('Batalkan Pembayaran?', 'Cancel Payment?')),
        content: Text(
          strings.tr(
            'Apakah Anda yakin ingin meninggalkan halaman pembayaran? Transaksi Anda belum selesai.',
            'Are you sure you want to leave the payment page? Your transaction is not complete yet.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(strings.tr('Lanjutkan Bayar', 'Continue Payment')),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go(AppRoutes.bookings);
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(strings.tr('Keluar', 'Exit')),
          ),
        ],
      ),
    );
  }
}
