import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/widgets/error_card.dart';
import '../../../../core/widgets/loading_view.dart';
import '../providers/rooms_providers.dart';

class RoomDetailScreen extends ConsumerWidget {
  const RoomDetailScreen({required this.roomId, super.key});

  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomValue = ref.watch(roomDetailProvider(roomId));

    return Scaffold(
      appBar: AppBar(title: const Text('Room Detail')),
      body: roomValue.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorCard(message: error.toString()),
        data: (room) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              height: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: const Icon(Icons.meeting_room_outlined, size: 72),
            ),
            const SizedBox(height: 16),
            Text(room.name, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('${room.city} • ${room.capacity} seats'),
            const SizedBox(height: 16),
            Text(room.description ?? 'Room description will come from Supabase.'),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.push(AppRoutes.bookingCreate),
              icon: const Icon(Icons.calendar_today_outlined),
              label: const Text('Start Booking'),
            ),
          ],
        ),
      ),
    );
  }
}
