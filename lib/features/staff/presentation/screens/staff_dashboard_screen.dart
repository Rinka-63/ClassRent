import 'package:flutter/material.dart';

import '../../../../core/widgets/app_scaffold.dart';

class StaffDashboardScreen extends StatelessWidget {
  const StaffDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'Staff Dashboard',
      body: Center(
        child: Text('Staff check-in, check-out, and assigned room operations.'),
      ),
    );
  }
}
