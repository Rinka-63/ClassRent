import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/room.dart';

abstract interface class RoomsRepository {
  Future<Either<Failure, List<Room>>> getRooms();
  Future<Either<Failure, Room>> getRoomById(String id);
}
