import '../../../rooms/domain/entities/room.dart';

class PlatformRoom {
  const PlatformRoom({
    required this.room,
    required this.agencyName,
    this.agencyId,
    this.facilities = const [],
  });

  final Room room;
  final String agencyName;
  final String? agencyId;
  final List<String> facilities;
}
