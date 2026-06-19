import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_card.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../shared/presentation/widgets/role_aware_nav_bar.dart';
import '../../../rooms/presentation/widgets/room_card.dart';
import '../providers/favorites_provider.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteIds = ref.watch(favoritesProvider);
    final favoriteRooms = ref.watch(favoriteRoomsProvider);

    return AppScaffold(
      title: 'Favorites',
      bottomNavigationBar:
          const RoleAwareNavBar(currentPath: AppRoutes.favorites),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(favoritesProvider.notifier).load();
          ref.invalidate(favoriteRoomsProvider);
        },
        child: favoriteIds.when(
          loading: () => const LoadingView(),
          error: (error, _) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ErrorCard(
                message: error.toString(),
                onRetry: () => ref.read(favoritesProvider.notifier).load(),
              ),
            ],
          ),
          data: (ids) {
            if (ids.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  EmptyState(
                    title: 'No favorite rooms yet',
                    message: 'Tap the heart icon on a room to save it here.',
                  ),
                ],
              );
            }

            return favoriteRooms.when(
              loading: () => const LoadingView(),
              error: (error, _) => ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ErrorCard(
                    message: error.toString(),
                    onRetry: () => ref.invalidate(favoriteRoomsProvider),
                  ),
                ],
              ),
              data: (rooms) {
                if (rooms.isEmpty) {
                  return ListView(
                    children: const [
                      SizedBox(height: 120),
                      EmptyState(
                        title: 'Favorite rooms are unavailable',
                        message:
                            'Saved rooms may have been removed or deactivated.',
                      ),
                    ],
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: rooms.length,
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 380,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.84,
                  ),
                  itemBuilder: (_, index) => RoomCard(room: rooms[index]),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
