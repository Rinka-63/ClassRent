import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_brand_mark.dart';

class WelcomeAuthScreen extends StatelessWidget {
  const WelcomeAuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  const Center(child: AppBrandMark(size: 56)),
                  const SizedBox(height: 24),
                  Text(
                    'ClassRent',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    strings.tr(
                      'Sewa ruangan untuk kelas, meeting, dan acara Anda',
                      'Rent rooms for classes, meetings, and events',
                    ),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FilledButton(
                          onPressed: () => context.push(
                            AppRoutes.login,
                            extra: {'isRegister': false},
                          ),
                          child: Text(strings.tr('Masuk', 'Sign In')),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => context.push(
                            AppRoutes.login,
                            extra: {'isRegister': true},
                          ),
                          child: Text(
                            strings.tr('Daftar Baru', 'Create Account'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '© 2024 ClassRent. Seluruh hak cipta dilindungi.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.outline,
                        ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
