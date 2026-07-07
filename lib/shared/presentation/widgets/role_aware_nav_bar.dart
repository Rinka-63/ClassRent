import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/l10n/app_strings.dart';

class RoleAwareNavBar extends ConsumerWidget {
  const RoleAwareNavBar({required this.currentPath, super.key});

  final String currentPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final items = [
      _NavItem(AppRoutes.home, Icons.home_outlined, Icons.home, strings.home),
      _NavItem(
        AppRoutes.search,
        Icons.meeting_room_outlined,
        Icons.meeting_room,
        strings.rooms,
      ),
      _NavItem(
        AppRoutes.bookings,
        Icons.receipt_long_outlined,
        Icons.receipt_long,
        strings.bookings,
      ),
      _NavItem(
        AppRoutes.profile,
        Icons.person_outline,
        Icons.person,
        strings.profile,
      ),
    ];
    final selectedIndex = items
        .indexWhere((item) => item.path == currentPath)
        .clamp(0, items.length - 1);

    return NavigationBar(
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      selectedIndex: selectedIndex,
      destinations: [
        for (final item in items)
          NavigationDestination(
            icon: Icon(item.icon),
            selectedIcon: Icon(item.selectedIcon),
            label: item.label,
          ),
      ],
      onDestinationSelected: (index) => context.go(items[index].path),
    );
  }
}

class _NavItem {
  const _NavItem(this.path, this.icon, this.selectedIcon, this.label);

  final String path;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}
