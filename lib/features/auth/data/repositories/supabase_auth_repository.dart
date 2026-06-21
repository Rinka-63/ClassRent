import 'package:flutter/foundation.dart';
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
      final profile = await _loadUserProfile(user.id);
      await _recordLogin(user.id);
      return right(profile);
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
    String? agencyEmail,
    String? agencyPhone,
    String? agencyAddress,
    String? agencyCity,
    String? agencyDescription,
  }) async {
    try {
      final response = await _service.requireClient.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'full_name': fullName.trim(),
          'registration_type': type.metadataValue,
          if (agencyName != null) 'agency_name': agencyName.trim(),
          if (agencyEmail != null) 'agency_email': agencyEmail.trim(),
          if (agencyPhone != null) 'agency_phone': agencyPhone.trim(),
          if (agencyAddress != null) 'agency_address': agencyAddress.trim(),
          if (agencyCity != null) 'agency_city': agencyCity.trim(),
          if (agencyDescription != null) 'agency_description': agencyDescription.trim(),
        },
      );
      final user = response.user;
      if (user == null) {
        return left(
            const AuthFailure('Registration failed. Please try again.'));
      }
      await _ensureUserProfile(
        user,
        fullName,
        type,
        agencyName,
        agencyEmail,
        agencyPhone,
        agencyAddress,
        agencyCity,
        agencyDescription,
      );
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
      await _recordLogout();
      await _service.requireClient.auth.signOut();
      return right(unit);
    } on AuthException catch (error) {
      return left(AuthFailure(error.message, code: error.statusCode));
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> resetPassword(String email) async {
    try {
      await _service.requireClient.auth.resetPasswordForEmail(email.trim());
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
        .select(
          'id,email,full_name,phone,avatar_url,role,is_verified,'
          'account_status,deleted_at',
        )
        .eq('id', userId)
        .single();
    _ensureAccountCanAccess(row);
    var agency = await _loadUserAgency(row);

    if (_shouldRepairAgencyRegistration(userId, row, agency)) {
      final metadata =
          _service.requireClient.auth.currentUser?.userMetadata ?? {};
      await _registerAgencyAdminProfile(
        fullName:
            metadata['full_name']?.toString() ?? row['full_name'] as String,
        agencyName: metadata['agency_name']?.toString(),
      );
      row = await _service.requireClient
          .from(SupabaseTables.users)
          .select(
            'id,email,full_name,phone,avatar_url,role,is_verified,'
            'account_status,deleted_at',
          )
          .eq('id', userId)
          .single();
      _ensureAccountCanAccess(row);
      agency = await _loadUserAgency(row);
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
    String? agencyEmail,
    String? agencyPhone,
    String? agencyAddress,
    String? agencyCity,
    String? agencyDescription,
  ) async {
    if (type == RegistrationType.agencyAdmin) {
      if (_service.requireClient.auth.currentSession != null) {
        await _registerAgencyAdminProfile(
          fullName: fullName,
          agencyName: agencyName,
          agencyEmail: agencyEmail,
          agencyPhone: agencyPhone,
          agencyAddress: agencyAddress,
          agencyCity: agencyCity,
          agencyDescription: agencyDescription,
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

  Future<Map<String, dynamic>?> _loadUserAgency(
      Map<String, dynamic> userRow) async {
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

    final metadata =
        _service.requireClient.auth.currentUser?.userMetadata ?? {};
    final registrationType = metadata['registration_type']?.toString();
    final role = UserRole.fromDb(row['role'] as String?);

    return registrationType == RegistrationType.agencyAdmin.metadataValue ||
        role == UserRole.admin;
  }

  Future<void> _registerAgencyAdminProfile({
    required String fullName,
    required String? agencyName,
    String? agencyEmail,
    String? agencyPhone,
    String? agencyAddress,
    String? agencyCity,
    String? agencyDescription,
  }) async {
    await _service.requireClient.rpc<void>(
      'register_agency_admin_profile',
      params: {
        'p_full_name': fullName.trim(),
        'p_agency_name': (agencyName == null || agencyName.trim().isEmpty)
            ? '${fullName.trim()} Agency'
            : agencyName.trim(),
        if (agencyEmail != null) 'p_agency_email': agencyEmail.trim(),
        if (agencyPhone != null) 'p_agency_phone': agencyPhone.trim(),
        if (agencyAddress != null) 'p_agency_address': agencyAddress.trim(),
        if (agencyCity != null) 'p_agency_city': agencyCity.trim(),
        if (agencyDescription != null) 'p_agency_description': agencyDescription.trim(),
      },
    );
  }

  Future<Map<String, dynamic>?> _maybeSingle(
      Future<List<dynamic>> query) async {
    final rows = await query;
    return rows.isEmpty ? null : rows.first as Map<String, dynamic>;
  }

  void _ensureAccountCanAccess(Map<String, dynamic> row) {
    final status = row['account_status'] as String? ?? 'active';
    if (row['deleted_at'] != null ||
        status == 'suspended' ||
        status == 'disabled' ||
        status == 'deleted') {
      throw const AuthException('Akun tidak aktif. Hubungi Super Admin.');
    }
  }

  Future<void> _recordLogin(String userId) async {
    try {
      await _service.requireClient.from('audit_logs').insert({
        'actor_id': userId,
        'action': 'login',
        'entity_type': 'user',
        'entity_id': userId,
      });
      await _service.requireClient.from(SupabaseTables.users).update({
        'last_login_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      debugPrint('Failed to record login: $e');
    }
  }

  Future<void> _recordLogout() async {
    try {
      final userId = _service.requireClient.auth.currentUser?.id;
      if (userId == null) return;
      await _service.requireClient.from('audit_logs').insert({
        'actor_id': userId,
        'action': 'logout',
        'entity_type': 'user',
        'entity_id': userId,
      });
    } catch (_) {
      // Logout should not fail because observability failed.
    }
  }
}
