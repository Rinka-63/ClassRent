import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_routes.dart';
import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_brand_mark.dart';
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
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    return AppBar(
      toolbarHeight: 64,
      centerTitle: true,
      title: Column(
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            strings.superAdminPanel,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.onPrimary.withValues(alpha: 0.82),
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
          : const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Center(
                child: AppBrandMark(
                  size: 36,
                  backgroundColor: AppColors.onPrimary,
                ),
              ),
            ),
      actions: [
        if (!showBackButton)
          IconButton(
            tooltip: strings.settings,
            onPressed: () => context.push(AppRoutes.superAdminSettings),
            icon: const Icon(Icons.settings_outlined),
          ),
        IconButton(
          tooltip: strings.logout,
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
