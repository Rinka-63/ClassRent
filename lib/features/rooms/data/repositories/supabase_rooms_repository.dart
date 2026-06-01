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
}
