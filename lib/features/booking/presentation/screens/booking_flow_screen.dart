import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../providers/booking_flow_provider.dart';

class BookingFlowScreen extends ConsumerWidget {
  const BookingFlowScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bookingFlowProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('New Booking')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(value: (state.step.index + 1) / BookingStep.values.length),
            const SizedBox(height: 24),
            Text('Step: ${state.step.name}', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('Booking state machine placeholder for date, time, coupon, and payment.'),
            const Spacer(),
            FilledButton(
              onPressed: () {
                if (state.step == BookingStep.payment) {
                  final bookingId = state.createdBookingId;
                  if (bookingId == null || bookingId.isEmpty) {
                    context.push(AppRoutes.payments);
                    return;
                  }
                  context.push(AppRoutes.paymentCheckoutPath(bookingId));
                  return;
                }
                final nextIndex = (state.step.index + 1).clamp(0, BookingStep.values.length - 1);
                ref.read(bookingFlowProvider.notifier).goTo(BookingStep.values[nextIndex]);
              },
              child: Text(state.step == BookingStep.payment ? 'Open Payment' : 'Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
