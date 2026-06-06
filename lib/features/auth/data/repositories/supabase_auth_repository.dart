import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/supabase_tables.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../../../../shared/data/dto/app_user_dto.dart';
import '../../../../shared/domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  const SupabaseAuthRepository(this._service);

  final SupabaseService _service;

  @override
  Future<Either<Failure, AppUser?>> restoreSession() async {
    try {
      final session = _service.requireClient.auth.currentSession;
      if (session == null) return right(null);
      return right(await _loadUserProfile(session.user.id));
    } on AuthException catch (error) {
      return left(AuthFailure(error.message, code: error.statusCode));
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, AppUser>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _service.requireClient.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      final user = response.user;
      if (user == null) {
        return left(const AuthFailure('Login failed. Please try again.'));
      }
      return right(await _loadUserProfile(user.id));
    } on AuthException catch (error) {
      return left(AuthFailure(error.message, code: error.statusCode));
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, AppUser>> register({
    required String email,
    required String password,
    required String fullName,
    required RegistrationType type,
    String? agencyName,
  }) async {
    try {
      final response = await _service.requireClient.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'full_name': fullName.trim(),
          'registration_type': type.metadataValue,
          if (agencyName != null) 'agency_name': agencyName.trim(),
        },
      );
      final user = response.user;
      if (user == null) {
        return left(const AuthFailure('Registration failed. Please try again.'));
      }
      await _ensureUserProfile(user, fullName, type, agencyName);
      return right(await _loadUserProfile(user.id));
    } on AuthException catch (error) {
      return left(AuthFailure(error.message, code: error.statusCode));
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    try {
      await _service.requireClient.auth.signOut();
      return right(unit);
    } on AuthException catch (error) {
      return left(AuthFailure(error.message, code: error.statusCode));
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  Future<AppUser> _loadUserProfile(String userId) async {
    var row = await _service.requireClient
        .from(SupabaseTables.users)
        .select('id,email,full_name,phone,avatar_url,role,is_verified,deleted_at')
        .eq('id', userId)
        .single();
    var agency = await _loadUserAgency(row);

    if (_shouldRepairAgencyRegistration(userId, row, agency)) {
      final metadata = _service.requireClient.auth.currentUser?.userMetadata ?? {};
      await _registerAgencyAdminProfile(
        fullName: metadata['full_name']?.toString() ?? row['full_name'] as String,
        agencyName: metadata['agency_name']?.toString(),
      );
      row = await _service.requireClient
          .from(SupabaseTables.users)
          .select('id,email,full_name,phone,avatar_url,role,is_verified,deleted_at')
          .eq('id', userId)
          .single();
      agency = await _loadUserAgency(row);
    }

    if (row['deleted_at'] != null) {
      throw const AuthFailure('Account is suspended.');
    }

    return AppUserDto.fromJson({
      ...row,
      'agency_id': agency?['id'],
      'agency_status': agency?['approval_status'],
      'agency_is_active': agency?['is_active'],
    });
  }

  Future<void> _ensureUserProfile(
    User user,
    String fullName,
    RegistrationType type,
    String? agencyName,
  ) async {
    if (type == RegistrationType.agencyAdmin) {
      if (_service.requireClient.auth.currentSession != null) {
        await _registerAgencyAdminProfile(
          fullName: fullName,
          agencyName: agencyName,
        );
      }
      return;
    }

    try {
      await _service.requireClient.from(SupabaseTables.users).upsert({
        'id': user.id,
        'email': user.email ?? '',
        'full_name': fullName.trim().isEmpty
            ? user.email ?? 'ClassRent User'
            : fullName.trim(),
        'role': type == RegistrationType.agencyAdmin
            ? UserRole.admin.dbValue
            : UserRole.user.dbValue,
      });
    } catch (_) {
      // The database trigger is the source of truth. This fallback can be
      // blocked by RLS, so registration should still continue to profile load.
    }
  }

  Future<Map<String, dynamic>?> _loadUserAgency(Map<String, dynamic> userRow) async {
    final role = UserRole.fromDb(userRow['role'] as String?);
    final userId = userRow['id'] as String;

    if (role == UserRole.admin) {
      return _maybeSingle(
        _service.requireClient
            .from(SupabaseTables.agencies)
            .select('id,approval_status,is_active')
            .eq('admin_id', userId)
            .limit(1),
      );
    }

    return null;
  }

  bool _shouldRepairAgencyRegistration(
    String userId,
    Map<String, dynamic> row,
    Map<String, dynamic>? agency,
  ) {
    if (agency != null) return false;
    if (_service.requireClient.auth.currentUser?.id != userId) return false;

    final metadata = _service.requireClient.auth.currentUser?.userMetadata ?? {};
    final registrationType = metadata['registration_type']?.toString();
    final role = UserRole.fromDb(row['role'] as String?);

    return registrationType == RegistrationType.agencyAdmin.metadataValue ||
        role == UserRole.admin;
  }

  Future<void> _registerAgencyAdminProfile({
    required String fullName,
    required String? agencyName,
  }) async {
    await _service.requireClient.rpc<void>(
      'register_agency_admin_profile',
      params: {
        'p_full_name': fullName.trim(),
        'p_agency_name': (agencyName == null || agencyName.trim().isEmpty)
            ? '${fullName.trim()} Agency'
            : agencyName.trim(),
      },
    );
  }

  Future<Map<String, dynamic>?> _maybeSingle(Future<List<dynamic>> query) async {
    final rows = await query;
    return rows.isEmpty ? null : rows.first as Map<String, dynamic>;
  }

}
