import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/supabase/supabase_client_provider.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../../data/repositories/supabase_rooms_repository.dart';
import '../../domain/entities/room.dart';
import '../../domain/repositories/rooms_repository.dart';

final roomsRepositoryProvider = Provider<RoomsRepository>((ref) {
  return SupabaseRoomsRepository(
    SupabaseService(ref.watch(supabaseClientProvider)),
  );
});

final roomsProvider = FutureProvider<List<Room>>((ref) async {
  final result = await ref.watch(roomsRepositoryProvider).getRooms();
  return result.match((failure) => throw failure, (rooms) => rooms);
});

final roomDetailProvider = FutureProvider.family<Room, String>((ref, id) async {
  final result = await ref.watch(roomsRepositoryProvider).getRoomById(id);
  return result.match((failure) => throw failure, (room) => room);
});

final roomFacilitiesProvider = FutureProvider.family<List<String>, String>((ref, roomId) async {
  final result = await ref.watch(roomsRepositoryProvider).getRoomFacilities(roomId);
  return result.match((failure) => throw failure, (data) => data);
});

final roomSchedulesProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, roomId) async {
  final result = await ref.watch(roomsRepositoryProvider).getRoomSchedules(roomId);
  return result.match((failure) => throw failure, (data) => data);
});
