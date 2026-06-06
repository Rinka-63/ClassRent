class Review {
  const Review({
    required this.id,
    required this.roomId,
    required this.bookingId,
    required this.userId,
    required this.rating,
    this.comment,
  });

  final String id;
  final String roomId;
  final String bookingId;
  final String userId;
  final int rating;
  final String? comment;
}
