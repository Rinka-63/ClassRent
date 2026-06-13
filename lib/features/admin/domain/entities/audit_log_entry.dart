class AuditLogEntry {
  const AuditLogEntry({
    required this.id,
    required this.actorId,
    required this.actorName,
    required this.actorRole,
    required this.agencyId,
    required this.agencyName,
    required this.action,
    required this.entityType,
    required this.entityName,
    required this.createdAt,
    required this.summary,
    required this.description,
    this.entityId,
    this.oldData,
    this.newData,
  });

  final String id;
  final String? actorId;
  final String? actorName;
  final String? actorRole;
  final String? agencyId;
  final String? agencyName;
  final String action;
  final String entityType;
  final String? entityId;
  final String? entityName;
  final DateTime createdAt;
  final String summary;
  final String description;
  final Map<String, dynamic>? oldData;
  final Map<String, dynamic>? newData;
}
