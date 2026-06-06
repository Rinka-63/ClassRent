import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/agency.dart';
import '../entities/audit_log_entry.dart';
import '../entities/platform_analytics.dart';
import '../entities/platform_stats.dart';
import '../entities/platform_user.dart';

abstract interface class AgencyRepository {
  Future<Either<Failure, List<Agency>>> getAgencies();
  Future<Either<Failure, Agency>> getAgencyDetail(String agencyId);
  Future<Either<Failure, PlatformStats>> getPlatformStats();
  Future<Either<Failure, List<PlatformUser>>> getPlatformUsers();
  Future<Either<Failure, PlatformUser>> getUserDetail(String userId);
  Future<Either<Failure, List<AuditLogEntry>>> getAuditLogs();
  Future<Either<Failure, PlatformAnalytics>> getPlatformAnalytics();
  Future<Either<Failure, Unit>> approveAgency(String agencyId);
  Future<Either<Failure, Unit>> rejectAgency(String agencyId);
  Future<Either<Failure, Unit>> setAgencyActive(String agencyId, bool isActive);
  Future<Either<Failure, Unit>> setUserActive(String userId, bool isActive);
  Future<Either<Failure, Unit>> logManualAudit({
    required String actorId,
    required String action,
    required String entityType,
    String? entityId,
    Map<String, dynamic>? oldData,
    Map<String, dynamic>? newData,
  });
}
