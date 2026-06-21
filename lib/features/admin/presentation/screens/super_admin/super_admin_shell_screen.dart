import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/super_admin_providers.dart';
import '../../widgets/super_admin/super_admin_app_bar.dart';
import '../../widgets/super_admin/super_admin_nav_bar.dart';
import 'super_admin_agency_tab.dart';
import 'super_admin_audit_log_tab.dart';
import 'super_admin_home_tab.dart';
import 'super_admin_room_tab.dart';
import 'super_admin_user_tab.dart';

class SuperAdminShellScreen extends ConsumerWidget {
  const SuperAdminShellScreen({super.key});

  static const _titles = ['Beranda', 'Agency', 'User', 'Room', 'Audit Log'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabIndex = ref.watch(superAdminTabIndexProvider);

    return Scaffold(
      appBar: SuperAdminAppBar(title: _titles[tabIndex]),
      body: IndexedStack(
        index: tabIndex,
        children: const [
          SuperAdminHomeTab(),
          SuperAdminAgencyTab(),
          SuperAdminUserTab(),
          SuperAdminRoomTab(),
          SuperAdminAuditLogTab(),
        ],
      ),
      bottomNavigationBar: const SuperAdminNavBar(),
    );
  }
}
