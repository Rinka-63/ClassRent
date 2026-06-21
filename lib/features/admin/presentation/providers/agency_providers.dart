import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/supabase/supabase_client_provider.dart';
import '../../../../../core/supabase/supabase_service.dart';
import '../../data/repositories/supabase_agency_repository.dart';
import '../../domain/repositories/agency_repository.dart';

final agencyRepositoryProvider = Provider<AgencyRepository>((ref) {
  return SupabaseAgencyRepository(
    SupabaseService(ref.watch(supabaseClientProvider)),
  );
});
