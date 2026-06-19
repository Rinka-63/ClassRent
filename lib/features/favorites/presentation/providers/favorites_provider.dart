import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/supabase/supabase_client_provider.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../rooms/domain/entities/room.dart';
import '../../data/repositories/supabase_favorites_repository.dart';

final favoritesRepositoryProvider =
    Provider<SupabaseFavoritesRepository>((ref) {
  return SupabaseFavoritesRepository(
    SupabaseService(ref.watch(supabaseClientProvider)),
  );
});

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, AsyncValue<Set<String>>>((ref) {
  return FavoritesNotifier(ref)..load();
});

final favoriteRoomsProvider = FutureProvider<List<Room>>((ref) async {
  final ids = ref.watch(favoritesProvider).valueOrNull ?? <String>{};
  final result =
      await ref.watch(favoritesRepositoryProvider).getFavoriteRooms(ids);
  return result.match((failure) => throw failure, (rooms) => rooms);
});

class FavoritesNotifier extends StateNotifier<AsyncValue<Set<String>>> {
  FavoritesNotifier(this._ref) : super(const AsyncValue.loading());

  final Ref _ref;

  String? get _userId => _ref.read(currentUserProvider)?.id;

  Future<void> load() async {
    final userId = _userId;
    if (userId == null) {
      state = const AsyncValue.data(<String>{});
      return;
    }

    state = const AsyncValue.loading();
    final result =
        await _ref.read(favoritesRepositoryProvider).getFavoriteIds(userId);
    state = result.match(
      (failure) => AsyncValue.error(failure, StackTrace.current),
      (ids) => AsyncValue.data(ids),
    );
  }

  Future<bool> toggle(String roomId) async {
    final userId = _userId;
    if (userId == null) return false;

    final previous = state.valueOrNull ?? <String>{};
    final wasFavorite = previous.contains(roomId);
    final next = {...previous};
    if (wasFavorite) {
      next.remove(roomId);
    } else {
      next.add(roomId);
    }

    state = AsyncValue.data(next);
    final repository = _ref.read(favoritesRepositoryProvider);
    final result = wasFavorite
        ? await repository.removeFavorite(userId: userId, roomId: roomId)
        : await repository.addFavorite(userId: userId, roomId: roomId);

    return result.match(
      (failure) {
        state = AsyncValue.data(previous);
        return false;
      },
      (_) {
        _ref.invalidate(favoriteRoomsProvider);
        return true;
      },
    );
  }
}
