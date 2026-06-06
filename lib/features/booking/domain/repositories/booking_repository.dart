import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../entities/booking.dart';

abstract interface class BookingRepository {
  Future<Either<Failure, List<Booking>>> getBookingsForAgency(String adminId);
  Future<Either<Failure, List<Booking>>> getBookingsForRoom(String roomId);
  Future<Either<Failure, Booking>> createBooking(Map<String, dynamic> payload);
  Future<Either<Failure, Booking>> updateBooking(String id, Map<String, dynamic> payload);
  Future<Either<Failure, Unit>> cancelBooking(String id);
}
