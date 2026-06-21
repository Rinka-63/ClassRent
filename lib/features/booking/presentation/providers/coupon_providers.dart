import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/supabase/supabase_client_provider.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../../data/repositories/supabase_coupon_repository.dart';
import '../../domain/repositories/coupon_repository.dart';

final couponRepositoryProvider = Provider<CouponRepository>((ref) {
  return SupabaseCouponRepository(
    SupabaseService(ref.watch(supabaseClientProvider)),
  );
});
