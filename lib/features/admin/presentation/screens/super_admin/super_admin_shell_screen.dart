import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../providers/super_admin_providers.dart';
import '../../widgets/super_admin/super_admin_app_bar.dart';
import '../../widgets/super_admin/super_admin_nav_bar.dart';
import 'super_admin_agency_tab.dart';
import 'super_admin_home_tab.dart';
import 'super_admin_more_tab.dart';
import 'super_admin_payment_tab.dart';
import 'super_admin_user_tab.dart';

class SuperAdminShellScreen extends ConsumerWidget {
  const SuperAdminShellScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabIndex = ref.watch(superAdminTabIndexProvider);
    final strings = AppStrings.of(context);
    final titles = [
      strings.home,
      strings.agency,
      strings.users,
      strings.payments,
      strings.menu,
    ];

    return Scaffold(
      appBar: SuperAdminAppBar(title: titles[tabIndex]),
      body: IndexedStack(
        index: tabIndex,
        children: const [
          SuperAdminHomeTab(),
          SuperAdminAgencyTab(),
          SuperAdminUserTab(),
          SuperAdminPaymentTab(),
          SuperAdminMoreTab(),
        ],
      ),
      bottomNavigationBar: const SuperAdminNavBar(),
    );
  }
}
