import '../../domain/entities/booking.dart';
import '../../domain/repositories/booking_repository.dart';

/// Cancels unpaid bookings older than [maxAge] using the existing repository API.
/// Safe to call on list refresh — idempotent for already-cancelled bookings.
Future<void> autoCancelStalePendingBookings({
  required List<Booking> bookings,
  required BookingRepository repository,
  Duration maxAge = const Duration(hours: 24),
}) async {
  final cutoff = DateTime.now().subtract(maxAge);

  for (final booking in bookings) {
    if (booking.status != 'pending_payment') continue;
    final created = booking.createdAt;
    if (created == null || !created.isBefore(cutoff)) continue;
    await repository.cancelBooking(booking.id);
  }
}
