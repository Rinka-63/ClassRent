import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/providers/app_settings_provider.dart';
import '../../../../core/providers/shared_prefs_provider.dart';
import '../../../../core/theme/app_colors.dart';

class LanguageSelectionScreen extends ConsumerWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final locale = ref.watch(appSettingsProvider).locale;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () async {
                    await ref
                        .read(hasSeenLanguageSelectionProvider.notifier)
                        .setHasSeen(true);
                    if (context.mounted) {
                      context.go(AppRoutes.onboarding);
                    }
                  },
                  child: Text(strings.skip),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                strings.chooseLanguage,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                strings.chooseLanguageSubtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 28),
              _LanguageOption(
                title: strings.indonesian,
                isSelected: locale.languageCode == 'id',
                onTap: () =>
                    ref.read(appSettingsProvider.notifier).setLanguage('id'),
              ),
              const SizedBox(height: 12),
              _LanguageOption(
                title: strings.english,
                isSelected: locale.languageCode == 'en',
                onTap: () =>
                    ref.read(appSettingsProvider.notifier).setLanguage('en'),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    await ref
                        .read(hasSeenLanguageSelectionProvider.notifier)
                        .setHasSeen(true);
                    if (context.mounted) {
                      context.go(AppRoutes.onboarding);
                    }
                  },
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: Text(strings.continueLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.outlineVariant,
            width: isSelected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
