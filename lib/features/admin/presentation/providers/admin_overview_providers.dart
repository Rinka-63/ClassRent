import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/supabase_tables.dart';
import '../../../../core/supabase/supabase_client_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../rooms/domain/entities/room.dart';
import '../../../rooms/data/dto/room_dto.dart';

class AuditLogEntry {
  const AuditLogEntry({
    required this.id,
    required this.action,
    required this.entityType,
    required this.createdAt,
    this.actorId,
    this.entityId,
  });

  final String id;
  final String action;
  final String entityType;
  final String? actorId;
  final String? entityId;
  final DateTime createdAt;
}

final adminRoomsProvider = FutureProvider<List<Room>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final user = ref.watch(currentUserProvider);
  if (client == null || user == null) return const [];

  final rows = await client
      .from(SupabaseTables.rooms)
      .select()
      .eq('admin_id', user.id)
      .isFilter('deleted_at', null)
      .order('updated_at', ascending: false);

  return rows.map(RoomDto.fromJson).toList();
});

final adminRoomReportsProvider = FutureProvider<AdminRoomReports>((ref) async {
  final rooms = await ref.watch(adminRoomsProvider.future);
  final totalRooms = rooms.length;
  final activeRooms = rooms.where((room) => room.isActive).length;
  final requiresApproval = rooms.where((room) => room.requiresApproval).length;
  final totalCapacity = rooms.fold<int>(0, (sum, room) => sum + room.capacity);
  final averageRating = rooms.isEmpty
      ? 0.0
      : rooms.fold<double>(
            0.0,
            (sum, room) => sum + room.avgRating,
          ) /
          rooms.length;
  final hourlyFloor = rooms.isEmpty
      ? 0.0
      : rooms
          .map((room) => room.hourlyRate)
          .reduce((a, b) => a < b ? a : b)
          .toDouble();
  final hourlyCeiling = rooms.isEmpty
      ? 0.0
      : rooms
          .map((room) => room.hourlyRate)
          .reduce((a, b) => a > b ? a : b)
          .toDouble();

  return AdminRoomReports(
    totalRooms: totalRooms,
    activeRooms: activeRooms,
    requiresApproval: requiresApproval,
    totalCapacity: totalCapacity,
    averageRating: averageRating,
    hourlyFloor: hourlyFloor,
    hourlyCeiling: hourlyCeiling,
  );
});

final adminHistoryProvider = FutureProvider<List<AuditLogEntry>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final user = ref.watch(currentUserProvider);
  if (client == null || user == null) return const [];

  final rows = await client
      .from('audit_logs')
      .select('id,actor_id,action,entity_type,entity_id,created_at')
      .eq('actor_id', user.id)
      .order('created_at', ascending: false)
      .limit(20);

  return rows
      .map(
        (row) => AuditLogEntry(
          id: row['id'] as String,
          actorId: row['actor_id'] as String?,
          action: row['action'] as String,
          entityType: row['entity_type'] as String,
          entityId: row['entity_id'] as String?,
          createdAt: DateTime.parse(row['created_at'].toString()),
        ),
      )
      .toList();
});

class AdminRoomReports {
  const AdminRoomReports({
    required this.totalRooms,
    required this.activeRooms,
    required this.requiresApproval,
    required this.totalCapacity,
    required this.averageRating,
    required this.hourlyFloor,
    required this.hourlyCeiling,
  });

  final int totalRooms;
  final int activeRooms;
  final int requiresApproval;
  final int totalCapacity;
  final double averageRating;
  final double hourlyFloor;
  final double hourlyCeiling;
}
