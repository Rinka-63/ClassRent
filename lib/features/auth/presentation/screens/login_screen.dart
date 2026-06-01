import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../shared/domain/entities/app_user.dart';
import '../providers/auth_providers.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('ClassRent', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  const Text('Starter auth screen wired for future Supabase Auth.'),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () {
                      ref.read(currentUserProvider.notifier).state = const AppUser(
                            id: 'local-user',
                            email: 'student@classrent.local',
                            fullName: 'ClassRent Student',
                            role: UserRole.user,
                          );
                      context.go(AppRoutes.home);
                    },
                    child: const Text('Continue as User'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () {
                      ref.read(currentUserProvider.notifier).state = const AppUser(
                            id: 'local-admin',
                            email: 'admin@classrent.local',
                            fullName: 'ClassRent Admin',
                            role: UserRole.admin,
                          );
                      context.go(AppRoutes.admin);
                    },
                    child: const Text('Continue as Admin'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
