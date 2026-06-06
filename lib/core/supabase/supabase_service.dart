import 'package:supabase_flutter/supabase_flutter.dart';

import '../error/app_exception.dart';

class SupabaseService {
  const SupabaseService(this._client);

  final SupabaseClient? _client;

  SupabaseClient get requireClient {
    final client = _client;
    if (client == null) {
      throw const AppException(
        'Supabase is not configured. Pass SUPABASE_URL and SUPABASE_ANON_KEY.',
        code: 'missing_supabase_config',
      );
    }
    return client;
  }
}
