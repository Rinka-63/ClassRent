import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_card.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../shared/presentation/widgets/role_aware_nav_bar.dart';
import '../../../rooms/domain/entities/room.dart';
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
          IconButton(
            onPressed: () => context.push(AppRoutes.admin),
            icon: const Icon(Icons.admin_panel_settings_outlined),
          ),
        ],
      ),
      body: ListView(
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
          Text('Popular Rooms', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          roomsValue.when(
            loading: () => const LoadingView(),
            error: (error, _) => ErrorCard(message: error.toString()),
            data: (rooms) {
              final displayRooms = rooms.isEmpty ? _sampleRooms : rooms;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: displayRooms.length,
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 380,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.84,
                ),
                itemBuilder: (_, index) => RoomCard(room: displayRooms[index]),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: const RoleAwareNavBar(currentPath: AppRoutes.home),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.bookingCreate),
        child: const Icon(Icons.add),
      ),
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

const _sampleRooms = [
  Room(
    id: 'sample-room-1',
    adminId: 'sample-admin',
    name: 'Tech Innovators Suite',
    capacity: 24,
    hourlyRate: 75000,
    city: 'Jakarta',
    avgRating: 4.9,
  ),
  Room(
    id: 'sample-room-2',
    adminId: 'sample-admin',
    name: 'Creative Design Studio',
    capacity: 16,
    hourlyRate: 55000,
    city: 'Bandung',
    avgRating: 4.7,
  ),
];
