import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/supabase/supabase_client_provider.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../../data/repositories/supabase_agency_repository.dart';
import '../../domain/entities/agency.dart';
import '../../domain/entities/platform_stats.dart';
import '../../domain/entities/platform_user.dart';
import '../../domain/repositories/agency_repository.dart';

final agencyRepositoryProvider = Provider<AgencyRepository>((ref) {
  return SupabaseAgencyRepository(
    SupabaseService(ref.watch(supabaseClientProvider)),
  );
});

final agenciesProvider = FutureProvider<List<Agency>>((ref) async {
  final result = await ref.watch(agencyRepositoryProvider).getAgencies();
  return result.match((failure) => throw failure, (agencies) => agencies);
});

final platformStatsProvider = FutureProvider<PlatformStats>((ref) async {
  final result = await ref.watch(agencyRepositoryProvider).getPlatformStats();
  return result.match((failure) => throw failure, (stats) => stats);
});

final platformUsersProvider = FutureProvider<List<PlatformUser>>((ref) async {
  final result = await ref.watch(agencyRepositoryProvider).getPlatformUsers();
  return result.match((failure) => throw failure, (users) => users);
});
