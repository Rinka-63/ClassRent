import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/providers/app_settings_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../shared/domain/entities/app_user.dart';
import '../../../../shared/presentation/widgets/admin_nav_bar.dart';
import '../../../../shared/presentation/widgets/role_aware_nav_bar.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../../../notifications/presentation/widgets/notification_badge.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final settings = ref.watch(appSettingsProvider);
    final isAdmin =
        user?.role == UserRole.admin || user?.role == UserRole.superAdmin;
    final strings = AppStrings.of(context);
    final unreadNotifications = ref.watch(unreadCountProvider).valueOrNull ?? 0;

    return AppScaffold(
      title: strings.profile,
      bottomNavigationBar: isAdmin
          ? const AdminNavBar(currentPath: AppRoutes.profile)
          : const RoleAwareNavBar(currentPath: AppRoutes.profile),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(authControllerProvider.notifier).refreshCurrentUser();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _ProfileHeader(user: user),
            const SizedBox(height: 20),
            _SectionTitle(text: strings.generalSettings),
            _SettingsTile(
              icon: Icons.language_outlined,
              title: strings.appLanguage,
              onTap: () => _showLanguageSheet(
                context,
                ref,
                selectedLanguageCode: settings.locale.languageCode,
              ),
            ),
            const SizedBox(height: 8),
            if (isAdmin) ...[
              _SectionTitle(text: strings.adminTools),
              _SettingsTile(
                icon: Icons.meeting_room_outlined,
                title: strings.tr('Manajemen Ruangan', 'Room Management'),
                onTap: () => context.push(AppRoutes.roomManagement),
              ),
              _SettingsTile(
                icon: Icons.calendar_month_outlined,
                title: strings.tr('Manajemen Pesanan', 'Booking Management'),
                onTap: () => context.push(AppRoutes.bookingManagement),
              ),
              _SettingsTile(
                icon: Icons.insights_outlined,
                title: strings.tr('Laporan', 'Reports'),
                onTap: () => context.push(AppRoutes.adminReports),
              ),
              _SettingsTile(
                icon: Icons.business_outlined,
                title: strings.tr('Profil Agensi', 'Agency Profile'),
                onTap: () => context.push(AppRoutes.agencyProfile),
              ),
              const SizedBox(height: 8),
            ] else ...[
              _SectionTitle(text: strings.account),
              _SettingsTile(
                icon: Icons.edit_outlined,
                title: strings.profileEdit,
                onTap: () => _showEditProfileSheet(context, ref, user),
              ),
              _SettingsTile(
                icon: Icons.favorite_border,
                title: strings.savedRooms,
                onTap: () => context.push(AppRoutes.favorites),
              ),
              const SizedBox(height: 8),
              _SettingsTile(
                icon: Icons.notifications_outlined,
                title: strings.notifications,
                badgeCount: unreadNotifications,
                onTap: () => context.push(AppRoutes.notifications),
              ),
              _SettingsTile(
                icon: Icons.support_agent_outlined,
                title: strings.help,
                onTap: () => context.push(AppRoutes.support),
              ),
              _SettingsTile(
                icon: Icons.info_outline,
                title: strings.about,
                onTap: () => _showInfoDialog(
                  context,
                  title: strings.aboutClassRent,
                  message: strings.tr(
                    'ClassRent membantu pengguna menemukan, memesan, dan mengelola ruang kelas secara praktis.',
                    'ClassRent helps users find, book, and manage classrooms easily.',
                  ),
                ),
              ),
              _SettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: strings.privacyPolicy,
                onTap: () => _showInfoDialog(
                  context,
                  title: strings.privacyPolicy,
                  message: strings.tr(
                    'Data digunakan untuk autentikasi, booking, pembayaran, dan notifikasi aplikasi.',
                    'Data is used for authentication, bookings, payments, and app notifications.',
                  ),
                ),
              ),
              _SettingsTile(
                icon: Icons.description_outlined,
                title: strings.termsAndConditions,
                onTap: () => _showInfoDialog(
                  context,
                  title: strings.termsAndConditions,
                  message: strings.tr(
                    'Pemesanan mengikuti status ruangan, persetujuan admin, dan status pembayaran yang berlaku.',
                    'Bookings follow room availability, admin approval, and applicable payment status.',
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                await ref.read(authControllerProvider.notifier).logout();
                if (context.mounted) context.go(AppRoutes.login);
              },
              icon: const Icon(Icons.logout),
              label: Text(strings.logout),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                minimumSize: const Size.fromHeight(52),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                strings.appVersion,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showInfoDialog(
  BuildContext context, {
  required String title,
  required String message,
}) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppStrings.of(context).closeLabel),
        ),
      ],
    ),
  );
}

