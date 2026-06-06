import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_routes.dart';
import '../widgets/empty_state.dart';

class UnauthorizedScreen extends StatelessWidget {
  const UnauthorizedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const EmptyState(
        title: 'Unauthorized',
        message: 'Your account role cannot access this area.',
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go(AppRoutes.home),
        label: const Text('Go Home'),
        icon: const Icon(Icons.home_outlined),
      ),
    );
  }
}
