import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _themeModeKey = 'app_theme_mode';
const _localeKey = 'app_locale';

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return SharedPreferences.getInstance();
});

final appThemeModeProvider = StateNotifierProvider<AppThemeModeController, ThemeMode>((ref) {
  return AppThemeModeController(ref);
});

final appLocaleProvider = StateNotifierProvider<AppLocaleController, Locale?>((ref) {
  return AppLocaleController(ref);
});

class AppThemeModeController extends StateNotifier<ThemeMode> {
  AppThemeModeController(this._ref) : super(ThemeMode.system) {
    _load();
  }

  final Ref _ref;

  Future<void> _load() async {
    final prefs = await _ref.read(sharedPreferencesProvider.future);
    final value = prefs.getString(_themeModeKey);
    state = switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await _ref.read(sharedPreferencesProvider.future);
    await prefs.setString(
      _themeModeKey,
      switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      },
    );
  }
}

class AppLocaleController extends StateNotifier<Locale?> {
  AppLocaleController(this._ref) : super(null) {
    _load();
  }

  final Ref _ref;

  Future<void> _load() async {
    final prefs = await _ref.read(sharedPreferencesProvider.future);
    final value = prefs.getString(_localeKey);
    state = switch (value) {
      'id' => const Locale('id'),
      'en' => const Locale('en'),
      _ => null,
    };
  }

  Future<void> setLocale(Locale? locale) async {
    state = locale;
    final prefs = await _ref.read(sharedPreferencesProvider.future);
    if (locale == null) {
      await prefs.remove(_localeKey);
      return;
    }
    await prefs.setString(_localeKey, locale.languageCode);
  }
}
