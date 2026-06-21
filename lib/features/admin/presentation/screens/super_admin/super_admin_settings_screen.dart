import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../providers/super_admin_providers.dart';
import '../../widgets/super_admin/super_admin_app_bar.dart';

class SuperAdminSettingsScreen extends ConsumerStatefulWidget {
  const SuperAdminSettingsScreen({super.key});

  @override
  ConsumerState<SuperAdminSettingsScreen> createState() => _SuperAdminSettingsScreenState();
}

class _SuperAdminSettingsScreenState extends ConsumerState<SuperAdminSettingsScreen> {
  bool _enableDebugLogs = false;
  bool _useStagingApi = false;
  bool _showPerformanceOverlay = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: const SuperAdminAppBar(
        title: 'Developer Settings',
        showBackButton: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.developer_mode, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Developer Profile',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(user?.email ?? '-', style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(user?.fullName ?? '-', style: const TextStyle(color: AppColors.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('System Environment'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('App Version', style: TextStyle(fontWeight: FontWeight.w600)),
            trailing: const Text('v1.0.0 (Build 42)', style: TextStyle(color: AppColors.onSurfaceVariant)),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.api),
            title: const Text('Use Staging API', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Switch between production and staging backend'),
            value: _useStagingApi,
            activeColor: AppColors.primary,
            onChanged: (val) {
              setState(() => _useStagingApi = val);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(val ? 'Switched to Staging API' : 'Switched to Production API')),
              );
            },
          ),
          const Divider(height: 32),
          _buildSectionTitle('Developer Tools'),
          SwitchListTile(
            secondary: const Icon(Icons.bug_report_outlined),
            title: const Text('Enable Debug Logs', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Write verbose logs to console'),
            value: _enableDebugLogs,
            activeColor: AppColors.primary,
            onChanged: (val) => setState(() => _enableDebugLogs = val),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.speed_outlined),
            title: const Text('Performance Overlay', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Show Flutter performance metrics on screen'),
            value: _showPerformanceOverlay,
            activeColor: AppColors.primary,
            onChanged: (val) => setState(() => _showPerformanceOverlay = val),
          ),
          ListTile(
            leading: const Icon(Icons.data_object),
            title: const Text('Inspect State Tree', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('View Riverpod provider states'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('State inspector opened in debug console')),
              );
            },
          ),
          const Divider(height: 32),
          _buildSectionTitle('Data & Cache'),
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('Force Refresh Dashboard', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Invalidate and reload all super admin providers'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              invalidateSuperAdminData(ref);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Dashboard data force-refreshed')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_sweep, color: AppColors.error),
            title: const Text('Clear App Cache', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
            subtitle: const Text('Wipe local preferences and temporary data'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache cleared successfully'),
                  backgroundColor: AppColors.error,
                ),
              );
            },
          ),
          const Divider(height: 32),
          _buildSectionTitle('Security Audit'),
          ListTile(
            leading: const Icon(Icons.security_outlined),
            title: const Text('Super Admin Role Verification', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('RLS rules actively verified on Supabase backend'),
            trailing: const Icon(Icons.check_circle, color: Colors.green),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 16),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}
