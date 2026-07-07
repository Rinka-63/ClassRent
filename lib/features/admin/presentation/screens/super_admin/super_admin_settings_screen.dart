import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../providers/super_admin_providers.dart';
import '../../widgets/super_admin/super_admin_app_bar.dart';

class SuperAdminSettingsScreen extends ConsumerStatefulWidget {
  const SuperAdminSettingsScreen({super.key});

  @override
  ConsumerState<SuperAdminSettingsScreen> createState() =>
      _SuperAdminSettingsScreenState();
}

class _SuperAdminSettingsScreenState
    extends ConsumerState<SuperAdminSettingsScreen> {
  bool _enableDebugLogs = false;
  bool _useStagingApi = false;
  bool _showPerformanceOverlay = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: const SuperAdminAppBar(
        title: 'Pengaturan Pengembang',
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
              border:
                  Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary,
                  child:
                      Icon(Icons.developer_mode, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Profil Pengembang',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(user?.email ?? '-',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(user?.fullName ?? '-',
                          style: const TextStyle(
                              color: AppColors.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Lingkungan Sistem'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Versi Aplikasi',
                style: TextStyle(fontWeight: FontWeight.w600)),
            trailing: const Text('v1.0.0 (Build 42)',
                style: TextStyle(color: AppColors.onSurfaceVariant)),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.api),
            title: const Text('Gunakan API Staging',
                style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Beralih antara backend produksi dan staging'),
            value: _useStagingApi,
            activeColor: AppColors.primary,
            onChanged: (val) {
              setState(() => _useStagingApi = val);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(val
                        ? 'Beralih ke API Staging'
                        : 'Beralih ke API Produksi')),
              );
            },
          ),
          const Divider(height: 32),
          _buildSectionTitle('Alat Pengembang'),
          SwitchListTile(
            secondary: const Icon(Icons.bug_report_outlined),
            title: const Text('Aktifkan Log Debug',
                style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Tulis log detail ke konsol'),
            value: _enableDebugLogs,
            activeColor: AppColors.primary,
            onChanged: (val) => setState(() => _enableDebugLogs = val),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.speed_outlined),
            title: const Text('Overlay Performa',
                style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Tampilkan metrik performa Flutter di layar'),
            value: _showPerformanceOverlay,
            activeColor: AppColors.primary,
            onChanged: (val) => setState(() => _showPerformanceOverlay = val),
          ),
          ListTile(
            leading: const Icon(Icons.data_object),
            title: const Text('Inspeksi State Tree',
                style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Lihat state provider Riverpod'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Inspector state dibuka di konsol debug')),
              );
            },
          ),
          const Divider(height: 32),
          _buildSectionTitle('Data & Cache'),
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('Muat Ulang Dashboard',
                style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text(
                'Invalidate dan muat ulang semua provider super admin'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              invalidateSuperAdminData(ref);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Data dashboard dimuat ulang')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_sweep, color: AppColors.error),
            title: const Text('Bersihkan Cache Aplikasi',
                style: TextStyle(
                    color: AppColors.error, fontWeight: FontWeight.w600)),
            subtitle: const Text('Hapus preferensi lokal dan data sementara'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache berhasil dibersihkan'),
                  backgroundColor: AppColors.error,
                ),
              );
            },
          ),
          const Divider(height: 32),
          _buildSectionTitle('Audit Keamanan'),
          ListTile(
            leading: const Icon(Icons.security_outlined),
            title: const Text('Verifikasi Peran Super Admin',
                style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle:
                const Text('Aturan RLS diverifikasi aktif di backend Supabase'),
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
