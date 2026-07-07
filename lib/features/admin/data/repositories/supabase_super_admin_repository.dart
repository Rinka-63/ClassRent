import 'package:fpdart/fpdart.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/supabase_tables.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../../../rooms/data/dto/room_dto.dart';
import '../../domain/entities/agency.dart';
import '../../domain/entities/agency_withdrawal.dart';
import '../../domain/entities/audit_log_entry.dart';
import '../../domain/entities/platform_analytics.dart';
import '../../domain/entities/platform_payment.dart';
import '../../domain/entities/platform_room.dart';
import '../../domain/entities/platform_stats.dart';
import '../../domain/entities/platform_user.dart';
import '../../domain/repositories/super_admin_repository.dart';
import '../dto/agency_dto.dart';
import '../dto/agency_withdrawal_dto.dart';
import '../dto/platform_user_dto.dart';

class SupabaseSuperAdminRepository implements SuperAdminRepository {
  const SupabaseSuperAdminRepository(this._service);

  final SupabaseService _service;

  @override
  Future<Either<Failure, PlatformStats>> getPlatformStats() async {
    try {
      final client = _service.requireClient;
      final agencies = await _fetchAgenciesRaw();
      final users = await client
          .from(SupabaseTables.users)
          .select('id, account_status, deleted_at');
      final rooms = await client
          .from(SupabaseTables.rooms)
          .select('id')
          .isFilter('deleted_at', null);
      final bookings = await client.from(SupabaseTables.bookings).select('id');
      final payments = await client
          .from(SupabaseTables.bookings)
          .select('final_price, status');

      var pendingPayments = 0;
      var completedPayments = 0;
      var totalRevenue = 0.0;
      for (final row in payments) {
        final status = (row['status'] as String? ?? '').toLowerCase();
        final amount = (row['final_price'] as num?)?.toDouble() ?? 0;
        if (status.contains('pending')) pendingPayments++;
        if (['confirmed', 'completed', 'checked_in', 'checked_out']
            .contains(status)) {
          completedPayments++;
          totalRevenue += amount;
        }
      }

      return right(
        PlatformStats(
          totalAgencies: agencies.length,
          pendingAgencies: agencies
              .where((agency) => agency.approvalStatus == 'pending')
              .length,
          activeAgencies: agencies.where((agency) => agency.isActive).length,
          approvedAgencies: agencies
              .where((agency) => agency.approvalStatus == 'approved')
              .length,
          suspendedAgencies: agencies
              .where((agency) => agency.approvalStatus == 'suspended')
              .length,
          totalUsers: users.length,
          activeUsers: users.where((user) {
            final status = user['account_status'] as String?;
            return (status == null || status == 'active') &&
                user['deleted_at'] == null;
          }).length,
          pendingUsers:
              users.where((user) => user['account_status'] == 'pending').length,
          suspendedUsers: users
              .where((user) => user['account_status'] == 'suspended')
              .length,
          totalRooms: rooms.length,
          totalBookings: bookings.length,
          totalPayments: payments.length,
          pendingPayments: pendingPayments,
          completedPayments: completedPayments,
          totalRevenue: totalRevenue,
        ),
      );
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, PlatformAnalytics>> getPlatformAnalytics() async {
    try {
      final client = _service.requireClient;
      final bookings = await client
          .from(SupabaseTables.bookings)
          .select('created_at, final_price');
      final payments = await client
          .from(SupabaseTables.bookings)
          .select('created_at, final_price, status');
      final users =
          await client.from(SupabaseTables.users).select('created_at');
      final agencies =
          await client.from(SupabaseTables.agencies).select('created_at');

      return right(
        PlatformAnalytics(
          bookingsPerMonth: _groupByMonth(
            bookings,
            valueKey: 'final_price',
            countOnly: true,
          ),
          paymentsPerMonth: _groupByMonth(
            payments.where((row) {
              final status = (row['status'] as String? ?? '').toLowerCase();
              return ['confirmed', 'completed', 'checked_in', 'checked_out']
                  .contains(status);
            }).toList(),
            countOnly: true,
          ),
          userGrowth: _groupByMonth(users, cumulative: true),
          agencyGrowth: _groupByMonth(agencies, cumulative: true),
          revenuePerMonth: _groupByMonth(
            payments.where((row) {
              final status = (row['status'] as String? ?? '').toLowerCase();
              return ['confirmed', 'completed', 'checked_in', 'checked_out']
                  .contains(status);
            }).toList(),
            valueKey: 'final_price',
          ),
        ),
      );
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Agency>>> getAgencies() async {
    try {
      return right(await _fetchAgenciesWithStats());
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, Agency>> getAgencyDetail(String agencyId) async {
    try {
      final agencies = await _fetchAgenciesWithStats();
      final agency = agencies.where((item) => item.id == agencyId).firstOrNull;
      if (agency == null) {
        return left(const UnknownFailure('Agency not found'));
      }
      return right(agency);
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PlatformUser>>> getPlatformUsers() async {
    try {
      final rows = await _service.requireClient
          .from(SupabaseTables.users)
          .select(
            'id,email,full_name,phone,role,is_verified,account_status,'
            'last_login_at,created_at,deleted_at,'
            'agencies:agencies!agencies_admin_id_fkey(id,name)',
          )
          .order('created_at', ascending: false);
      return right(rows.map(PlatformUserDto.fromJson).toList());
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, PlatformUser>> getPlatformUserDetail(
      String userId) async {
    try {
      final rows = await _service.requireClient
          .from(SupabaseTables.users)
          .select(
            'id,email,full_name,phone,role,is_verified,account_status,'
            'last_login_at,created_at,deleted_at,'
            'agencies:agencies!agencies_admin_id_fkey(id,name)',
          )
          .eq('id', userId)
          .limit(1);
      if (rows.isEmpty) {
        return left(const UnknownFailure('User not found'));
      }
      return right(PlatformUserDto.fromJson(rows.first));
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PlatformRoom>>> getPlatformRooms() async {
    try {
      return right(await _fetchPlatformRooms());
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, PlatformRoom>> getPlatformRoomDetail(
      String roomId) async {
    try {
      final rooms = await _fetchPlatformRooms();
      final room = rooms.where((item) => item.room.id == roomId).firstOrNull;
      if (room == null) {
        return left(const UnknownFailure('Room not found'));
      }
      return right(room);
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, List<AuditLogEntry>>> getAuditLogs() async {
    try {
      final client = _service.requireClient;
      final rows = (await client
          .from('audit_logs')
          .select(
            'id,actor_id,action,entity_type,entity_id,old,new,created_at,'
            'users:users!audit_logs_actor_id_fkey(full_name,role)',
          )
          .order('created_at', ascending: false)
          .limit(500)) as List<dynamic>;
      final typedRows = rows.cast<Map<String, dynamic>>();
      final labels = await _resolveAuditLabels(typedRows);

      return right(
        typedRows.map((row) {
          final actor = row['users'];
          Map<String, dynamic>? actorMap;
          if (actor is Map<String, dynamic>) {
            actorMap = actor;
          } else if (actor is List && actor.isNotEmpty) {
            actorMap = actor.first as Map<String, dynamic>;
          }

          return AuditLogEntry(
            id: row['id'] as String,
            actorId: row['actor_id'] as String?,
            actorName: actorMap?['full_name'] as String?,
            actorRole: actorMap?['role'] as String?,
            action: row['action'] as String,
            entityType: row['entity_type'] as String,
            entityId: row['entity_id'] as String?,
            entityLabel: labels[row['id'] as String] ?? _entityLabel(row),
            oldData: row['old'] as Map<String, dynamic>?,
            newData: row['new'] as Map<String, dynamic>?,
            createdAt: DateTime.parse(row['created_at'].toString()),
          );
        }).toList(),
      );
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PlatformUser>>> getRecentUsers(
      {int limit = 5}) async {
    try {
      final rows = await _service.requireClient
          .from(SupabaseTables.users)
          .select(
            'id,email,full_name,phone,role,is_verified,account_status,'
            'last_login_at,created_at,deleted_at,'
            'agencies:agencies!agencies_admin_id_fkey(id,name)',
          )
          .order('created_at', ascending: false)
          .limit(limit);
      return right(rows.map(PlatformUserDto.fromJson).toList());
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Agency>>> getRecentAgencies(
      {int limit = 5}) async {
    try {
      final agencies = await _fetchAgenciesWithStats();
      return right(agencies.take(limit).toList());
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PlatformPayment>>> getRecentPayments(
      {int limit = 5}) async {
    try {
      final rows = await _service.requireClient
          .from(SupabaseTables.bookings)
          .select(
            'id,user_id,final_price,status,created_at,'
            'users!bookings_user_id_fkey(full_name)',
          )
          .order('created_at', ascending: false)
          .limit(limit);

      return right(
        rows.map((row) {
          final user = row['users'];
          String? userName;
          if (user is Map<String, dynamic>) {
            userName = user['full_name'] as String?;
          } else if (user is List && user.isNotEmpty) {
            userName =
                (user.first as Map<String, dynamic>)['full_name'] as String?;
          }
          final status = (row['status'] as String? ?? '').toLowerCase();
          final paymentStatus = [
            'confirmed',
            'completed',
            'checked_in',
            'checked_out'
          ].contains(status)
              ? 'settlement'
              : status.contains('pending')
                  ? 'pending'
                  : 'cancel';

          return PlatformPayment(
            id: row['id'] as String,
            bookingId: row['id'] as String,
            userId: row['user_id'] as String,
            amount: (row['final_price'] as num?)?.toDouble() ?? 0,
            status: paymentStatus,
            paymentMethod: 'system',
            userName: userName,
            createdAt: DateTime.parse(row['created_at'].toString()),
          );
        }).toList(),
      );
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getRecentBookings({
    int limit = 5,
  }) async {
    try {
      final rows = await _service.requireClient
          .from(SupabaseTables.bookings)
          .select(
            'id,user_id,room_id,booking_date,status,final_price,created_at,'
            'rooms(name), users(full_name)',
          )
          .order('created_at', ascending: false)
          .limit(limit);
      return right(rows.cast<Map<String, dynamic>>());
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, List<AgencyWithdrawal>>> getAgencyWithdrawals() async {
    try {
      final rows = await _service.requireClient
          .from(SupabaseTables.agencyWithdrawals)
          .select()
          .order('created_at', ascending: false);
      final agencyIds = rows
          .map((row) => row['agency_id'] as String?)
          .whereType<String>()
          .toSet()
          .toList();
      final agencyNames = await _fetchAgencyNamesByIds(agencyIds);
      return right(
        rows.map((row) {
          final agencyId = row['agency_id'] as String?;
          return AgencyWithdrawalDto.fromJson({
            ...row,
            'agencies': {'name': agencyNames[agencyId] ?? 'Agency'},
          });
        }).toList(),
      );
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> approveAgency(String agencyId) =>
      _updateAgencyWithAudit(
        agencyId,
        {
          'approval_status': 'approved',
          'is_active': true,
          'approved_at': DateTime.now().toIso8601String(),
          'rejected_at': null,
        },
        'agency_approved',
      );

  @override
  Future<Either<Failure, Unit>> rejectAgency(String agencyId) =>
      _runAgencyStatusRpc(agencyId, 'banned');

  @override
  Future<Either<Failure, Unit>> suspendAgency(String agencyId) =>
      _runAgencyStatusRpc(agencyId, 'suspended');

  @override
  Future<Either<Failure, Unit>> reactivateAgency(String agencyId) =>
      _updateAgencyWithAudit(
        agencyId,
        {
          'approval_status': 'approved',
          'is_active': true,
          'approved_at': DateTime.now().toIso8601String(),
          'rejected_at': null,
          'deleted_at': null,
        },
        'agency_reactivated',
      );

  @override
  Future<Either<Failure, Unit>> deleteAgency(String agencyId) =>
      _updateAgencyWithAudit(
        agencyId,
        {
          'is_active': false,
          'deleted_at': DateTime.now().toIso8601String(),
        },
        'agency_deleted',
      );

  @override
  Future<Either<Failure, Unit>> setAgencyActive(
          String agencyId, bool isActive) =>
      isActive ? reactivateAgency(agencyId) : suspendAgency(agencyId);

  @override
  Future<Either<Failure, Unit>> updateAgency(
    String agencyId,
    Map<String, dynamic> values,
  ) =>
      _updateAgencyWithAudit(agencyId, values, 'agency_updated');

  @override
  Future<Either<Failure, Unit>> updateUser(
    String userId,
    Map<String, dynamic> values,
  ) async {
    try {
      final old = await _fetchUserRow(userId);
      if (_isSelf(userId) && _changesRestrictedSelfFields(values)) {
        return left(const UnknownFailure(
            'Super Admin cannot change own account status or role.'));
      }
      await _service.requireClient
          .from(SupabaseTables.users)
          .update(values)
          .eq('id', userId);
      final updated = await _fetchUserRow(userId);
      await _insertAudit(
        action: 'user_updated',
        entityType: 'user',
        entityId: userId,
        oldData: old,
        newData: updated,
      );
      return right(unit);
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> activateUser(String userId) =>
      _runUserStatusRpc(userId, 'active');

  @override
  Future<Either<Failure, Unit>> suspendUser(String userId) =>
      _runUserStatusRpc(userId, 'suspended');

  @override
  Future<Either<Failure, Unit>> disableUser(String userId) =>
      _runUserStatusRpc(userId, 'disabled');

  @override
  Future<Either<Failure, Unit>> deleteUser(String userId) =>
      updateUser(userId, {
        'account_status': 'deleted',
        'deleted_at': DateTime.now().toIso8601String(),
      });

  @override
  Future<Either<Failure, Unit>> changeUserRole(String userId, String role) =>
      updateUser(userId, {'role': role});

  @override
  Future<Either<Failure, Unit>> resetUserPassword(String email) async {
    try {
      await _service.requireClient.auth.resetPasswordForEmail(email.trim());
      await _insertAudit(
        action: 'password_reset_requested',
        entityType: 'user',
        entityId: null,
        newData: {'email': email.trim()},
      );
      return right(unit);
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> transferAgencyOwnership({
    required String agencyId,
    required String newOwnerEmail,
  }) async {
    try {
      final client = _service.requireClient;
      final agency = await client
          .from(SupabaseTables.agencies)
          .select()
          .eq('id', agencyId)
          .single();
      final users = await client
          .from(SupabaseTables.users)
          .select('id,email,full_name,role')
          .eq('email', newOwnerEmail.trim())
          .limit(1);
      if (users.isEmpty) {
        return left(const UnknownFailure('New owner email not found.'));
      }
      final newOwner = users.first;
      final oldOwnerId = agency['admin_id'] as String;
      final newOwnerId = newOwner['id'] as String;
      if (_isSelf(oldOwnerId)) {
        return left(const UnknownFailure(
            'Super Admin cannot transfer own agency ownership.'));
      }

      await client
          .from(SupabaseTables.agencies)
          .update({'admin_id': newOwnerId}).eq('id', agencyId);
      await client.from(SupabaseTables.users).update(
          {'role': 'admin', 'account_status': 'active'}).eq('id', newOwnerId);
      await client
          .from(SupabaseTables.users)
          .update({'role': 'user'}).eq('id', oldOwnerId);
      final updated = await client
          .from(SupabaseTables.agencies)
          .select()
          .eq('id', agencyId)
          .single();
      await _insertAudit(
        action: 'agency_ownership_transferred',
        entityType: 'agency',
        entityId: agencyId,
        oldData: agency,
        newData: updated,
      );
      return right(unit);
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateRoom(
    String roomId,
    Map<String, dynamic> values,
  ) async {
    try {
      final old = await _fetchRoomRow(roomId);
      await _service.requireClient
          .from(SupabaseTables.rooms)
          .update(values)
          .eq('id', roomId);
      final updated = await _fetchRoomRow(roomId);
      await _insertAudit(
        action: 'room_updated',
        entityType: 'room',
        entityId: roomId,
        oldData: old,
        newData: updated,
      );
      return right(unit);
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> suspendRoom(String roomId) => updateRoom(
        roomId,
        {'is_active': false},
      );

  @override
  Future<Either<Failure, Unit>> reactivateRoom(String roomId) => updateRoom(
        roomId,
        {
          'is_active': true,
          'deleted_at': null,
        },
      );

  @override
  Future<Either<Failure, Unit>> deleteRoom(String roomId) async {
    try {
      final old = await _fetchRoomRow(roomId);
      await _service.requireClient.from(SupabaseTables.rooms).update({
        'deleted_at': DateTime.now().toIso8601String(),
        'is_active': false,
      }).eq('id', roomId);
      final updated = await _fetchRoomRow(roomId);
      await _insertAudit(
        action: 'room_deleted',
        entityType: 'room',
        entityId: roomId,
        oldData: old,
        newData: updated,
      );
      return right(unit);
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateAgencyWithdrawalStatus({
    required String withdrawalId,
    required String status,
    String? rejectionReason,
  }) async {
    try {
      final old = await _service.requireClient
          .from(SupabaseTables.agencyWithdrawals)
          .select()
          .eq('id', withdrawalId)
          .single();
      await _service.requireClient
          .from(SupabaseTables.agencyWithdrawals)
          .update({
        'status': status,
        'reviewed_by': _service.requireClient.auth.currentUser?.id,
        'reviewed_at': DateTime.now().toIso8601String(),
        'rejection_reason': rejectionReason,
      }).eq('id', withdrawalId);
      final updated = await _service.requireClient
          .from(SupabaseTables.agencyWithdrawals)
          .select()
          .eq('id', withdrawalId)
          .single();
      await _insertAudit(
        action: 'agency_withdrawal_$status',
        entityType: 'agency_withdrawal',
        entityId: withdrawalId,
        oldData: old,
        newData: updated,
      );
      return right(unit);
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  Future<Either<Failure, Unit>> _runUserStatusRpc(
    String userId,
    String status,
  ) async {
    try {
      await _service.requireClient.rpc(
        'super_admin_set_user_account_status',
        params: {
          'p_user_id': userId,
          'p_status': status,
        },
      );
      return right(unit);
    } catch (error) {
      if (_looksLikeMissingRpc(error)) {
        return _updateUserWithAudit(
          userId,
          status == 'active'
              ? {
                  'account_status': 'active',
                  'deleted_at': null,
                  'deletion_reason': null,
                }
              : status == 'disabled'
                  ? {
                      'account_status': 'disabled',
                      'deleted_at': DateTime.now().toIso8601String(),
                      'deletion_reason': 'Diblokir oleh super admin',
                    }
                  : {
                      'account_status': 'suspended',
                      'deleted_at': null,
                      'deletion_reason': null,
                    },
          status == 'active'
              ? 'user_reactivated'
              : status == 'disabled'
                  ? 'user_banned'
                  : 'user_suspended',
        );
      }
      return left(UnknownFailure(error.toString()));
    }
  }

  Future<Either<Failure, Unit>> _runAgencyStatusRpc(
    String agencyId,
    String status,
  ) async {
    try {
      await _service.requireClient.rpc(
        'super_admin_set_agency_status',
        params: {
          'p_agency_id': agencyId,
          'p_status': status,
        },
      );
      return right(unit);
    } catch (error) {
      if (_looksLikeMissingRpc(error)) {
        return _updateAgencyWithAudit(
          agencyId,
          {
            'approval_status': status == 'banned' ? 'rejected' : 'suspended',
            'is_active': false,
            'rejected_at':
                status == 'banned' ? DateTime.now().toIso8601String() : null,
            'rejection_reason':
                status == 'banned' ? 'Diblokir oleh super admin' : null,
          },
          status == 'banned' ? 'agency_banned' : 'agency_suspended',
        );
      }
      return left(UnknownFailure(error.toString()));
    }
  }

  Future<List<Agency>> _fetchAgenciesRaw() async {
    final rows = await _service.requireClient
        .from(SupabaseTables.agencies)
        .select('*, users:users!agencies_admin_id_fkey(full_name,email,phone)')
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false);
    return rows.map(AgencyDto.fromJson).toList();
  }

  Future<Map<String, String>> _fetchAgencyNamesByIds(List<String> ids) async {
    if (ids.isEmpty) return const {};
    final rows = await _service.requireClient
        .from(SupabaseTables.agencies)
        .select('id,name')
        .inFilter('id', ids);
    return {
      for (final row in rows)
        if (row['id'] != null && row['name'] != null)
          row['id'] as String: row['name'] as String,
    };
  }

  Future<List<Agency>> _fetchAgenciesWithStats() async {
    final client = _service.requireClient;
    final agencies = await _fetchAgenciesRaw();
    final rooms = await client
        .from(SupabaseTables.rooms)
        .select('id, admin_id')
        .isFilter('deleted_at', null);
    final bookings = await client
        .from(SupabaseTables.bookings)
        .select('id, room_id, final_price');

    final roomIdsByAdmin = <String, List<String>>{};
    for (final room in rooms) {
      final adminId = room['admin_id'] as String;
      roomIdsByAdmin.putIfAbsent(adminId, () => []).add(room['id'] as String);
    }

    final bookingCountByRoom = <String, int>{};
    final revenueByRoom = <String, double>{};
    for (final booking in bookings) {
      final roomId = booking['room_id'] as String;
      bookingCountByRoom[roomId] = (bookingCountByRoom[roomId] ?? 0) + 1;
      revenueByRoom[roomId] = (revenueByRoom[roomId] ?? 0) +
          ((booking['final_price'] as num?)?.toDouble() ?? 0);
    }

    return agencies.map((agency) {
      final roomIds = roomIdsByAdmin[agency.adminId] ?? const [];
      final bookingCount = roomIds.fold<int>(
          0, (sum, roomId) => sum + (bookingCountByRoom[roomId] ?? 0));
      final revenue = roomIds.fold<double>(
          0, (sum, roomId) => sum + (revenueByRoom[roomId] ?? 0));
      return AgencyDto(
        id: agency.id,
        adminId: agency.adminId,
        name: agency.name,
        slug: agency.slug,
        isActive: agency.isActive,
        approvalStatus: agency.approvalStatus,
        email: agency.email,
        phone: agency.phone,
        address: agency.address,
        city: agency.city,
        description: agency.description,
        ownerName: agency.ownerName,
        ownerEmail: agency.ownerEmail,
        ownerPhone: agency.ownerPhone,
        createdAt: agency.createdAt,
        roomCount: roomIds.length,
        bookingCount: bookingCount,
        revenue: revenue,
      );
    }).toList();
  }

  Future<List<PlatformRoom>> _fetchPlatformRooms() async {
    final client = _service.requireClient;
    final agencies = await _fetchAgenciesRaw();
    final agencyByAdmin = {
      for (final agency in agencies) agency.adminId: agency
    };
    final roomRows = await client
        .from(SupabaseTables.rooms)
        .select()
        .isFilter('deleted_at', null)
        .order('updated_at', ascending: false);
    final facilityRows = await client
        .from(SupabaseTables.roomFacilities)
        .select('room_id, facility_tag');

    final facilitiesByRoom = <String, List<String>>{};
    for (final row in facilityRows) {
      final roomId = row['room_id'] as String;
      facilitiesByRoom
          .putIfAbsent(roomId, () => [])
          .add(row['facility_tag'] as String);
    }

    return roomRows.map((row) {
      final room = RoomDto.fromJson(row);
      final agency = agencyByAdmin[room.adminId];
      return PlatformRoom(
        room: room,
        agencyName: agency?.name ?? 'Unknown Agency',
        agencyId: agency?.id,
        facilities: facilitiesByRoom[room.id] ?? const [],
      );
    }).toList();
  }

  Future<Either<Failure, Unit>> _updateAgencyWithAudit(
    String agencyId,
    Map<String, Object?> values,
    String action,
  ) async {
    try {
      final old = await _service.requireClient
          .from(SupabaseTables.agencies)
          .select()
          .eq('id', agencyId)
          .single();
      await _service.requireClient
          .from(SupabaseTables.agencies)
          .update(values)
          .eq('id', agencyId);
      final updated = await _service.requireClient
          .from(SupabaseTables.agencies)
          .select()
          .eq('id', agencyId)
          .single();
      await _insertAudit(
        action: action,
        entityType: 'agency',
        entityId: agencyId,
        oldData: old,
        newData: updated,
      );
      return right(unit);
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  Future<Either<Failure, Unit>> _updateUserWithAudit(
    String userId,
    Map<String, Object?> values,
    String action,
  ) async {
    try {
      final old = await _fetchUserRow(userId);
      await _service.requireClient
          .from(SupabaseTables.users)
          .update(values)
          .eq('id', userId);
      final updated = await _fetchUserRow(userId);
      await _insertAudit(
        action: action,
        entityType: 'user',
        entityId: userId,
        oldData: old,
        newData: updated,
      );
      return right(unit);
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  Future<Map<String, dynamic>> _fetchUserRow(String userId) async {
    return _service.requireClient
        .from(SupabaseTables.users)
        .select()
        .eq('id', userId)
        .single();
  }

  Future<Map<String, dynamic>> _fetchRoomRow(String roomId) async {
    return _service.requireClient
        .from(SupabaseTables.rooms)
        .select()
        .eq('id', roomId)
        .single();
  }

  Future<void> _insertAudit({
    required String action,
    required String entityType,
    required String? entityId,
    Map<String, dynamic>? oldData,
    Map<String, dynamic>? newData,
  }) async {
    try {
      await _service.requireClient.from('audit_logs').insert({
        'actor_id': _service.requireClient.auth.currentUser?.id,
        'action': action,
        'entity_type': entityType,
        'entity_id': entityId,
        'old': oldData,
        'new': newData,
      });
    } catch (_) {
      // Audit logging must never block the administrative action.
    }
  }

  bool _looksLikeMissingRpc(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('could not find the function') ||
        message.contains('schema cache') ||
        message.contains('pgrst203') ||
        message.contains('unsupported user status');
  }

  bool _isSelf(String userId) =>
      _service.requireClient.auth.currentUser?.id == userId;

  bool _changesRestrictedSelfFields(Map<String, dynamic> values) {
    return values.containsKey('role') ||
        values.containsKey('account_status') ||
        values.containsKey('deleted_at');
  }

  List<MonthlyDataPoint> _groupByMonth(
    List<dynamic> rows, {
    String valueKey = 'created_at',
    bool countOnly = false,
    bool cumulative = false,
  }) {
    final monthFormat = DateFormat('MMM yy');
    final buckets = <DateTime, ({int count, double revenue})>{};

    for (final row in rows) {
      final createdAt = DateTime.parse(row['created_at'].toString());
      final key = DateTime(createdAt.year, createdAt.month);
      final current = buckets[key] ?? (count: 0, revenue: 0);
      final amount = countOnly ? 0.0 : (row[valueKey] as num?)?.toDouble() ?? 0;
      buckets[key] = (
        count: current.count + 1,
        revenue: current.revenue + (countOnly ? 0 : amount),
      );
    }

    final sortedKeys = buckets.keys.toList()..sort();
    final lastSix = sortedKeys.length > 6
        ? sortedKeys.sublist(sortedKeys.length - 6)
        : sortedKeys;

    var runningTotal = 0;
    return [
      for (final key in lastSix)
        () {
          final bucket = buckets[key]!;
          runningTotal += bucket.count;
          return MonthlyDataPoint(
            label: monthFormat.format(key),
            count: cumulative ? runningTotal : bucket.count,
            revenue: bucket.revenue,
          );
        }(),
    ];
  }

  String? _entityLabel(Map<String, dynamic> row) {
    final newData = row['new'] as Map<String, dynamic>?;
    final oldData = row['old'] as Map<String, dynamic>?;
    final data = newData ?? oldData;
    if (data == null) return row['entity_id'] as String?;
    return (data['name'] ??
            data['full_name'] ??
            data['title'] ??
            row['entity_id'])
        ?.toString();
  }

  Future<Map<String, String>> _resolveAuditLabels(
    List<Map<String, dynamic>> rows,
  ) async {
    final userIds = <String>{};
    final roomIds = <String>{};
    final agencyIds = <String>{};
    final bookingIds = <String>{};
    final paymentBookingIds = <String>{};

    for (final row in rows) {
      final entityId = row['entity_id'] as String?;
      final entityType = (row['entity_type'] as String? ?? '').toLowerCase();
      final oldData = row['old'] as Map<String, dynamic>?;
      final newData = row['new'] as Map<String, dynamic>?;
      final data = newData ?? oldData ?? const <String, dynamic>{};

      switch (entityType) {
        case 'user':
          if (entityId != null) userIds.add(entityId);
          break;
        case 'room':
          if (entityId != null) roomIds.add(entityId);
          break;
        case 'agency':
          if (entityId != null) agencyIds.add(entityId);
          break;
        case 'booking':
          if (entityId != null) bookingIds.add(entityId);
          break;
        case 'payment':
          final bookingId = data['booking_id']?.toString();
          if (bookingId != null && bookingId.isNotEmpty) {
            paymentBookingIds.add(bookingId);
          }
          break;
      }
    }

    final labels = <String, String>{};
    labels.addAll(await _fetchSimpleLabels(
      table: SupabaseTables.users,
      ids: userIds,
      select: 'id,full_name,email',
      labelBuilder: (row) =>
          (row['full_name'] ?? row['email'] ?? row['id']).toString(),
    ));
    labels.addAll(await _fetchSimpleLabels(
      table: SupabaseTables.rooms,
      ids: roomIds,
      select: 'id,name',
      labelBuilder: (row) => (row['name'] ?? row['id']).toString(),
    ));
    labels.addAll(await _fetchSimpleLabels(
      table: SupabaseTables.agencies,
      ids: agencyIds,
      select: 'id,name',
      labelBuilder: (row) => (row['name'] ?? row['id']).toString(),
    ));
    labels.addAll(await _fetchBookingLabels({
      ...bookingIds,
      ...paymentBookingIds,
    }));

    for (final row in rows) {
      final rowId = row['id']?.toString();
      final entityType = (row['entity_type'] as String? ?? '').toLowerCase();
      final entityId = row['entity_id']?.toString();
      final oldData = row['old'] as Map<String, dynamic>?;
      final newData = row['new'] as Map<String, dynamic>?;
      final data = newData ?? oldData;

      final directLabel = _entityLabel(row);
      if (rowId == null || rowId.isEmpty) continue;
      if (!_looksLikeUuid(directLabel)) {
        labels[rowId] = directLabel ?? '';
        continue;
      }

      switch (entityType) {
        case 'user':
          if (entityId != null && labels[entityId] != null) {
            labels[rowId] = labels[entityId]!;
          }
          break;
        case 'room':
          if (entityId != null && labels[entityId] != null) {
            labels[rowId] = labels[entityId]!;
          }
          break;
        case 'agency':
          if (entityId != null && labels[entityId] != null) {
            labels[rowId] = labels[entityId]!;
          }
          break;
        case 'booking':
          if (entityId != null && labels[entityId] != null) {
            labels[rowId] = labels[entityId]!;
          } else {
            labels[rowId] = _fallbackAuditLabel('Booking', entityId);
          }
          break;
        case 'payment':
          final bookingId = data?['booking_id']?.toString();
          final bookingLabel = bookingId != null ? labels[bookingId] : null;
          labels[rowId] = bookingLabel == null
              ? _fallbackAuditLabel('Payment', entityId)
              : 'Payment • $bookingLabel';
          break;
        case 'agency_withdrawal':
          labels[rowId] = _fallbackAuditLabel('Withdrawal', entityId);
          break;
      }
    }

    return labels;
  }

  Future<Map<String, String>> _fetchSimpleLabels({
    required String table,
    required Set<String> ids,
    required String select,
    required String Function(Map<String, dynamic>) labelBuilder,
  }) async {
    if (ids.isEmpty) return const {};
    final rows = await _service.requireClient
        .from(table)
        .select(select)
        .inFilter('id', ids.toList());
    return {
      for (final row in rows)
        if (row['id'] != null)
          row['id'] as String: labelBuilder(row.cast<String, dynamic>()),
    };
  }

  Future<Map<String, String>> _fetchBookingLabels(Set<String> ids) async {
    if (ids.isEmpty) return const {};
    final rows = await _service.requireClient
        .from(SupabaseTables.bookings)
        .select('id,booking_date,rooms(name),users(full_name)')
        .inFilter('id', ids.toList());
    return {
      for (final row in rows)
        if (row['id'] != null)
          row['id'] as String: _bookingLabel(row.cast<String, dynamic>()),
    };
  }

  String _bookingLabel(Map<String, dynamic> row) {
    final room = row['rooms'];
    final user = row['users'];
    String? roomName;
    String? userName;
    if (room is Map<String, dynamic>) {
      roomName = room['name'] as String?;
    } else if (room is List && room.isNotEmpty) {
      roomName = (room.first as Map<String, dynamic>)['name'] as String?;
    }
    if (user is Map<String, dynamic>) {
      userName = user['full_name'] as String?;
    } else if (user is List && user.isNotEmpty) {
      userName = (user.first as Map<String, dynamic>)['full_name'] as String?;
    }
    final dateText = row['booking_date']?.toString();
    final segments = <String>[
      if (roomName != null && roomName.isNotEmpty) roomName,
      if (userName != null && userName.isNotEmpty) userName,
      if (dateText != null && dateText.isNotEmpty) dateText,
    ];
    if (segments.isNotEmpty) {
      return segments.join(' • ');
    }
    return _fallbackAuditLabel('Booking', row['id']?.toString());
  }

  String _fallbackAuditLabel(String prefix, String? id) {
    if (id == null || id.isEmpty) return prefix;
    final shortId = id.length > 8 ? id.substring(0, 8) : id;
    return '$prefix #$shortId';
  }

  bool _looksLikeUuid(String? value) {
    if (value == null || value.isEmpty) return true;
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(value);
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) return iterator.current;
    return null;
  }
}
