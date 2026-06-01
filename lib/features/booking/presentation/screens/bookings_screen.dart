import 'package:flutter/material.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../shared/presentation/widgets/role_aware_nav_bar.dart';

class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'Bookings',
      bottomNavigationBar: RoleAwareNavBar(currentPath: AppRoutes.bookings),
      body: EmptyState(
        title: 'No bookings yet',
        message: 'Booking history will read from the bookings table.',
      ),
    );
  }
}
