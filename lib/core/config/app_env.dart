import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppEnv {
  const AppEnv._();

  static String get supabaseUrl {
    return _normalizeSupabaseUrl(dotenv.env['SUPABASE_URL'] ?? '');
  }

  static String get supabaseAnonKey {
    return dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  }

  static bool get hasSupabaseConfig {
    return supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
  }

  static String _normalizeSupabaseUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';

    final withoutRest = trimmed.replaceFirst(RegExp(r'/rest/v1/?$'), '');
    return withoutRest.replaceFirst(RegExp(r'/$'), '');
  }
}
