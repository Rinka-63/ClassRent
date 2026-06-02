import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/agency.dart';
import '../entities/platform_stats.dart';
import '../entities/platform_user.dart';

abstract interface class AgencyRepository {
  Future<Either<Failure, List<Agency>>> getAgencies();
  Future<Either<Failure, PlatformStats>> getPlatformStats();
  Future<Either<Failure, List<PlatformUser>>> getPlatformUsers();
  Future<Either<Failure, Unit>> approveAgency(String agencyId);
  Future<Either<Failure, Unit>> rejectAgency(String agencyId);
  Future<Either<Failure, Unit>> setAgencyActive(String agencyId, bool isActive);
  Future<Either<Failure, Unit>> createStaff({
    required String email,
    required String password,
    required String fullName,
    required String agencyId,
  });
}
