import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../../domain/repositories/favorites_repository.dart';

class SupabaseFavoritesRepository implements FavoritesRepository {
  SupabaseFavoritesRepository(this._service);

  final SupabaseService _service;

  @override
  Future<Either<Failure, bool>> toggleFavorite(String userId, String roomId) async {
    try {
      final existing = await _service.requireClient
          .from('favorite_rooms')
          .select()
          .eq('user_id', userId)
          .eq('room_id', roomId)
          .maybeSingle();

      if (existing != null) {
        // Remove favorite
        await _service.requireClient
            .from('favorite_rooms')
            .delete()
            .eq('user_id', userId)
            .eq('room_id', roomId);
        return right(false);
      } else {
        // Add favorite
        await _service.requireClient.from('favorite_rooms').insert({
          'user_id': userId,
          'room_id': roomId,
        });
        return right(true);
      }
    } catch (e) {
      return left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getFavoriteRoomIds(String userId) async {
    try {
      final result = await _service.requireClient
          .from('favorite_rooms')
          .select('room_id')
          .eq('user_id', userId);

      final ids = (result as List).map((e) => e['room_id'] as String).toList();
      return right(ids);
    } catch (e) {
      return left(UnknownFailure(e.toString()));
    }
  }
}
