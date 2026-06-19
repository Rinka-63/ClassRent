import 'package:fpdart/fpdart.dart';

import '../../../../core/constants/supabase_tables.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../../../rooms/data/dto/room_dto.dart';
import '../../../rooms/domain/entities/room.dart';

class SupabaseFavoritesRepository {
  const SupabaseFavoritesRepository(this._service);

  final SupabaseService _service;

  Future<Either<Failure, Set<String>>> getFavoriteIds(String userId) async {
    try {
      final rows = await _service.requireClient
          .from(SupabaseTables.userFavorites)
          .select('room_id')
          .eq('user_id', userId);
      return right(rows.map((row) => row['room_id'].toString()).toSet());
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  Future<Either<Failure, List<Room>>> getFavoriteRooms(
      Set<String> roomIds) async {
    try {
      if (roomIds.isEmpty) return right(const <Room>[]);
      final rows = await _service.requireClient
          .from(SupabaseTables.rooms)
          .select()
          .inFilter('id', roomIds.toList())
          .eq('is_active', true)
          .isFilter('deleted_at', null);
      return right(rows.map(RoomDto.fromJson).toList());
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  Future<Either<Failure, Unit>> addFavorite({
    required String userId,
    required String roomId,
  }) async {
    try {
      await _service.requireClient.from(SupabaseTables.userFavorites).upsert({
        'user_id': userId,
        'room_id': roomId,
      });
      return right(unit);
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  Future<Either<Failure, Unit>> removeFavorite({
    required String userId,
    required String roomId,
  }) async {
    try {
      await _service.requireClient
          .from(SupabaseTables.userFavorites)
          .delete()
          .eq('user_id', userId)
          .eq('room_id', roomId);
      return right(unit);
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }
}
