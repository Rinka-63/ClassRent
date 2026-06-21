import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/supabase_tables.dart';
import '../../../../../core/supabase/supabase_client_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../rooms/domain/entities/room.dart';
import '../../../rooms/data/dto/room_dto.dart';
import '../../domain/entities/audit_log_entry.dart';



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
      .rpc('get_agency_audit_logs', params: {'p_admin_id': user.id});

  // Supabase RPC returns List<dynamic>
  final List<dynamic> resultList = rows as List<dynamic>;

  return resultList.map((dynamic item) {
    final row = item as Map<String, dynamic>;
    
    final actorName = row['actor_name'] as String?;
    final newData = row['new'] as Map<String, dynamic>?;
    final oldData = row['old'] as Map<String, dynamic>?;
    final data = newData ?? oldData;
    
    String? entityLabel = row['entity_id'] as String?;
    if (data != null) {
      entityLabel = (data['name'] ?? data['full_name'] ?? data['title'] ?? row['entity_id'])?.toString();
    }

    return AuditLogEntry(
      id: row['id'] as String,
      actorId: row['actor_id'] as String?,
      actorName: actorName,
      action: row['action'] as String,
      entityType: row['entity_type'] as String,
      entityId: row['entity_id'] as String?,
      entityLabel: entityLabel,
      oldData: oldData,
      newData: newData,
      createdAt: DateTime.parse(row['created_at'].toString()),
    );
  }).toList();
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
