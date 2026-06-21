import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../shared/presentation/widgets/role_aware_nav_bar.dart';
import '../providers/favorites_provider.dart';
import '../providers/rooms_providers.dart';
import '../widgets/room_card.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesState = ref.watch(favoritesProvider);
    final roomsState = ref.watch(roomsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorit'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(favoritesProvider);
              ref.invalidate(roomsProvider);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: favoritesState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 12),
                Text('Terjadi kesalahan', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('$err', style: const TextStyle(color: AppColors.onSurfaceVariant), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(favoritesProvider),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Coba lagi'),
                ),
              ],
            ),
          ),
          data: (favIds) {
            if (favIds.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.favorite_border, size: 64, color: AppColors.outlineVariant),
                    const SizedBox(height: 16),
                    Text(
                      'Belum ada favorit',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        'Ketuk ikon ❤️ pada ruangan yang kamu suka\nuntuk menyimpannya di sini.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.onSurfaceVariant, height: 1.5),
                      ),
                    ),
                  ],
                ),
              );
            }

            return roomsState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => const Center(child: Text('Gagal memuat ruangan')),
              data: (rooms) {
                final favoriteRooms = rooms.where((r) => favIds.contains(r.id)).toList();

                if (favoriteRooms.isEmpty) {
                  return const EmptyState(
                    title: 'Belum ada favorit',
                    message: 'Ruangan yang Anda sukai akan muncul di sini.',
                  );
                }

                // Use GridView with same aspect ratio as home screen
                // This avoids the Expanded/Spacer issue in RoomCard
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: favoriteRooms.length,
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 240, // Match home screen layout
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.72,
                  ),
                  itemBuilder: (context, index) {
                    return RoomCard(room: favoriteRooms[index]);
                  },
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: const RoleAwareNavBar(currentPath: AppRoutes.favorites),
    );
  }
}
