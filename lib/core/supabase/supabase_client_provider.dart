import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_env.dart';

final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  if (!AppEnv.hasSupabaseConfig) return null;
  return SupabaseClient(AppEnv.supabaseUrl, AppEnv.supabaseAnonKey);
});
