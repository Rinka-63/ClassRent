import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';

class RoleAwareNavBar extends StatelessWidget {
  const RoleAwareNavBar({required this.currentPath, super.key});

  final String currentPath;

  @override
  Widget build(BuildContext context) {
    final items = <_NavItem>[
      const _NavItem(AppRoutes.home, Icons.home_outlined, 'Home'),
      const _NavItem(AppRoutes.search, Icons.search, 'Search'),
      const _NavItem(AppRoutes.bookings, Icons.calendar_today_outlined, 'Booking'),
      const _NavItem(AppRoutes.payments, Icons.payments_outlined, 'Payment'),
      const _NavItem(AppRoutes.favorites, Icons.favorite_border, 'Saved'),
      const _NavItem(AppRoutes.profile, Icons.person_outline, 'Profile'),
    ];

    final index = items.indexWhere((item) => item.path == currentPath);

    return NavigationBar(
      selectedIndex: index < 0 ? 0 : index,
      destinations: [
        for (final item in items)
          NavigationDestination(icon: Icon(item.icon), label: item.label),
      ],
      onDestinationSelected: (index) => context.go(items[index].path),
    );
  }
}

class _NavItem {
  const _NavItem(this.path, this.icon, this.label);

  final String path;
  final IconData icon;
  final String label;
}
