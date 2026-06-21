import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';

class SuperAdminAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const SuperAdminAppBar({
    required this.title,
    this.showBackButton = false,
    super.key,
  });

  final String title;
  final bool showBackButton;

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppBar(
      toolbarHeight: 72,
      centerTitle: true,
      title: Column(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            'ClassRent Super Admin Panel',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  letterSpacing: 0.2,
                ),
          ),
        ],
      ),
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(AppRoutes.superAdmin);
                }
              },
            )
          : Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Center(
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.school_outlined, color: Colors.white, size: 22),
                ),
              ),
            ),
      actions: [
        if (!showBackButton)
          IconButton(
            tooltip: 'Settings',
            onPressed: () => context.push(AppRoutes.superAdminSettings),
            icon: const Icon(Icons.settings_outlined),
          ),
        IconButton(
          tooltip: 'Logout',
          onPressed: () async {
            await ref.read(authControllerProvider.notifier).logout();
            if (context.mounted) context.go(AppRoutes.login);
          },
          icon: const Icon(Icons.logout),
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}
