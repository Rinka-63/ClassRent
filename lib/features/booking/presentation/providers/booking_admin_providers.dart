import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/supabase/supabase_client_provider.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/supabase_booking_repository.dart';
import '../../domain/entities/booking.dart';
import '../../domain/repositories/booking_repository.dart';

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return SupabaseBookingRepository(
    SupabaseService(ref.watch(supabaseClientProvider)),
  );
});

final agencyBookingsProvider = FutureProvider<List<Booking>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const [];
  final result = await ref.watch(bookingRepositoryProvider).getBookingsForAgency(user.id);
  return result.match((failure) => throw Exception(failure.message), (data) => data);
});

final roomBookingsProvider = FutureProvider.family<List<Booking>, String>((ref, roomId) async {
  final result = await ref.watch(bookingRepositoryProvider).getBookingsForRoom(roomId);
  return result.match((failure) => throw Exception(failure.message), (data) => data);
});
