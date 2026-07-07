import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../providers/super_admin_providers.dart';

class SuperAdminNavBar extends ConsumerWidget {
  const SuperAdminNavBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(superAdminTabIndexProvider);
    final strings = AppStrings.of(context);
    final items = [
      _NavItem(Icons.dashboard_outlined, Icons.dashboard, strings.home),
      _NavItem(Icons.apartment_outlined, Icons.apartment, strings.agency),
      _NavItem(Icons.people_outline, Icons.people, strings.users),
      _NavItem(Icons.payments_outlined, Icons.payments, strings.payments),
      _NavItem(Icons.grid_view_outlined, Icons.grid_view, strings.menu),
    ];

    return NavigationBar(
      selectedIndex: index,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: [
        for (final item in items)
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
  const _NavItem(this.icon, this.selectedIcon, this.label);

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}
