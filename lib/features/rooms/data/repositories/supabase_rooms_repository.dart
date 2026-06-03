import 'package:fpdart/fpdart.dart';

import '../../../../core/constants/supabase_tables.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../../domain/entities/room.dart';
import '../../domain/repositories/rooms_repository.dart';
import '../dto/room_dto.dart';

class SupabaseRoomsRepository implements RoomsRepository {
  const SupabaseRoomsRepository(this._service);

  final SupabaseService _service;

  @override
  Future<Either<Failure, List<Room>>> getRooms() async {
    try {
      final rows = await _service.requireClient
          .from(SupabaseTables.rooms)
          .select()
          .eq('is_active', true)
          .isFilter('deleted_at', null)
          .order('avg_rating', ascending: false);
      return right(rows.map(RoomDto.fromJson).toList());
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, Room>> getRoomById(String id) async {
    try {
      final row = await _service.requireClient
          .from(SupabaseTables.rooms)
          .select()
          .eq('id', id)
          .single();
      return right(RoomDto.fromJson(row));
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Room>>> getRoomsByAdminId(String adminId) async {
    try {
      final rows = await _service.requireClient
          .from(SupabaseTables.rooms)
          .select()
          .eq('admin_id', adminId)
          .isFilter('deleted_at', null)
          .order('updated_at', ascending: false);
      return right(rows.map(RoomDto.fromJson).toList());
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, Room>> createRoom(Map<String, dynamic> payload) async {
    try {
      final row = await _service.requireClient
          .from(SupabaseTables.rooms)
          .insert(payload)
          .select()
          .single();
      return right(RoomDto.fromJson(row));
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, Room>> updateRoom(String id, Map<String, dynamic> payload) async {
    try {
      final row = await _service.requireClient
          .from(SupabaseTables.rooms)
          .update(payload)
          .eq('id', id)
          .select()
          .single();
      return right(RoomDto.fromJson(row));
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteRoom(String id) async {
    try {
      await _service.requireClient
          .from(SupabaseTables.rooms)
        .update({'deleted_at': DateTime.now().toIso8601String(), 'is_active': false})
        .eq('id', id);
      return right(unit);
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getRoomSchedules(String roomId) async {
    try {
      final rows = await _service.requireClient
          .from('room_schedules')
          .select()
          .eq('room_id', roomId)
          .order('day_of_week', ascending: true);
      return right(rows.cast<Map<String, dynamic>>());
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> saveRoomSchedules(
    String roomId,
    List<Map<String, dynamic>> schedules,
  ) async {
    try {
      await _service.requireClient
          .from('room_schedules')
          .delete()
          .eq('room_id', roomId);
      if (schedules.isNotEmpty) {
        final payload = schedules
            .map((item) => {
                  ...item,
                  'room_id': roomId,
                },)
            .toList();
        await _service.requireClient.from('room_schedules').insert(payload);
      }
      return right(unit);
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getRoomFacilities(String roomId) async {
    try {
      final rows = await _service.requireClient
          .from(SupabaseTables.roomFacilities)
          .select('facility_tag')
          .eq('room_id', roomId)
          .order('facility_tag', ascending: true);
      return right(rows.map((row) => row['facility_tag'].toString()).toList());
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> saveRoomFacilities(
    String roomId,
    List<String> facilities,
  ) async {
    try {
      await _service.requireClient
          .from(SupabaseTables.roomFacilities)
          .delete()
          .eq('room_id', roomId);
      if (facilities.isNotEmpty) {
        await _service.requireClient.from(SupabaseTables.roomFacilities).insert(
          facilities
              .map(
                (facility) => {
                  'room_id': roomId,
                  'facility_tag': facility.trim(),
                },
              )
              .toList(),
        );
      }
      return right(unit);
    } catch (error) {
      return left(UnknownFailure(error.toString()));
    }
  }
}
