import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/super_admin_providers.dart';

class SuperAdminNavBar extends ConsumerWidget {
  const SuperAdminNavBar({super.key});

  static const _items = [
    _NavItem(0, Icons.dashboard_outlined, Icons.dashboard, 'Beranda'),
    _NavItem(1, Icons.apartment_outlined, Icons.apartment, 'Agency'),
    _NavItem(2, Icons.people_outline, Icons.people, 'User'),
    _NavItem(3, Icons.meeting_room_outlined, Icons.meeting_room, 'Room'),
    _NavItem(4, Icons.receipt_long_outlined, Icons.receipt_long, 'Audit Log'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(superAdminTabIndexProvider);

    return NavigationBar(
      selectedIndex: index,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: [
        for (final item in _items)
          NavigationDestination(
            icon: Icon(item.icon),
            selectedIcon: Icon(item.selectedIcon),
            label: item.label,
          ),
      ],
      onDestinationSelected: (selected) =>
          ref.read(superAdminTabIndexProvider.notifier).state = selected,
    );
  }
}

class _NavItem {
  const _NavItem(this.index, this.icon, this.selectedIcon, this.label);

  final int index;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}
