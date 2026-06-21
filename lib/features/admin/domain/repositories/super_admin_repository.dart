import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/agency.dart';
import '../entities/audit_log_entry.dart';
import '../entities/platform_analytics.dart';
import '../entities/platform_payment.dart';
import '../entities/platform_room.dart';
import '../entities/platform_stats.dart';
import '../entities/platform_user.dart';

abstract interface class SuperAdminRepository {
  Future<Either<Failure, PlatformStats>> getPlatformStats();
  Future<Either<Failure, PlatformAnalytics>> getPlatformAnalytics();
  Future<Either<Failure, List<Agency>>> getAgencies();
  Future<Either<Failure, Agency>> getAgencyDetail(String agencyId);
  Future<Either<Failure, List<PlatformUser>>> getPlatformUsers();
  Future<Either<Failure, PlatformUser>> getPlatformUserDetail(String userId);
  Future<Either<Failure, List<PlatformRoom>>> getPlatformRooms();
  Future<Either<Failure, PlatformRoom>> getPlatformRoomDetail(String roomId);
  Future<Either<Failure, List<AuditLogEntry>>> getAuditLogs();
  Future<Either<Failure, List<PlatformUser>>> getRecentUsers({int limit = 5});
  Future<Either<Failure, List<Agency>>> getRecentAgencies({int limit = 5});
  Future<Either<Failure, List<PlatformPayment>>> getRecentPayments(
      {int limit = 5});
  Future<Either<Failure, List<Map<String, dynamic>>>> getRecentBookings(
      {int limit = 5});

  Future<Either<Failure, Unit>> approveAgency(String agencyId);
  Future<Either<Failure, Unit>> rejectAgency(String agencyId);
  Future<Either<Failure, Unit>> suspendAgency(String agencyId);
  Future<Either<Failure, Unit>> reactivateAgency(String agencyId);
  Future<Either<Failure, Unit>> setAgencyActive(String agencyId, bool isActive);
  Future<Either<Failure, Unit>> updateAgency(
      String agencyId, Map<String, dynamic> values);
  Future<Either<Failure, Unit>> updateUser(
      String userId, Map<String, dynamic> values);
  Future<Either<Failure, Unit>> activateUser(String userId);
  Future<Either<Failure, Unit>> suspendUser(String userId);
  Future<Either<Failure, Unit>> disableUser(String userId);
  Future<Either<Failure, Unit>> deleteUser(String userId);
  Future<Either<Failure, Unit>> changeUserRole(String userId, String role);
  Future<Either<Failure, Unit>> resetUserPassword(String email);
  Future<Either<Failure, Unit>> transferAgencyOwnership({
    required String agencyId,
    required String newOwnerEmail,
  });
  Future<Either<Failure, Unit>> updateRoom(
      String roomId, Map<String, dynamic> values);
  Future<Either<Failure, Unit>> deleteRoom(String roomId);
}
