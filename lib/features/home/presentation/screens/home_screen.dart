import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_card.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../shared/presentation/widgets/role_aware_nav_bar.dart';
import '../../../rooms/presentation/providers/rooms_providers.dart';
import '../../../rooms/presentation/widgets/room_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsValue = ref.watch(roomsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ClassRent'),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.notifications),
            icon: const Icon(Icons.notifications_none),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(roomsProvider),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              readOnly: true,
              onTap: () => context.push(AppRoutes.search),
              decoration: const InputDecoration(
                hintText: 'Search for rooms...',
                prefixIcon: Icon(Icons.search),
                suffixIcon: Icon(Icons.tune),
              ),
            ),
            const SizedBox(height: 16),
            const _PromoBanner(),
            const SizedBox(height: 24),
            Text('Popular Rooms',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            roomsValue.when(
              loading: () => const LoadingView(),
              error: (error, _) => ErrorCard(
                message: error.toString(),
                onRetry: () => ref.invalidate(roomsProvider),
              ),
              data: (rooms) {
                if (rooms.isEmpty) {
                  return const EmptyState(
                    title: 'No rooms available',
                    message: 'Rooms will appear here after they are published.',
                  );
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
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
            ),
          ],
        ),
      ),
      bottomNavigationBar: const RoleAwareNavBar(currentPath: AppRoutes.home),
    );
  }
}

class _PromoBanner extends StatelessWidget {
  const _PromoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 164,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Chip(label: Text('Exclusive Offer')),
          const SizedBox(height: 8),
          Text(
            '20% off for first booking',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
