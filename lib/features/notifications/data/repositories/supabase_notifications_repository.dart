import 'package:fpdart/fpdart.dart';

import '../../../../core/constants/supabase_tables.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../../domain/entities/app_notification.dart';

class SupabaseNotificationsRepository {
  const SupabaseNotificationsRepository(this._service);

  final SupabaseService _service;

  Future<Either<Failure, List<AppNotification>>> getNotifications(String userId) async {
    try {
      final rows = await _service.requireClient
          .from(SupabaseTables.notifications)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return right(rows.map(_fromJson).toList());
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  Future<Either<Failure, Unit>> markAsRead(String notificationId) async {
    try {
      await _service.requireClient.from(SupabaseTables.notifications).update({
        'is_read': true,
        'read_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', notificationId);
      return right(unit);
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  AppNotification _fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}
