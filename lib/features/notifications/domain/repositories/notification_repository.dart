import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/notification.dart';

abstract class NotificationRepository {
  Future<Either<Failure, List<AppNotification>>> getNotificationsForUser(String userId);
  Future<Either<Failure, AppNotification>> markAsRead(String notificationId);
  Future<Either<Failure, Unit>> markAllAsRead(String userId);
  Future<Either<Failure, int>> getUnreadCount(String userId);
}
