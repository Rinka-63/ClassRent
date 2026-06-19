import 'package:fpdart/fpdart.dart';

import '../../../../core/constants/supabase_tables.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/supabase/supabase_service.dart';

class SupabaseFavoritesRepository {
  const SupabaseFavoritesRepository(this._service);

  final SupabaseService _service;

  Future<Either<Failure, Set<String>>> getFavoriteRoomIds(String userId) async {
    try {
      final rows = await _service.requireClient
          .from(SupabaseTables.userFavorites)
          .select('room_id')
          .eq('user_id', userId);
      return right(rows.map((row) => row['room_id'] as String).toSet());
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  Future<Either<Failure, Unit>> addFavorite(String userId, String roomId) async {
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

  Future<Either<Failure, Unit>> removeFavorite(String userId, String roomId) async {
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
