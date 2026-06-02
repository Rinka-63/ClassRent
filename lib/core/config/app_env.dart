import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppEnv {
  const AppEnv._();

  static const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
  static const _supabaseUrlFromDefine = String.fromEnvironment('SUPABASE_URL');
  static const _supabaseAnonKeyFromDefine = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  static String get supabaseUrl {
    final configuredUrl = _supabaseUrlFromDefine.isNotEmpty
        ? _supabaseUrlFromDefine
        : dotenv.env['SUPABASE_URL'] ?? '';

    return _normalizeSupabaseUrl(configuredUrl);
  }

  static String get supabaseAnonKey => _supabaseAnonKeyFromDefine.isNotEmpty
      ? _supabaseAnonKeyFromDefine
      : dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  static bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static String _normalizeSupabaseUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.endsWith('/rest/v1/')) {
      return trimmed.substring(0, trimmed.length - '/rest/v1/'.length);
    }
    if (trimmed.endsWith('/rest/v1')) {
      return trimmed.substring(0, trimmed.length - '/rest/v1'.length);
    }
    return trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
  }
}
