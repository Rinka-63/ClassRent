import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../shared/presentation/widgets/role_aware_nav_bar.dart';

class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Bookings',
      actions: [
        IconButton(
          onPressed: () => context.push(AppRoutes.payments),
          icon: const Icon(Icons.payments_outlined),
        ),
      ],
      bottomNavigationBar: const RoleAwareNavBar(currentPath: AppRoutes.bookings),
      body: Center(
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
      ),
    );
  }
}
