import 'package:fpdart/fpdart.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/supabase_tables.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../../../rooms/data/dto/room_dto.dart';
import '../../domain/entities/agency.dart';
import '../../domain/entities/audit_log_entry.dart';
import '../../domain/entities/platform_analytics.dart';
import '../../domain/entities/platform_payment.dart';
import '../../domain/entities/platform_room.dart';
import '../../domain/entities/platform_stats.dart';
import '../../domain/entities/platform_user.dart';
import '../../domain/repositories/super_admin_repository.dart';
import '../dto/agency_dto.dart';
import '../dto/platform_user_dto.dart';

class SupabaseSuperAdminRepository implements SuperAdminRepository {
  const SupabaseSuperAdminRepository(this._service);

  final SupabaseService _service;

  static const _completedPaymentStatuses = {'settlement', 'capture'};
  static const _pendingPaymentStatuses = {'pending'};

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
          .from(SupabaseTables.payments)
          .select('gross_amount, transaction_status');

      var pendingPayments = 0;
      var completedPayments = 0;
      var totalRevenue = 0.0;
      for (final row in payments) {
        final status =
            (row['transaction_status'] as String? ?? 'pending').toLowerCase();
        final amount = (row['gross_amount'] as num?)?.toDouble() ?? 0;
        if (_pendingPaymentStatuses.contains(status)) pendingPayments++;
        if (_completedPaymentStatuses.contains(status)) {
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
          .from(SupabaseTables.payments)
          .select('created_at, gross_amount, transaction_status');
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
              final status =
                  (row['transaction_status'] as String? ?? '').toLowerCase();
              return _completedPaymentStatuses.contains(status);
            }).toList(),
            countOnly: true,
          ),
          userGrowth: _groupByMonth(users, cumulative: true),
          agencyGrowth: _groupByMonth(agencies, cumulative: true),
          revenuePerMonth: _groupByMonth(
            payments.where((row) {
              final status =
                  (row['transaction_status'] as String? ?? '').toLowerCase();
              return _completedPaymentStatuses.contains(status);
            }).toList(),
            valueKey: 'gross_amount',
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
      final rows = await client
          .from('audit_logs')
          .select(
            'id,actor_id,action,entity_type,entity_id,old,new,created_at,'
            'users:users!audit_logs_actor_id_fkey(full_name,role)',
          )
          .order('created_at', ascending: false)
          .limit(500);

      return right(
        rows.map((row) {
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
            entityLabel: _entityLabel(row),
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
          .from(SupabaseTables.payments)
          .select(
            'id,booking_id,user_id,gross_amount,transaction_status,payment_method,created_at,'
            'users:users!payments_user_id_fkey(full_name)',
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
          return PlatformPayment(
            id: row['id'] as String,
            bookingId: row['booking_id'] as String,
            userId: row['user_id'] as String,
            amount: (row['gross_amount'] as num?)?.toDouble() ?? 0,
            status: row['transaction_status'] as String? ?? 'pending',
            paymentMethod: row['payment_method'] as String?,
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
      _updateAgencyWithAudit(
        agencyId,
        {
          'approval_status': 'rejected',
          'is_active': false,
          'rejected_at': DateTime.now().toIso8601String(),
        },
        'agency_rejected',
      );

  @override
  Future<Either<Failure, Unit>> suspendAgency(String agencyId) =>
      _updateAgencyWithAudit(
        agencyId,
        {
          'approval_status': 'suspended',
          'is_active': false,
        },
        'agency_suspended',
      );

  @override
  Future<Either<Failure, Unit>> reactivateAgency(String agencyId) =>
      _updateAgencyWithAudit(
        agencyId,
        {
          'approval_status': 'approved',
          'is_active': true,
          'approved_at': DateTime.now().toIso8601String(),
          'rejected_at': null,
        },
        'agency_reactivated',
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
      updateUser(userId, {
        'account_status': 'active',
        'deleted_at': null,
        'deletion_reason': null,
      });

  @override
  Future<Either<Failure, Unit>> suspendUser(String userId) =>
      updateUser(userId, {'account_status': 'suspended'});

  @override
  Future<Either<Failure, Unit>> disableUser(String userId) =>
      updateUser(userId, {'account_status': 'disabled'});

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
      await _service.requireClient
          .from(SupabaseTables.rooms)
          .update(values)
          .eq('id', roomId);
      return right(unit);
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteRoom(String roomId) async {
    try {
      await _service.requireClient.from(SupabaseTables.rooms).update(
          {'deleted_at': DateTime.now().toIso8601String()}).eq('id', roomId);
      return right(unit);
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  Future<List<Agency>> _fetchAgenciesRaw() async {
    final rows = await _service.requireClient
        .from(SupabaseTables.agencies)
        .select('*, users:users!agencies_admin_id_fkey(full_name,email,phone)')
        .order('created_at', ascending: false);
    return rows.map(AgencyDto.fromJson).toList();
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

  Future<Map<String, dynamic>> _fetchUserRow(String userId) async {
    return _service.requireClient
        .from(SupabaseTables.users)
        .select()
        .eq('id', userId)
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
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) return iterator.current;
    return null;
  }
}
