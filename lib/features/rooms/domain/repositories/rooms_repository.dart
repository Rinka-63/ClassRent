import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/room.dart';

abstract interface class RoomsRepository {
  Future<Either<Failure, List<Room>>> getRooms();
  Future<Either<Failure, Room>> getRoomById(String id);
  Future<Either<Failure, List<Room>>> getRoomsByAdminId(String adminId);
  Future<Either<Failure, Room>> createRoom(Map<String, dynamic> payload);
  Future<Either<Failure, Room>> updateRoom(String id, Map<String, dynamic> payload);
  Future<Either<Failure, Unit>> deleteRoom(String id);
  Future<Either<Failure, List<Map<String, dynamic>>>> getRoomSchedules(String roomId);
  Future<Either<Failure, Unit>> saveRoomSchedules(
    String roomId,
    List<Map<String, dynamic>> schedules,
  );
  Future<Either<Failure, List<String>>> getRoomFacilities(String roomId);
  Future<Either<Failure, Unit>> saveRoomFacilities(
    String roomId,
    List<String> facilities,
  );
}
