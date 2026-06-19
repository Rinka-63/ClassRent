import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../shared/domain/entities/app_user.dart';
import '../../../../shared/presentation/widgets/admin_nav_bar.dart';
import '../../../../shared/presentation/widgets/role_aware_nav_bar.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isAdmin =
        user?.role == UserRole.admin || user?.role == UserRole.superAdmin;

    return AppScaffold(
      title: isAdmin ? 'Profile' : 'Profile',
      bottomNavigationBar: isAdmin
          ? const AdminNavBar(currentPath: AppRoutes.profile)
          : const RoleAwareNavBar(currentPath: AppRoutes.profile),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ProfileCard(user: user),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: user == null
                ? null
                : () => _showEditProfileSheet(context, ref, user),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit Profile'),
          ),
          const SizedBox(height: 16),
          _SecurityCard(
            user: user,
            onPressed: () {
              if (user?.role == UserRole.admin ||
                  user?.role == UserRole.superAdmin) {
                context.push(AppRoutes.adminHistory);
              } else {
                context.push(AppRoutes.support);
              }
            },
          ),
          const SizedBox(height: 16),
          _SectionTitle(text: isAdmin ? 'Admin Tools' : 'Account'),
          const SizedBox(height: 12),
          if (isAdmin) ...[
            _SettingsTile(
              icon: Icons.meeting_room_outlined,
              title: 'Room Management',
              subtitle: 'CRUD rooms, facilities, and schedules',
              onTap: () => context.push(AppRoutes.roomManagement),
            ),
            _SettingsTile(
              icon: Icons.calendar_month_outlined,
              title: 'Booking Management',
              subtitle: 'Monitor and confirm bookings',
              onTap: () => context.push(AppRoutes.bookingManagement),
            ),
            _SettingsTile(
              icon: Icons.insights_outlined,
              title: 'Reports',
              subtitle: 'Automatic summary and revenue insight',
              onTap: () => context.push(AppRoutes.adminReports),
            ),
            _SettingsTile(
              icon: Icons.history_outlined,
              title: 'Activity History',
              subtitle: 'Audit logs and recent admin actions',
              onTap: () => context.push(AppRoutes.adminHistory),
            ),
          ] else ...[
            _SettingsTile(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              subtitle: 'Email and booking alerts',
              onTap: () => context.push(AppRoutes.notifications),
            ),
            _SettingsTile(
              icon: Icons.favorite_border,
              title: 'Saved Rooms',
              subtitle: 'Your favorite rooms and places',
              onTap: () => context.push(AppRoutes.favorites),
            ),
            _SettingsTile(
              icon: Icons.support_agent_outlined,
              title: 'Support Tickets',
              subtitle: 'Help desk and contact support',
              onTap: () => context.push(AppRoutes.support),
            ),
          ],
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).logout();
              if (context.mounted) {
                context.go(AppRoutes.login);
              }
            },
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'ClassRent',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditProfileSheet(
    BuildContext context,
    WidgetRef ref,
    AppUser user,
  ) async {
    final nameController = TextEditingController(text: user.fullName);
    final phoneController = TextEditingController(text: user.phone ?? '');
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        var isSaving = false;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Edit Profile',
                      style: Theme.of(sheetContext).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Full name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Full name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone number',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setSheetState(() => isSaving = true);
                              final success = await ref
                                  .read(authControllerProvider.notifier)
                                  .updateProfile(
                                    fullName: nameController.text,
                                    phone: phoneController.text,
                                  );
                              if (!sheetContext.mounted) return;
                              setSheetState(() => isSaving = false);
                              if (success) {
                                Navigator.pop(sheetContext);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Profile updated')),
                                );
                              } else {
                                final message = ref
                                        .read(authControllerProvider)
                                        .errorMessage ??
                                    'Unable to update profile.';
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(message)),
                                );
                              }
                            },
                      child: isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    nameController.dispose();
    phoneController.dispose();
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.user});

  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    final roleLabel = switch (user?.role) {
      UserRole.superAdmin => 'Super Admin',
      UserRole.admin => 'Agency Admin',
      _ => 'User',
    };

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(Icons.person,
                    color: AppColors.primary, size: 36),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.fullName ?? 'Guest',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(user?.email ?? '-',
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 10),
                    _RoleBadge(text: roleLabel),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                icon: Icons.badge_outlined,
                label:
                    user?.agencyId == null ? 'No Agency Yet' : 'Agency Linked',
              ),
              _InfoChip(
                icon: Icons.verified_outlined,
                label: user?.agencyIsActive == false
                    ? 'Inactive'
                    : 'Account Active',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SecurityCard extends StatelessWidget {
  const _SecurityCard({required this.user, required this.onPressed});

  final AppUser? user;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final lastLogin = DateFormat('dd MMM yyyy, HH:mm')
        .format(DateTime.now().subtract(const Duration(hours: 2)));

    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'Security Status',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Strong',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Last login: $lastLogin',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.16),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
            ),
            child: Text(user?.role == UserRole.user
                ? 'Contact Support'
                : 'Audit History'),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppColors.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.secondaryContainer.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.secondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.outlineVariant),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }
}
