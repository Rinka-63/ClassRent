import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/error_card.dart';
import '../../../../shared/presentation/widgets/role_aware_nav_bar.dart';
import '../../domain/entities/payment.dart';
import '../providers/payment_providers.dart';
import 'payment_widgets.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({required this.bookingId, super.key});

  final String bookingId;

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> with WidgetsBindingObserver {
  bool _openedPaymentPage = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _openedPaymentPage) {
      _openedPaymentPage = false;
      _refreshPayment();
    }
  }

  @override
  Widget build(BuildContext context) {
    final paymentValue = ref.watch(latestPaymentByBookingProvider(widget.bookingId));
    final actionState = ref.watch(paymentControllerProvider);

    return AppScaffold(
      title: 'Payment',
      bottomNavigationBar: const RoleAwareNavBar(currentPath: AppRoutes.payments),
      body: paymentValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Booking ${widget.bookingId}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'This screen is prepared for Midtrans Snap checkout.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            ErrorCard(message: error.toString()),
            const SizedBox(height: 16),
            _PayButton(
              isLoading: actionState.isLoading,
              onPressed: () async {
                final opened = await _createAndOpenPayment(context, ref);
                if (opened) _refreshPayment();
              },
            ),
            if (actionState.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                actionState.errorMessage!,
                style: const TextStyle(color: AppColors.error),
              ),
            ],
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => context.push(AppRoutes.payments),
              icon: const Icon(Icons.history_outlined),
              label: const Text('View Payment History'),
            ),
          ],
        ),
        data: (payment) {
          if (payment == null) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                PaymentEmptyPanel(
                  title: 'No payment for this booking',
                  message:
                      'Press Bayar Sekarang to create a Midtrans Snap payment for this booking.',
                  action: _PayButton(
                    isLoading: actionState.isLoading,
                    onPressed: () async {
                      final opened = await _createAndOpenPayment(context, ref);
                      if (opened) _refreshPayment();
                    },
                  ),
                ),
                if (actionState.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  ErrorCard(message: actionState.errorMessage!),
                ],
              ],
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            formatPaymentAmount(payment.amount),
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          PaymentStatusChip(status: payment.status),
                        ],
                      ),
                      const SizedBox(height: 16),
                      PaymentInfoRow(label: 'Booking ID', value: payment.bookingId),
                      PaymentInfoRow(
                        label: 'Order ID',
                        value: payment.orderId ?? '-',
                      ),
                      PaymentInfoRow(
                        label: 'Method',
                        value: payment.paymentMethod ?? payment.paymentType ?? '-',
                      ),
                      PaymentInfoRow(
                        label: 'Status',
                        value: payment.transactionStatus.value,
                      ),
                      PaymentInfoRow(
                        label: 'Created at',
                        value: formatPaymentDate(payment.createdAt),
                      ),
                      PaymentInfoRow(
                        label: 'Expires at',
                        value: formatPaymentDate(payment.expiredAt),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _PayButton(
                isLoading: actionState.isLoading,
                onPressed: () async {
                  final targetPayment = payment.canOpenPaymentPage
                      ? payment
                      : await _createPayment(context, ref);
                  if (targetPayment == null) return;

                  final opened = await _openPaymentUrl(context, targetPayment);
                  if (opened) {
                    _refreshPayment();
                    ref.invalidate(paymentDetailProvider(targetPayment.id));
                  }
                },
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => context.push(AppRoutes.paymentDetailPath(payment.id)),
                icon: const Icon(Icons.receipt_long_outlined),
                label: const Text('Payment Detail'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<bool> _createAndOpenPayment(BuildContext context, WidgetRef ref) async {
    final payment = await _createPayment(context, ref);
    if (payment == null) return false;
    return _openPaymentUrl(context, payment);
  }

  Future<Payment?> _createPayment(BuildContext context, WidgetRef ref) async {
    final created = await ref
        .read(paymentControllerProvider.notifier)
        .createMidtransPayment(widget.bookingId);
    if (!created) return null;

    final payment = ref.read(createdPaymentProvider);
    if (payment == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment response is invalid')),
        );
      }
      return null;
    }
    return payment;
  }

  Future<bool> _openPaymentUrl(BuildContext context, Payment payment) async {
    final redirectUrl = payment.snapRedirectUrl;
    if (redirectUrl == null || redirectUrl.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment URL is not available yet')),
        );
      }
      return false;
    }

    final uri = Uri.tryParse(redirectUrl);
    if (uri == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment URL is invalid')),
        );
      }
      return false;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (opened) {
      _openedPaymentPage = true;
    }
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open payment page')),
      );
    }

    return opened;
  }

  void _refreshPayment() {
    ref.invalidate(latestPaymentByBookingProvider(widget.bookingId));
    ref.invalidate(paymentHistoryProvider);
  }
}

class _PayButton extends StatelessWidget {
  const _PayButton({
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.open_in_new),
      label: const Text('Bayar Sekarang'),
    );
  }
}
