class SupportTicket {
  const SupportTicket({
    required this.id,
    required this.userId,
    required this.subject,
    required this.category,
    required this.status,
    required this.priority,
    this.facilityId,
    this.bookingId,
  });

  final String id;
  final String userId;
  final String? facilityId;
  final String? bookingId;
  final String subject;
  final String category;
  final String status;
  final String priority;
}
