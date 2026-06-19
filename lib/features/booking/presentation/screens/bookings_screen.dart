import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/error_card.dart';
import '../../../../shared/presentation/widgets/role_aware_nav_bar.dart';
import '../../../payments/presentation/screens/payment_widgets.dart';
import '../providers/booking_admin_providers.dart';

class BookingsScreen extends ConsumerWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsValue = ref.watch(userBookingsProvider);

    return AppScaffold(
      title: 'Bookings',
      actions: [
        IconButton(
          onPressed: () => context.push(AppRoutes.payments),
          icon: const Icon(Icons.payments_outlined),
        ),
      ],
      bottomNavigationBar: const RoleAwareNavBar(currentPath: AppRoutes.bookings),
      body: bookingsValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(16),
          child: ErrorCard(message: error.toString()),
        ),
        data: (bookings) {
          if (bookings.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.inbox_outlined, size: 48),
                    const SizedBox(height: 12),
                    Text('No bookings yet', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    const Text(
                      'Booking history will read from the bookings table.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => context.push(AppRoutes.payments),
                      icon: const Icon(Icons.payments_outlined),
                      label: const Text('Payment History'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, index) {
              final booking = bookings[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Booking ${booking.id.substring(0, 8)}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                          Text(booking.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('${booking.bookingDate.toIso8601String().split('T').first} ${booking.startTime} - ${booking.endTime}'),
                      const SizedBox(height: 8),
                      Text(formatPaymentAmount(booking.finalPrice)),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () => context.push(AppRoutes.paymentCheckoutPath(booking.id)),
                        icon: const Icon(Icons.payments_outlined),
                        label: const Text('Bayar Sekarang'),
                      ),
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
}
