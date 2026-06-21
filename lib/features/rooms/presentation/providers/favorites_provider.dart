import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/supabase/supabase_client_provider.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/supabase_favorites_repository.dart';
import '../../domain/repositories/favorites_repository.dart';

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  return SupabaseFavoritesRepository(
    SupabaseService(ref.watch(supabaseClientProvider)),
  );
});

class FavoritesNotifier extends StateNotifier<AsyncValue<Set<String>>> {
  FavoritesNotifier(this._repository, this._userId) : super(const AsyncValue.loading()) {
    if (_userId != null) {
      _loadFavorites();
    } else {
      state = const AsyncValue.data({});
    }
  }

  final FavoritesRepository _repository;
  final String? _userId;

  Future<void> _loadFavorites() async {
    final result = await _repository.getFavoriteRoomIds(_userId!);
    state = result.fold(
      (failure) => AsyncValue.error(failure, StackTrace.current),
      (ids) => AsyncValue.data(ids.toSet()),
    );
  }

  Future<void> toggleFavorite(String roomId) async {
    if (_userId == null) return;

    // Optimistic UI update
    final currentSet = state.valueOrNull ?? {};
    final isCurrentlyFav = currentSet.contains(roomId);
    
    if (isCurrentlyFav) {
      state = AsyncValue.data(Set.from(currentSet)..remove(roomId));
    } else {
      state = AsyncValue.data(Set.from(currentSet)..add(roomId));
    }

    final result = await _repository.toggleFavorite(_userId!, roomId);
    
    result.fold(
      (failure) {
        // Revert on error
        state = AsyncValue.data(currentSet);
      },
      (isAdded) {
        // Ensure state matches server response
        if (isAdded) {
          state = AsyncValue.data(Set.from(currentSet)..add(roomId));
        } else {
          state = AsyncValue.data(Set.from(currentSet)..remove(roomId));
        }
      },
    );
  }
}

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, AsyncValue<Set<String>>>((ref) {
  final user = ref.watch(currentUserProvider);
  return FavoritesNotifier(ref.watch(favoritesRepositoryProvider), user?.id);
});
