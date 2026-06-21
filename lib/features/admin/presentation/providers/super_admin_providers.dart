import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/supabase/supabase_client_provider.dart';
import '../../../../../core/supabase/supabase_service.dart';
import '../../data/repositories/supabase_super_admin_repository.dart';
import '../../domain/entities/agency.dart';
import '../../domain/entities/audit_log_entry.dart';
import '../../domain/entities/platform_analytics.dart';
import '../../domain/entities/platform_payment.dart';
import '../../domain/entities/platform_room.dart';
import '../../domain/entities/platform_stats.dart';
import '../../domain/entities/platform_user.dart';
import '../../domain/repositories/super_admin_repository.dart';

final superAdminRepositoryProvider = Provider<SuperAdminRepository>((ref) {
  return SupabaseSuperAdminRepository(
    SupabaseService(ref.watch(supabaseClientProvider)),
  );
});

final superAdminTabIndexProvider = StateProvider<int>((ref) => 0);

final platformStatsProvider = FutureProvider<PlatformStats>((ref) async {
  final result = await ref.watch(superAdminRepositoryProvider).getPlatformStats();
  return result.match((failure) => throw failure, (stats) => stats);
});

final platformAnalyticsProvider = FutureProvider<PlatformAnalytics>((ref) async {
  final result = await ref.watch(superAdminRepositoryProvider).getPlatformAnalytics();
  return result.match((failure) => throw failure, (data) => data);
});

final agenciesProvider = FutureProvider<List<Agency>>((ref) async {
  final result = await ref.watch(superAdminRepositoryProvider).getAgencies();
  return result.match((failure) => throw failure, (agencies) => agencies);
});

final agencyDetailProvider = FutureProvider.family<Agency, String>((ref, id) async {
  final result = await ref.watch(superAdminRepositoryProvider).getAgencyDetail(id);
  return result.match((failure) => throw failure, (agency) => agency);
});

final platformUsersProvider = FutureProvider<List<PlatformUser>>((ref) async {
  final result = await ref.watch(superAdminRepositoryProvider).getPlatformUsers();
  return result.match((failure) => throw failure, (users) => users);
});

final platformUserDetailProvider =
    FutureProvider.family<PlatformUser, String>((ref, id) async {
  final result = await ref.watch(superAdminRepositoryProvider).getPlatformUserDetail(id);
  return result.match((failure) => throw failure, (user) => user);
});

final platformRoomsProvider = FutureProvider<List<PlatformRoom>>((ref) async {
  final result = await ref.watch(superAdminRepositoryProvider).getPlatformRooms();
  return result.match((failure) => throw failure, (rooms) => rooms);
});

final platformRoomDetailProvider =
    FutureProvider.family<PlatformRoom, String>((ref, id) async {
  final result = await ref.watch(superAdminRepositoryProvider).getPlatformRoomDetail(id);
  return result.match((failure) => throw failure, (room) => room);
});

final platformAuditLogsProvider = FutureProvider<List<AuditLogEntry>>((ref) async {
  final result = await ref.watch(superAdminRepositoryProvider).getAuditLogs();
  return result.match((failure) => throw failure, (logs) => logs);
});

final recentUsersProvider = FutureProvider<List<PlatformUser>>((ref) async {
  final result = await ref.watch(superAdminRepositoryProvider).getRecentUsers();
  return result.match((failure) => throw failure, (users) => users);
});

final recentAgenciesProvider = FutureProvider<List<Agency>>((ref) async {
  final result = await ref.watch(superAdminRepositoryProvider).getRecentAgencies();
  return result.match((failure) => throw failure, (agencies) => agencies);
});

final recentPaymentsProvider = FutureProvider<List<PlatformPayment>>((ref) async {
  final result = await ref.watch(superAdminRepositoryProvider).getRecentPayments();
  return result.match((failure) => throw failure, (payments) => payments);
});

final recentBookingsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final result = await ref.watch(superAdminRepositoryProvider).getRecentBookings();
  return result.match((failure) => throw failure, (bookings) => bookings);
});

final userBookingsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, userId) async {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return const [];
  final rows = await client
      .from('bookings')
      .select('id,room_id,booking_date,status,final_price,created_at,rooms(name)')
      .eq('user_id', userId)
      .order('created_at', ascending: false)
      .limit(20);
  return rows.cast<Map<String, dynamic>>();
});

final userPaymentsProvider =
    FutureProvider.family<List<PlatformPayment>, String>((ref, userId) async {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return const [];
  final rows = await client
      .from('payments')
      .select('id,booking_id,user_id,gross_amount,transaction_status,payment_method,created_at')
      .eq('user_id', userId)
      .order('created_at', ascending: false)
      .limit(20);
  return rows
      .map(
        (row) => PlatformPayment(
          id: row['id'] as String,
          bookingId: row['booking_id'] as String,
          userId: row['user_id'] as String,
          amount: (row['gross_amount'] as num?)?.toDouble() ?? 0,
          status: row['transaction_status'] as String? ?? 'pending',
          paymentMethod: row['payment_method'] as String?,
          createdAt: DateTime.parse(row['created_at'].toString()),
        ),
      )
      .toList();
});

final agencyRoomsProvider =
    FutureProvider.family<List<PlatformRoom>, String>((ref, agencyId) async {
  final rooms = await ref.watch(platformRoomsProvider.future);
  return rooms.where((room) => room.agencyId == agencyId).toList();
});

void invalidateSuperAdminData(WidgetRef ref) {
  ref.invalidate(platformStatsProvider);
  ref.invalidate(platformAnalyticsProvider);
  ref.invalidate(agenciesProvider);
  ref.invalidate(platformUsersProvider);
  ref.invalidate(platformRoomsProvider);
  ref.invalidate(platformAuditLogsProvider);
  ref.invalidate(recentUsersProvider);
  ref.invalidate(recentAgenciesProvider);
  ref.invalidate(recentPaymentsProvider);
  ref.invalidate(recentBookingsProvider);
}
