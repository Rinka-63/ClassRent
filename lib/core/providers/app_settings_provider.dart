import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'shared_prefs_provider.dart';

class AppSettings {
  const AppSettings({required this.locale});

  final Locale locale;

  AppSettings copyWith({Locale? locale}) {
    return AppSettings(locale: locale ?? this.locale);
  }
}

class AppSettingsNotifier extends Notifier<AppSettings> {
  static const _languageKey = 'app_language_code';

  @override
  AppSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final languageCode = prefs.getString(_languageKey) ?? 'id';
    return AppSettings(locale: Locale(languageCode));
  }

  Future<void> setLanguage(String languageCode) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_languageKey, languageCode);
    state = state.copyWith(locale: Locale(languageCode));
  }
}

final appSettingsProvider = NotifierProvider<AppSettingsNotifier, AppSettings>(
  AppSettingsNotifier.new,
);
