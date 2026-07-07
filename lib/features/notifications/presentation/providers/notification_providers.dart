import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/supabase_client_provider.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/supabase_notification_repository.dart';
import '../../domain/entities/notification.dart';
import '../../domain/repositories/notification_repository.dart';
import 'dart:async';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return SupabaseNotificationRepository(
    SupabaseService(ref.watch(supabaseClientProvider)),
  );
});

final notificationsProvider =
    StreamProvider.autoDispose<List<AppNotification>>((ref) async* {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    yield const [];
    return;
  }

  final client = ref.watch(supabaseClientProvider);
  if (client == null) {
    yield const [];
    return;
  }

  final controller = StreamController<List<AppNotification>>();

  // Initial fetch
  final repo = ref.read(notificationRepositoryProvider);
  final result = await repo.getNotificationsForUser(user.id);
  final initialData = result.fold((l) => throw Exception(l.message), (r) => r);
  controller.add(initialData);
  yield* controller.stream;

  // Subscribe to realtime changes using RealtimeChannel
  final channel =
      client.channel('public:notifications:receiver_id=eq.${user.id}');
  channel
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'notifications',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'receiver_id',
          value: user.id,
        ),
        callback: (payload) async {
          // Refetch and yield new data on any change
          final newResult = await repo.getNotificationsForUser(user.id);
          controller
              .add(newResult.fold((l) => throw Exception(l.message), (r) => r));
        },
      )
      .subscribe();

  ref.onDispose(() {
    channel.unsubscribe();
    controller.close();
  });
});

final unreadCountProvider = Provider<AsyncValue<int>>((ref) {
  final notifications = ref.watch(notificationsProvider);
  return notifications.whenData(
    (items) => items.where((item) => !item.isRead).length,
  );
});
