import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'core/l10n/app_strings.dart';
import 'core/providers/app_settings_provider.dart';
import 'core/providers/app_update_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class ClassRentApp extends ConsumerStatefulWidget {
  const ClassRentApp({super.key});

  @override
  ConsumerState<ClassRentApp> createState() => _ClassRentAppState();
}

class _ClassRentAppState extends ConsumerState<ClassRentApp> {
  bool _optionalUpdateShown = false;

  @override
  void initState() {
    super.initState();
    ref.listenManual(
      appUpdateStatusProvider,
      (previous, next) {
        final status = next.valueOrNull;
        if (status == null ||
            status.requiresUpdate ||
            !status.hasOptionalUpdate ||
            _optionalUpdateShown) {
          return;
        }
        _optionalUpdateShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showOptionalUpdateDialog(status);
        });
      },
      fireImmediately: true,
    );
  }

  Future<void> _showOptionalUpdateDialog(AppUpdateStatus status) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update tersedia'),
        content: Text(
          'Versi ${status.latestVersionName} tersedia. Anda bisa memperbarui sekarang atau nanti.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Nanti'),
          ),
          FilledButton(
            onPressed: () async {
              final uri = Uri.tryParse(status.storeUrl);
              if (uri != null) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            child: const Text('Update Sekarang'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final settings = ref.watch(appSettingsProvider);

    return MaterialApp.router(
      title: 'ClassRent',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      themeMode: ThemeMode.light,
      locale: settings.locale,
      supportedLocales: const [
        Locale('id'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        AppStrings.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
