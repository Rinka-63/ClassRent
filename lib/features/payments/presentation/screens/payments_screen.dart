import 'package:flutter/material.dart';

import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/empty_state.dart';

class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'Payments',
      body: EmptyState(
        title: 'No payments yet',
        message: 'Payment records will map to Midtrans-backed payments.',
      ),
    );
  }
}
