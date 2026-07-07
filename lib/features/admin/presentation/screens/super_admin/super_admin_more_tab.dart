import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_routes.dart';
import '../../../../../core/theme/app_colors.dart';
import 'super_admin_agency_withdrawal_tab.dart';
import 'super_admin_audit_log_tab.dart';
import 'super_admin_room_tab.dart';

class SuperAdminMoreTab extends ConsumerStatefulWidget {
  const SuperAdminMoreTab({super.key});

  @override
  ConsumerState<SuperAdminMoreTab> createState() => _SuperAdminMoreTabState();
}

class _SuperAdminMoreTabState extends ConsumerState<SuperAdminMoreTab> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (_currentIndex == 1) {
      return _SubPageShell(
        title: 'Manajemen Ruangan',
        onBack: () => setState(() => _currentIndex = 0),
        child: const SuperAdminRoomTab(),
      );
    }
    if (_currentIndex == 2) {
      return _SubPageShell(
        title: 'Log Audit',
        onBack: () => setState(() => _currentIndex = 0),
        child: const SuperAdminAuditLogTab(),
      );
    }
    if (_currentIndex == 3) {
      return _SubPageShell(
        title: 'Pencairan Agensi',
        onBack: () => setState(() => _currentIndex = 0),
        child: const SuperAdminAgencyWithdrawalTab(),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Menu Lainnya', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        _MenuTile(
          icon: Icons.meeting_room_outlined,
          title: 'Manajemen Ruangan',
          subtitle: 'Kelola ruangan lintas agensi',
          onTap: () => setState(() => _currentIndex = 1),
        ),
        _MenuTile(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Pencairan Agensi',
          subtitle: 'Setujui atau tolak pengajuan pencairan',
          onTap: () => setState(() => _currentIndex = 3),
        ),
        _MenuTile(
          icon: Icons.receipt_long_outlined,
          title: 'Log Audit',
          subtitle: 'Riwayat aktivitas sistem',
          onTap: () => setState(() => _currentIndex = 2),
        ),
        _MenuTile(
          icon: Icons.settings_outlined,
          title: 'Pengaturan',
          subtitle: 'Preferensi super admin',
          onTap: () => context.push(AppRoutes.superAdminSettings),
        ),
      ],
    );
  }
}

class _SubPageShell extends StatelessWidget {
  const _SubPageShell({
    required this.title,
    required this.onBack,
    required this.child,
  });

  final String title;
  final VoidCallback onBack;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: onBack,
          ),
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side:
            BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
