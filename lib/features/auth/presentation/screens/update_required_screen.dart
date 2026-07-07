import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/providers/app_update_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_brand_mark.dart';

class UpdateRequiredScreen extends ConsumerWidget {
  const UpdateRequiredScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final updateStatus = ref.watch(appUpdateStatusProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: updateStatus.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => _UpdateContent(
              title: strings.tr('Update Diperlukan', 'Update Required'),
              message: strings.tr(
                'Versi baru ClassRent tersedia. Perbarui aplikasi untuk melanjutkan.',
                'A new ClassRent version is available. Update the app to continue.',
              ),
              versionLabel: strings.tr('Versi terbaru', 'Latest version'),
              latestVersionName: currentAppVersionName,
              storeUrl: defaultPlayStoreUrl,
              onRetry: () => ref.invalidate(appUpdateStatusProvider),
            ),
            data: (status) => _UpdateContent(
              title: strings.tr('Update Diperlukan', 'Update Required'),
              message: strings.tr(status.messageId, status.messageEn),
              versionLabel: strings.tr('Versi terbaru', 'Latest version'),
              latestVersionName: status.latestVersionName,
              storeUrl: status.storeUrl,
              onRetry: () => ref.invalidate(appUpdateStatusProvider),
            ),
          ),
        ),
      ),
    );
  }
}

class _UpdateContent extends StatelessWidget {
  const _UpdateContent({
    required this.title,
    required this.message,
    required this.versionLabel,
    required this.latestVersionName,
    required this.storeUrl,
    required this.onRetry,
  });

  final String title;
  final String message;
  final String versionLabel;
  final String latestVersionName;
  final String storeUrl;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: AppBrandMark(size: 92)),
        const SizedBox(height: 28),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
                height: 1.45,
              ),
        ),
        const SizedBox(height: 20),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$versionLabel: $latestVersionName',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        FilledButton.icon(
          onPressed: () => _openStore(storeUrl),
          icon: const Icon(Icons.open_in_new),
          label: Text(strings.tr('Update Sekarang', 'Update Now')),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: onRetry,
          child: Text(strings.tr('Cek Lagi', 'Check Again')),
        ),
      ],
    );
  }

  Future<void> _openStore(String storeUrl) async {
    final uri = Uri.tryParse(storeUrl);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
