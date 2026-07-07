import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/storage_service.dart';
import '../supabase/supabase_client_provider.dart';
import '../supabase/supabase_service.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(
    SupabaseService(ref.watch(supabaseClientProvider)),
  );
});
