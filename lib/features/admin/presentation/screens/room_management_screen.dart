import 'package:flutter/material.dart';

import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/empty_state.dart';

class RoomManagementScreen extends StatelessWidget {
  const RoomManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'Room Management',
      body: EmptyState(
        title: 'Room manager ready',
        message: 'CRUD screens will map exactly to rooms, room_images, and room_facilities.',
      ),
    );
  }
}
