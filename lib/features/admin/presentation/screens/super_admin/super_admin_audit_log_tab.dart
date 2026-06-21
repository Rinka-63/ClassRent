import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/empty_state.dart';
import '../../../../../core/widgets/error_card.dart';
import '../../../domain/entities/audit_log_entry.dart';
import '../../providers/super_admin_providers.dart';
import '../../widgets/super_admin/super_admin_list_controls.dart';

class SuperAdminAuditLogTab extends ConsumerStatefulWidget {
  const SuperAdminAuditLogTab({super.key});

  @override
  ConsumerState<SuperAdminAuditLogTab> createState() =>
      _SuperAdminAuditLogTabState();
}

class _SuperAdminAuditLogTabState extends ConsumerState<SuperAdminAuditLogTab> {
  String _search = '';
  String? _filter;
  SuperAdminSortOption _sort = SuperAdminSortOption.newest;
  int _page = 0;
  static const _pageSize = 12;

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(platformAuditLogsProvider);
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm:ss');

    return logsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: ErrorCard(
          message: error.toString(),
          onRetry: () => ref.invalidate(platformAuditLogsProvider),
        ),
      ),
      data: (logs) {
        final filtered = _applyFilters(logs);
        final paged = paginateList(filtered, _page, _pageSize);
        final totalPages = totalPagesFor(filtered.length, _pageSize);

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(platformAuditLogsProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SuperAdminListControls(
                searchHint: 'Cari aktivitas, user, entity...',
                onSearchChanged: (value) => setState(() {
                  _search = value.toLowerCase();
                  _page = 0;
                }),
                filterOptions: const [
                  'Login',
                  'Agency',
                  'Room',
                  'User',
                  'Booking',
                  'Payment',
                ],
                selectedFilter: _filter,
                onFilterChanged: (value) => setState(() {
                  _filter = value;
                  _page = 0;
                }),
                selectedSort: _sort,
                onSortChanged: (value) => setState(() => _sort = value),
              ),
              const SizedBox(height: 16),
              if (filtered.isEmpty)
                const EmptyState(title: 'Audit log kosong')
              else ...[
                for (final log in paged) ...[
                  _AuditLogTile(log: log, dateFormat: dateFormat),
                  const SizedBox(height: 12),
                ],
                SuperAdminPaginationBar(
                  currentPage: _page,
                  totalPages: totalPages,
                  onPageChanged: (page) => setState(() => _page = page),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  List<AuditLogEntry> _applyFilters(List<AuditLogEntry> logs) {
    var result = logs.where((log) {
      final query = _search.trim();
      if (query.isEmpty) return true;
      return log.action.toLowerCase().contains(query) ||
          (log.actorName?.toLowerCase().contains(query) ?? false) ||
          log.entityType.toLowerCase().contains(query) ||
          (log.entityLabel?.toLowerCase().contains(query) ?? false);
    }).toList();

    if (_filter != null) {
      result = result.where((log) {
        final action = log.action.toLowerCase();
        final entity = log.entityType.toLowerCase();
        return switch (_filter) {
          'Login' => action.contains('login') || action.contains('logout'),
          'Agency' => entity.contains('agency') || action.contains('agency'),
          'Room' => entity.contains('room') || action.contains('room'),
          'User' => entity.contains('user') || action.contains('user'),
          'Booking' => entity.contains('booking') || action.contains('booking'),
          'Payment' => entity.contains('payment') || action.contains('payment'),
          _ => true,
        };
      }).toList();
    }

    result.sort((a, b) {
      return switch (_sort) {
        SuperAdminSortOption.newest => b.createdAt.compareTo(a.createdAt),
        SuperAdminSortOption.oldest => a.createdAt.compareTo(b.createdAt),
        SuperAdminSortOption.nameAsc => a.action.compareTo(b.action),
        SuperAdminSortOption.nameDesc => b.action.compareTo(a.action),
      };
    });

    return result;
  }
}

class _AuditLogTile extends StatelessWidget {
  const _AuditLogTile({required this.log, required this.dateFormat});

  final AuditLogEntry log;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    final descriptor = _AuditDescriptor.from(log);
    final changes = _humanChanges(log.oldData, log.newData);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: descriptor.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(descriptor.icon, color: descriptor.color, size: 18),
              ),
              Container(width: 2, height: 54, color: AppColors.outlineVariant),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        descriptor.title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    SuperAdminStatusChip(
                      label: descriptor.badge,
                      color: descriptor.color,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _Line('Waktu', dateFormat.format(log.createdAt)),
                _Line('Pelaku', log.actorName ?? log.actorId ?? '-'),
                _Line('Role', log.actorRole ?? '-'),
                _Line('Target', log.entityLabel ?? _titleCase(log.entityType)),
                if (changes.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: EdgeInsets.zero,
                    title: const Text(
                      'Detail Perubahan',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    children: [
                      for (final change in changes)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _Line(change.label, change.value),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<_HumanChange> _humanChanges(
    Map<String, dynamic>? oldData,
    Map<String, dynamic>? newData,
  ) {
    final keys = <String>{
      ...?oldData?.keys,
      ...?newData?.keys,
    }.where((key) => !_hiddenField(key)).toList()
      ..sort();

    final changes = <_HumanChange>[];
    for (final key in keys) {
      final oldValue = oldData?[key];
      final newValue = newData?[key];
      if (oldData != null && newData != null && oldValue == newValue) continue;
      changes.add(
        _HumanChange(
          label: _fieldLabel(key),
          value: oldData != null && newData != null
              ? '${_formatValue(oldValue)} -> ${_formatValue(newValue)}'
              : _formatValue(newValue ?? oldValue),
        ),
      );
    }
    return changes;
  }

  bool _hiddenField(String key) {
    final normalized = key.toLowerCase();
    if (normalized == 'id' ||
        normalized == 'uuid' ||
        normalized == 'version' ||
        normalized == 'deleted_at' ||
        normalized == 'created_at' ||
        normalized == 'updated_at' ||
        normalized == 'qr_token') {
      return true;
    }
    return normalized.endsWith('_id') ||
        normalized.endsWith('_uuid') ||
        normalized.contains('token');
  }

  String _fieldLabel(String key) {
    return key
        .split('_')
        .where((part) => part.isNotEmpty)
        .map(_titleCase)
        .join(' ');
  }

  String _formatValue(Object? value) {
    if (value == null) return '-';
    if (value is DateTime) return dateFormat.format(value);
    if (value is Map || value is List) return 'Data detail tersedia';
    final text = value.toString();
    if (text.length > 80) return '${text.substring(0, 80)}...';
    return text;
  }
}

class _AuditDescriptor {
  const _AuditDescriptor({
    required this.title,
    required this.badge,
    required this.icon,
    required this.color,
  });

  final String title;
  final String badge;
  final IconData icon;
  final Color color;

  factory _AuditDescriptor.from(AuditLogEntry log) {
    final action = log.action.toLowerCase();
    if (action.contains('booking')) {
      return const _AuditDescriptor(
        title: 'Booking Dibuat / Diperbarui',
        badge: 'Booking',
        icon: Icons.event_note_outlined,
        color: AppColors.primary,
      );
    }
    if (action.contains('payment')) {
      return const _AuditDescriptor(
        title: 'Payment Diperbarui',
        badge: 'Payment',
        icon: Icons.payments_outlined,
        color: AppColors.secondary,
      );
    }
    if (action.contains('password')) {
      return const _AuditDescriptor(
        title: 'Password Reset',
        badge: 'Security',
        icon: Icons.lock_reset_outlined,
        color: AppColors.tertiary,
      );
    }
    if (action.contains('agency')) {
      return _AuditDescriptor(
        title: _titleCase(action.replaceAll('_', ' ')),
        badge: 'Agency',
        icon: Icons.apartment_outlined,
        color: action.contains('reject') || action.contains('suspend')
            ? AppColors.error
            : AppColors.secondary,
      );
    }
    if (action.contains('user') || action.contains('role')) {
      return _AuditDescriptor(
        title: _titleCase(action.replaceAll('_', ' ')),
        badge: 'User',
        icon: Icons.person_outline,
        color: action.contains('suspend') || action.contains('disable')
            ? AppColors.error
            : AppColors.primary,
      );
    }
    if (action.contains('login') || action.contains('logout')) {
      return const _AuditDescriptor(
        title: 'Login / Logout',
        badge: 'Auth',
        icon: Icons.login_outlined,
        color: AppColors.primary,
      );
    }
    return _AuditDescriptor(
      title: _titleCase(action.replaceAll('_', ' ')),
      badge: _titleCase(log.entityType),
      icon: Icons.history_outlined,
      color: AppColors.onSurfaceVariant,
    );
  }
}

class _HumanChange {
  const _HumanChange({required this.label, required this.value});

  final String label;
  final String value;
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 86,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

String _titleCase(String value) {
  if (value.isEmpty) return value;
  return value
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1).toLowerCase())
      .join(' ');
}
