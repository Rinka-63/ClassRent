import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/agency.dart';
import '../entities/agency_withdrawal.dart';
import '../entities/platform_stats.dart';
import '../entities/platform_user.dart';

abstract interface class AgencyRepository {
  Future<Either<Failure, List<Agency>>> getAgencies();
  Future<Either<Failure, PlatformStats>> getPlatformStats();
  Future<Either<Failure, List<PlatformUser>>> getPlatformUsers();
  Future<Either<Failure, Unit>> approveAgency(String agencyId);
  Future<Either<Failure, Unit>> rejectAgency(String agencyId);
  Future<Either<Failure, Unit>> setAgencyActive(String agencyId, bool isActive);
  Future<Either<Failure, List<AgencyWithdrawal>>> getMyWithdrawals(
    String adminId,
  );
  Future<Either<Failure, Unit>> createWithdrawal({
    required String adminId,
    required double amount,
    required String bankName,
    required String accountName,
    required String accountNumber,
  });
}
