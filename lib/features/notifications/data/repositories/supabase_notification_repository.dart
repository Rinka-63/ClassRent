import 'package:fpdart/fpdart.dart';

import '../../../../core/constants/supabase_tables.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../dto/notification_dto.dart';
import '../../domain/entities/notification.dart';
import '../../domain/repositories/notification_repository.dart';

class SupabaseNotificationRepository implements NotificationRepository {
  const SupabaseNotificationRepository(this._service);

  final SupabaseService _service;

  @override
  Future<Either<Failure, List<AppNotification>>> getNotificationsForUser(
    String userId,
  ) async {
    try {
      final rows = await _service.requireClient
          .from(SupabaseTables.notifications)
          .select()
          .eq('receiver_id', userId)
          .order('created_at', ascending: false);
      return right(
        rows.map((row) => NotificationDto.fromJson(row).toEntity()).toList(),
      );
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, AppNotification>> markAsRead(
    String notificationId,
  ) async {
    try {
      final row = await _service.requireClient
          .from(SupabaseTables.notifications)
          .update({'is_read': true})
          .eq('id', notificationId)
          .select()
          .single();
      return right(NotificationDto.fromJson(row).toEntity());
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> markAllAsRead(String userId) async {
    try {
      await _service.requireClient
          .from(SupabaseTables.notifications)
          .update({'is_read': true})
          .eq('receiver_id', userId);
      return right(unit);
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> getUnreadCount(String userId) async {
    try {
      final result = await _service.requireClient
          .from(SupabaseTables.notifications)
          .select()
          .eq('receiver_id', userId)
          .eq('is_read', false);
      return right(result.length);
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }
}
