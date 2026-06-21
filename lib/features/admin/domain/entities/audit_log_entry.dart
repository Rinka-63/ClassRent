class AuditLogEntry {
  const AuditLogEntry({
    required this.id,
    required this.action,
    required this.entityType,
    required this.createdAt,
    this.actorId,
    this.actorName,
    this.actorRole,
    this.entityId,
    this.entityLabel,
    this.oldData,
    this.newData,
  });

  final String id;
  final String action;
  final String entityType;
  final String? actorId;
  final String? actorName;
  final String? actorRole;
  final String? entityId;
  final String? entityLabel;
  final Map<String, dynamic>? oldData;
  final Map<String, dynamic>? newData;
  final DateTime createdAt;
}
