import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';

abstract class FavoritesRepository {
  /// Toggle a room's favorite status for a user. Returns true if added, false if removed.
  Future<Either<Failure, bool>> toggleFavorite(String userId, String roomId);
  
  /// Get list of favorite room IDs for a user
  Future<Either<Failure, List<String>>> getFavoriteRoomIds(String userId);
}
