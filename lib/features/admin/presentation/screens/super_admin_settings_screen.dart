import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/settings/app_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/domain/entities/app_user.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class SuperAdminSettingsScreen extends ConsumerWidget {
  const SuperAdminSettingsScreen({super.key});

  static const _appName = 'ClassRent';
  static const _appVersion = '0.1.0';
  static const _buildNumber = '1';
  static const _copyright = 'Copyright © 2026 ClassRent Team';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(appThemeModeProvider);
    final locale = ref.watch(appLocaleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionCard(
            title: 'Appearance',
            children: [
              SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode_outlined)),
                  ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode_outlined)),
                  ButtonSegment(value: ThemeMode.system, label: Text('System'), icon: Icon(Icons.settings_suggest_outlined)),
                ],
                selected: {themeMode},
                onSelectionChanged: (value) => ref.read(appThemeModeProvider.notifier).setThemeMode(value.first),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Language',
            subtitle: 'Localization structure ready for future expansion.',
            children: [
              SegmentedButton<Locale?>(
                segments: const [
                  ButtonSegment(value: Locale('id'), label: Text('Bahasa Indonesia')),
                  ButtonSegment(value: Locale('en'), label: Text('English')),
                  ButtonSegment(value: null, label: Text('System')),
                ],
                selected: {locale},
                onSelectionChanged: (value) => ref.read(appLocaleProvider.notifier).setLocale(value.first),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'About Application',
            children: const [
              _InfoRow(label: 'App Name', value: _appName),
              _InfoRow(label: 'App Version', value: _appVersion),
              _InfoRow(label: 'Build Number', value: _buildNumber),
              _InfoRow(label: 'Copyright', value: _copyright),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Developer',
            children: const [
              _InfoRow(label: 'Team', value: 'Developed by ClassRent Team'),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).logout();
              if (context.mounted) context.go(AppRoutes.login);
            },
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.children,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant)),
            ],
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(color: AppColors.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
