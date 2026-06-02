import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/app_env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  if (AppEnv.hasSupabaseConfig) {
    await Supabase.initialize(
      url: AppEnv.supabaseUrl,
      anonKey: AppEnv.supabaseAnonKey,
    );
  }

  runApp(const ProviderScope(child: ClassRentApp()));
}
