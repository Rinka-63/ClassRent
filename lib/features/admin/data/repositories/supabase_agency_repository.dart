import 'package:fpdart/fpdart.dart';

import '../../../../core/constants/supabase_tables.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../../domain/entities/agency.dart';
import '../../domain/entities/audit_log_entry.dart';
import '../../domain/entities/platform_analytics.dart';
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
      final agencies = await _loadAgencySummaries();
      return right(agencies);
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, Agency>> getAgencyDetail(String agencyId) async {
    try {
      final agency = await _loadAgencySummaries(agencyId: agencyId);
      if (agency.isEmpty) {
        return left(const UnknownFailure('Agency not found'));
      }
      return right(agency.first);
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, PlatformStats>> getPlatformStats() async {
    try {
      final now = DateTime.now().toUtc();
      final users = await _service.requireClient
          .from(SupabaseTables.users)
          .select('id,role,created_at,deleted_at,updated_at');
      final agencies = await _service.requireClient
          .from(SupabaseTables.agencies)
          .select('id,approval_status,is_active,created_at,approved_at,updated_at');
      final rooms = await _service.requireClient
          .from(SupabaseTables.rooms)
          .select('id,is_active,deleted_at,created_at');
      final bookings = await _service.requireClient
          .from(SupabaseTables.bookings)
          .select('id,status,created_at');
      final payments = await _service.requireClient
          .from(SupabaseTables.payments)
          .select('id,amount,status,created_at');

      final totalUsers = users.where((row) => row['role'] == 'user').length;
      final activeUsersToday = users.where((row) {
        if (row['role'] != 'user') return false;
        if (row['deleted_at'] != null) return false;
        final updated = DateTime.tryParse(row['updated_at']?.toString() ?? row['created_at']?.toString() ?? '');
        return updated != null && _sameUtcDay(updated, now);
      }).length;

      final totalAgencies = agencies.length;
      final activeAgencies = agencies.where((row) => row['approval_status'] == 'approved' && row['is_active'] == true).length;
      final pendingAgencies = agencies.where((row) => row['approval_status'] == 'pending').length;
      final suspendedAgencies = agencies.where((row) => row['approval_status'] == 'suspended' || row['is_active'] == false).length;
      final activeAgenciesToday = agencies.where((row) {
        final approvedAt = DateTime.tryParse(row['approved_at']?.toString() ?? row['updated_at']?.toString() ?? '');
        return row['is_active'] == true && approvedAt != null && _sameUtcDay(approvedAt, now);
      }).length;

      final totalRooms = rooms.length;
      final activeRooms = rooms.where((row) => row['is_active'] == true && row['deleted_at'] == null).length;

      final totalBookings = bookings.length;
      final pendingBookings = bookings.where((row) => (row['status'] as String? ?? '').toLowerCase().contains('pending')).length;
      final approvedBookings = bookings.where((row) => (row['status'] as String? ?? '').toLowerCase().contains('confirm') || (row['status'] as String? ?? '').toLowerCase().contains('approved')).length;
      final completedBookings = bookings.where((row) => (row['status'] as String? ?? '').toLowerCase() == 'completed').length;
      final cancelledBookings = bookings.where((row) => (row['status'] as String? ?? '').toLowerCase() == 'cancelled').length;

      final successfulPayments = payments.where((row) {
        final status = (row['status'] as String? ?? '').toLowerCase();
        return status == 'settlement' || status == 'capture';
      }).toList();
      final totalSuccessfulTransactions = successfulPayments.length;
      final revenueThisMonth = successfulPayments
          .where((row) {
            final createdAt = DateTime.tryParse(row['created_at']?.toString() ?? '');
            return createdAt != null &&
                createdAt.year == now.year &&
                createdAt.month == now.month;
          })
          .fold<double>(0, (sum, row) => sum + ((row['amount'] as num?)?.toDouble() ?? 0));

      return right(
        PlatformStats(
          totalAgencies: totalAgencies,
          activeAgencies: activeAgencies,
          pendingAgencies: pendingAgencies,
          suspendedAgencies: suspendedAgencies,
          totalUsers: totalUsers,
          activeUsersToday: activeUsersToday,
          totalRooms: totalRooms,
          activeRooms: activeRooms,
          totalBookings: totalBookings,
          pendingBookings: pendingBookings,
          approvedBookings: approvedBookings,
          completedBookings: completedBookings,
          cancelledBookings: cancelledBookings,
          totalSuccessfulTransactions: totalSuccessfulTransactions,
          revenueThisMonth: revenueThisMonth,
          activeAgenciesToday: activeAgenciesToday,
        ),
      );
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PlatformUser>>> getPlatformUsers() async {
    try {
      final client = _service.requireClient;
      final rows = await client
          .from(SupabaseTables.users)
          .select('id,email,full_name,role,is_verified,deleted_at,created_at')
          .order('created_at', ascending: false);
      final agencies = await client
          .from(SupabaseTables.agencies)
          .select('admin_id,name');
      final agencyByAdminId = <String, String>{
        for (final row in agencies) row['admin_id'] as String: row['name'] as String,
      };
      return right(
        rows.map((row) {
          final json = Map<String, dynamic>.from(row);
          json['agency_name'] = agencyByAdminId[json['id'] as String];
          return PlatformUserDto.fromJson(json);
        }).toList(),
      );
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, PlatformUser>> getUserDetail(String userId) async {
    try {
      final row = await _service.requireClient
          .from(SupabaseTables.users)
          .select('id,email,full_name,role,is_verified,deleted_at,created_at')
          .eq('id', userId)
          .single();
      final agencies = await _service.requireClient
          .from(SupabaseTables.agencies)
          .select('admin_id,name')
          .eq('admin_id', userId);
      final json = Map<String, dynamic>.from(row);
      if (agencies.isNotEmpty) {
        json['agency_name'] = agencies.first['name'] as String?;
      }
      return right(PlatformUserDto.fromJson(json));
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, List<AuditLogEntry>>> getAuditLogs() async {
    try {
      final rows = await _service.requireClient
          .from(SupabaseTables.auditLogs)
          .select('id,actor_id,actor_name,actor_role,agency_id,agency_name,action,entity_type,entity_id,entity_name,description,old,new,created_at')
          .order('created_at', ascending: false)
          .limit(300);
      return right(rows.map(_auditFromJson).toList());
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, PlatformAnalytics>> getPlatformAnalytics() async {
    try {
      final clients = _service.requireClient;
      final users = await clients.from(SupabaseTables.users).select('id,role,created_at');
      final agencies = await clients
          .from(SupabaseTables.agencies)
          .select('id,admin_id,name,approval_status,is_active,created_at');
      final rooms = await clients.from(SupabaseTables.rooms).select('id,name,admin_id,created_at');
      final bookings = await clients.from(SupabaseTables.bookings).select('id,room_id,created_at');

      final bookingCountsByRoom = <String, int>{};
      for (final row in bookings) {
        final roomId = row['room_id'] as String;
        bookingCountsByRoom[roomId] = (bookingCountsByRoom[roomId] ?? 0) + 1;
      }

      final bookingsByAgency = <String, int>{};
      final roomToAdmin = {for (final row in rooms) row['id'] as String: row['admin_id'] as String};
      for (final row in bookings) {
        final adminId = roomToAdmin[row['room_id'] as String];
        if (adminId != null) {
          bookingsByAgency[adminId] = (bookingsByAgency[adminId] ?? 0) + 1;
        }
      }

      final monthlyUsers = _monthlySeries(users, 'created_at', filterRole: 'user');
      final agencyRows = agencies.cast<Map<String, dynamic>>().toList();
      final monthlyAgencies = _monthlySeries(agencyRows, 'created_at');
      final monthlyBookings = _monthlySeries(bookings, 'created_at');

      final agencyLookup = {
        for (final row in agencyRows) row['admin_id'] as String: row['name'] as String,
      };
      final topAgencies = bookingsByAgency.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topRooms = bookingCountsByRoom.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return right(
        PlatformAnalytics(
          totalUsers: users.where((row) => row['role'] == 'user').length,
          totalAgencies: agencies.length,
          totalRooms: rooms.length,
          totalBookings: bookings.length,
          userRegistrationsByMonth: monthlyUsers,
          agencyRegistrationsByMonth: monthlyAgencies,
          bookingsByMonth: monthlyBookings,
          topAgencies: topAgencies
              .take(5)
              .map(
                (entry) => LeaderboardRow(
                  id: entry.key,
                  label: agencyLookup[entry.key] ?? entry.key,
                  value: entry.value,
                ),
              )
              .toList(),
          topRooms: topRooms
              .take(5)
              .map(
                (entry) => LeaderboardRow(
                  id: entry.key,
                  label: _roomNameById(rooms, entry.key),
                  value: entry.value,
                ),
              )
              .toList(),
        ),
      );
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
      'rejection_reason': null,
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
    return _updateAgency(agencyId, {
      'is_active': isActive,
      'approval_status': isActive ? 'approved' : 'suspended',
    });
  }

  @override
  Future<Either<Failure, Unit>> setUserActive(String userId, bool isActive) async {
    try {
      await _service.requireClient
          .from(SupabaseTables.users)
          .update({
            'deleted_at': isActive ? null : DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
      return right(unit);
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> logManualAudit({
    required String actorId,
    required String action,
    required String entityType,
    String? entityId,
    Map<String, dynamic>? oldData,
    Map<String, dynamic>? newData,
  }) async {
    try {
      await _service.requireClient.from(SupabaseTables.auditLogs).insert({
        'actor_id': actorId,
        'action': action,
        'entity_type': entityType,
        'entity_id': entityId,
        'old': oldData,
        'new': newData,
      });
      return right(unit);
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  Future<List<Agency>> _loadAgencySummaries({String? agencyId}) async {
    final agenciesQuery = _service.requireClient
        .from(SupabaseTables.agencies)
        .select('id,admin_id,name,slug,is_active,approval_status,city,created_at,approved_at,rejected_at,rejection_reason');
    final agenciesRows = agencyId == null
        ? await agenciesQuery.order('created_at', ascending: false)
        : await agenciesQuery.eq('id', agencyId).limit(1);

    final rooms = await _service.requireClient
        .from(SupabaseTables.rooms)
        .select('id,admin_id');
    final bookings = await _service.requireClient
        .from(SupabaseTables.bookings)
        .select('id,room_id');
    final roomToAdmin = {for (final row in rooms) row['id'] as String: row['admin_id'] as String};
    final roomCounts = <String, int>{};
    for (final row in rooms) {
      final adminId = row['admin_id'] as String;
      roomCounts[adminId] = (roomCounts[adminId] ?? 0) + 1;
    }
    final bookingCounts = <String, int>{};
    for (final row in bookings) {
      final roomId = row['room_id'] as String;
      final adminId = roomToAdmin[roomId];
      if (adminId != null) {
        bookingCounts[adminId] = (bookingCounts[adminId] ?? 0) + 1;
      }
    }

    return agenciesRows.map((row) {
      final json = Map<String, dynamic>.from(row);
      json['room_count'] = roomCounts[json['admin_id'] as String] ?? 0;
      json['booking_count'] = bookingCounts[json['admin_id'] as String] ?? 0;
      return AgencyDto.fromJson(json);
    }).toList();
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

  AuditLogEntry _auditFromJson(Map<String, dynamic> json) {
    return AuditLogEntry(
      id: json['id'] as String,
      actorId: json['actor_id'] as String?,
      actorName: json['actor_name'] as String?,
      actorRole: json['actor_role'] as String?,
      agencyId: json['agency_id'] as String?,
      agencyName: json['agency_name'] as String?,
      action: json['action'] as String,
      entityType: json['entity_type'] as String,
      entityId: json['entity_id'] as String?,
      entityName: json['entity_name'] as String?,
      createdAt: DateTime.parse(json['created_at'].toString()),
      summary: '${json['action']} ${json['entity_type']}',
      description: json['description'] as String? ?? '${json['action']} ${json['entity_type']}',
      oldData: (json['old'] as Map?)?.cast<String, dynamic>(),
      newData: (json['new'] as Map?)?.cast<String, dynamic>(),
    );
  }

  List<MonthlyMetric> _monthlySeries(
    List<dynamic> rows,
    String field, {
    String? filterRole,
  }) {
    final counts = <String, int>{};
    for (final raw in rows) {
      final row = raw as Map<String, dynamic>;
      if (filterRole != null && row['role'] != filterRole) continue;
      final value = DateTime.parse(row[field].toString());
      final key = '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}';
      counts[key] = (counts[key] ?? 0) + 1;
    }

    final entries = counts.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return entries
        .map(
          (entry) => MonthlyMetric(
            label: entry.key,
            value: entry.value,
          ),
        )
        .toList();
  }

  String _roomNameById(List<dynamic> rooms, String roomId) {
    for (final raw in rooms) {
      final row = raw as Map<String, dynamic>;
      if (row['id'] == roomId) return row['name'].toString();
    }
    return roomId;
  }

  bool _sameUtcDay(DateTime a, DateTime b) {
    return a.toUtc().year == b.year && a.toUtc().month == b.month && a.toUtc().day == b.day;
  }
}
