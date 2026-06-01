import 'package:flutter/material.dart';

import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/empty_state.dart';

class BookingManagementScreen extends StatelessWidget {
  const BookingManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'Booking Management',
      body: EmptyState(
        title: 'Booking manager ready',
        message: 'Admin and staff flows will update booking status under RLS.',
      ),
    );
  }
}
