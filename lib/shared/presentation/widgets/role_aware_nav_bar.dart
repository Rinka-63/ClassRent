import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';

class RoleAwareNavBar extends StatelessWidget {
  const RoleAwareNavBar({required this.currentPath, super.key});

  final String currentPath;

  @override
  Widget build(BuildContext context) {
    final items = <_NavItem>[
      const _NavItem(AppRoutes.home, Icons.home_outlined, Icons.home, 'Beranda'),
      const _NavItem(AppRoutes.bookings, Icons.calendar_today_outlined, Icons.calendar_today, 'Booking'),
      const _NavItem(AppRoutes.favorites, Icons.favorite_border, Icons.favorite, 'Favorit'),
      const _NavItem(AppRoutes.profile, Icons.person_outline, Icons.person, 'Profil'),
    ];

    return NavigationBar(
      selectedIndex: items.indexWhere((item) => item.path == currentPath).clamp(0, items.length - 1),
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
