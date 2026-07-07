import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/supabase/supabase_client_provider.dart';
import '../../../../../core/supabase/supabase_service.dart';
import '../../data/repositories/supabase_agency_repository.dart';
import '../../domain/entities/agency_withdrawal.dart';
import '../../domain/repositories/agency_repository.dart';

final agencyRepositoryProvider = Provider<AgencyRepository>((ref) {
  return SupabaseAgencyRepository(
    SupabaseService(ref.watch(supabaseClientProvider)),
  );
});

final myAgencyWithdrawalsProvider =
    FutureProvider.family<List<AgencyWithdrawal>, String>((ref, adminId) async {
  final result =
      await ref.watch(agencyRepositoryProvider).getMyWithdrawals(adminId);
  return result.match((failure) => throw failure, (withdrawals) => withdrawals);
});
