import '../../domain/entities/notification.dart';

class NotificationDto {
  const NotificationDto({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.isRead,
    this.readAt,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  factory NotificationDto.fromJson(Map<String, dynamic> json) {
    return NotificationDto(
      id: json['id'] as String,
      userId: (json['receiver_id'] ?? json['user_id']) as String,
      type: json['type'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      data: {
        if (json['data'] is Map)
          ...Map<String, dynamic>.from(json['data'] as Map),
        if (json['reference_id'] != null) 'reference_id': json['reference_id'],
        if (json['sender_id'] != null) 'sender_id': json['sender_id'],
      },
      isRead: json['is_read'] as bool? ?? false,
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  AppNotification toEntity() {
    return AppNotification(
      id: id,
      userId: userId,
      type: type,
      title: title,
      body: body,
      data: data,
      isRead: isRead,
      readAt: readAt,
      createdAt: createdAt,
    );
  }
}
