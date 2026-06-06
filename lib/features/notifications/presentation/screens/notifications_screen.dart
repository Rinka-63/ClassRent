import 'package:flutter/material.dart';

import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/empty_state.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'Notifications',
      body: EmptyState(
        title: 'Inbox is empty',
        message: 'Realtime notifications will subscribe to notifications rows.',
      ),
    );
  }
}
