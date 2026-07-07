import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/supabase/supabase_client_provider.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../../data/repositories/supabase_payment_repository.dart';
import '../../domain/repositories/payment_repository.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return SupabasePaymentRepository(
    SupabaseService(ref.watch(supabaseClientProvider)),
  );
});
