import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/l10n/app_strings.dart';

class AdminNavBar extends StatelessWidget {
  const AdminNavBar({required this.currentPath, super.key});

  final String currentPath;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final items = <_NavItem>[
      _NavItem(AppRoutes.admin, Icons.home_outlined, strings.home),
      _NavItem(
          AppRoutes.roomManagement, Icons.meeting_room_outlined, strings.rooms),
      _NavItem(AppRoutes.bookingManagement, Icons.calendar_month_outlined,
          strings.bookings),
      _NavItem(AppRoutes.adminHistory, Icons.history_outlined, strings.history),
      _NavItem(AppRoutes.profile, Icons.person_outline, strings.profile),
    ];
    final index = items.indexWhere((item) => item.path == currentPath);

    return NavigationBar(
      selectedIndex: index < 0 ? 0 : index,
      destinations: [
        for (final item in items)
          NavigationDestination(icon: Icon(item.icon), label: item.label),
      ],
      onDestinationSelected: (selected) => context.go(items[selected].path),
    );
  }
}

class _NavItem {
  const _NavItem(this.path, this.icon, this.label);

  final String path;
  final IconData icon;
  final String label;
}
