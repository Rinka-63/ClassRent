import 'package:flutter/material.dart';

import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/empty_state.dart';

class SupportTicketsScreen extends StatelessWidget {
  const SupportTicketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'Support Tickets',
      body: EmptyState(
        title: 'No support tickets',
        message: 'Tickets will use support_tickets and ticket_messages.',
      ),
    );
  }
}
