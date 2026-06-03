import 'package:fpdart/fpdart.dart';

import '../../../../core/constants/supabase_tables.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../../domain/entities/agency.dart';
import '../../domain/entities/platform_stats.dart';
import '../../domain/entities/platform_user.dart';
import '../../domain/repositories/agency_repository.dart';
import '../dto/agency_dto.dart';
import '../dto/platform_user_dto.dart';

class SupabaseAgencyRepository implements AgencyRepository {
  const SupabaseAgencyRepository(this._service);

  final SupabaseService _service;

  @override
  Future<Either<Failure, List<Agency>>> getAgencies() async {
    try {
      final rows = await _service.requireClient
          .from(SupabaseTables.agencies)
          .select()
          .order('created_at', ascending: false);
      return right(rows.map(AgencyDto.fromJson).toList());
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, PlatformStats>> getPlatformStats() async {
    try {
      final agenciesResult = await getAgencies();
      final agencies = agenciesResult.match((failure) => throw failure, (data) => data);
      final users = await _service.requireClient
          .from(SupabaseTables.users)
          .select('id');
      final rooms = await _service.requireClient
          .from(SupabaseTables.rooms)
          .select('id');
      final bookings = await _service.requireClient
          .from(SupabaseTables.bookings)
          .select('id');

      return right(
        PlatformStats(
          totalAgencies: agencies.length,
          pendingAgencies: agencies
              .where((agency) => agency.approvalStatus == 'pending')
              .length,
          activeAgencies: agencies.where((agency) => agency.isActive).length,
          totalUsers: users.length,
          totalRooms: rooms.length,
          totalBookings: bookings.length,
        ),
      );
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PlatformUser>>> getPlatformUsers() async {
    try {
      final rows = await _service.requireClient
          .from(SupabaseTables.users)
          .select('id,email,full_name,role,is_verified,created_at')
          .order('created_at', ascending: false);
      return right(rows.map(PlatformUserDto.fromJson).toList());
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> approveAgency(String agencyId) async {
    return _updateAgency(agencyId, {
      'approval_status': 'approved',
      'is_active': true,
      'approved_at': DateTime.now().toIso8601String(),
      'rejected_at': null,
    });
  }

  @override
  Future<Either<Failure, Unit>> rejectAgency(String agencyId) async {
    return _updateAgency(agencyId, {
      'approval_status': 'rejected',
      'is_active': false,
      'rejected_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<Either<Failure, Unit>> setAgencyActive(
    String agencyId,
    bool isActive,
  ) async {
    return _updateAgency(agencyId, {'is_active': isActive});
  }

  Future<Either<Failure, Unit>> _updateAgency(
    String agencyId,
    Map<String, Object?> values,
  ) async {
    try {
      await _service.requireClient
          .from(SupabaseTables.agencies)
          .update(values)
          .eq('id', agencyId);
      return right(unit);
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }
}
