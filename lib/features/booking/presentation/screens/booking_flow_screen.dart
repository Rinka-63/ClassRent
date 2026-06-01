import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
                final nextIndex = (state.step.index + 1).clamp(0, BookingStep.values.length - 1);
                ref.read(bookingFlowProvider.notifier).goTo(BookingStep.values[nextIndex]);
              },
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