Future<void> _showLanguageSheet(
  BuildContext context,
  WidgetRef ref, {
  required String selectedLanguageCode,
}) async {
  final selected = ValueNotifier<String>(selectedLanguageCode);

  await showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: ValueListenableBuilder<String>(
          valueListenable: selected,
          builder: (context, value, _) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.of(context).appLanguage,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  _LanguageOptionTile(
                    title: AppStrings.of(context).indonesian,
                    selected: value == 'id',
                    onTap: () => selected.value = 'id',
                  ),
                  _LanguageOptionTile(
                    title: AppStrings.of(context).english,
                    selected: value == 'en',
                    onTap: () => selected.value = 'en',
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () async {
                      await ref
                          .read(appSettingsProvider.notifier)
                          .setLanguage(selected.value);
                      if (context.mounted) Navigator.pop(sheetContext);
                    },
                    icon: const Icon(Icons.save_outlined),
                    label: Text(AppStrings.of(context).save),
                  ),
                ],
              ),
            );
          },
        ),
      );
    },
  );
  selected.dispose();
}

class _LanguageOptionTile extends StatelessWidget {
  const _LanguageOptionTile({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      trailing: Icon(
        selected ? Icons.check_circle : Icons.circle_outlined,
        color: selected ? AppColors.primary : AppColors.outline,
      ),
    );
  }
}

Future<void> _showEditProfileSheet(
  BuildContext context,
  WidgetRef ref,
  AppUser? user,
) async {
  if (user == null) return;
  final nameController = TextEditingController(text: user.fullName);
  var isSaving = false;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                18,
                20,
                MediaQuery.viewInsetsOf(context).bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.of(context).profileEdit,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: AppStrings.of(context).profileName,
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: isSaving
                        ? null
                        : () async {
                            final name = nameController.text.trim();
                            if (name.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppStrings.of(context).emptyNameError,
                                  ),
                                ),
                              );
                              return;
                            }
                            setState(() => isSaving = true);
                            final success = await ref
                                .read(authControllerProvider.notifier)
                                .updateProfile(
                                  fullName: name,
                                );
                            if (!context.mounted) return;
                            setState(() => isSaving = false);
                            if (success) {
                              await ref
                                  .read(authControllerProvider.notifier)
                                  .refreshCurrentUser();
                              if (!context.mounted) return;
                              Navigator.pop(sheetContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppStrings.of(context).profileUpdated,
                                  ),
                                ),
                              );
                            } else {
                              final message = ref
                                      .read(authControllerProvider)
                                      .errorMessage ??
                                  AppStrings.of(context).profileUpdateFailed;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(message)),
                              );
                            }
                          },
                    icon: isSaving
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      AppStrings.of(context)
                          .tr('Simpan Profil', 'Save Profile'),
                    ),
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
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});

  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final roleLabel = switch (user?.role) {
      UserRole.superAdmin => strings.superAdminLabel,
      UserRole.admin => strings.adminAgencyLabel,
      _ => strings.userLabel,
    };
    final initials = (user?.fullName.isNotEmpty == true)
        ? user!.fullName[0].toUpperCase()
        : '?';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.primaryContainer,
            child: Text(
              initials,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            user?.fullName ?? strings.classRentUser,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            user?.email ?? strings.emailPlaceholder,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              roleLabel,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: NotificationBadge(
        count: badgeCount,
        child: Icon(icon, color: AppColors.primary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.outline),
    );
  }
}
