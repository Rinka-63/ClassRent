import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/l10n/app_strings.dart';
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
    final strings = AppStrings.of(context);

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
                searchHint: strings.searchActivitiesHint,
                onSearchChanged: (value) => setState(() {
                  _search = value.toLowerCase();
                  _page = 0;
                }),
                filterOptions: [
                  SuperAdminFilterOption(
                    value: 'auth',
                    label: strings.tr('Masuk/Keluar', 'Sign in/out'),
                  ),
                  SuperAdminFilterOption(
                    value: 'agency',
                    label: strings.agency,
                  ),
                  SuperAdminFilterOption(
                    value: 'room',
                    label: strings.rooms,
                  ),
                  SuperAdminFilterOption(
                    value: 'user',
                    label: strings.users,
                  ),
                  SuperAdminFilterOption(
                    value: 'booking',
                    label: strings.bookings,
                  ),
                  SuperAdminFilterOption(
                    value: 'payment',
                    label: strings.payments,
                  ),
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
                EmptyState(
                  title: strings.tr('Audit log kosong', 'Audit log is empty'),
                )
              else ...[
                for (final log in paged) ...[
                  _AuditLogTile(
                    log: log,
                    dateFormat: dateFormat,
                    strings: strings,
                  ),
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
          'auth' => action.contains('login') || action.contains('logout'),
          'agency' => entity.contains('agency') || action.contains('agency'),
          'room' => entity.contains('room') || action.contains('room'),
          'user' => entity.contains('user') || action.contains('user'),
          'booking' => entity.contains('booking') || action.contains('booking'),
          'payment' => entity.contains('payment') || action.contains('payment'),
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
  const _AuditLogTile({
    required this.log,
    required this.dateFormat,
    required this.strings,
  });

  final AuditLogEntry log;
  final DateFormat dateFormat;
  final AppStrings strings;

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
                _Line(strings.time, dateFormat.format(log.createdAt)),
                _Line(strings.actor,
                    log.actorName ?? _formatActorId(log.actorId)),
                _Line(strings.role, log.actorRole ?? '-'),
                _Line(
                    strings.target,
                    log.entityLabel ??
                        _formatEntityType(log.entityType, log.entityId)),
                if (changes.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: EdgeInsets.zero,
                    title: Text(
                      strings.details,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
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
    const labels = {
      'full_name': 'Nama',
      'phone': 'Telepon',
      'email': 'Email',
      'name': 'Nama',
      'description': 'Deskripsi',
      'room_type': 'Tipe Ruangan',
      'capacity': 'Kapasitas',
      'hourly_rate': 'Tarif Per Jam',
      'daily_rate': 'Tarif Harian',
      'city': 'Kota',
      'address': 'Alamat',
      'is_active': 'Status Aktif',
      'requires_approval': 'Perlu Persetujuan',
      'account_status': 'Status Akun',
      'approval_status': 'Status Approval',
      'role': 'Peran',
      'search_vector': 'Kata Kunci Pencarian',
      'preview_url': 'Foto Utama',
      'logo_url': 'Logo',
    };
    final mapped = labels[key.toLowerCase()];
    if (mapped != null) return mapped;
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
    if (value is bool) return value ? 'Ya' : 'Tidak';
    final text = value.toString();
    const values = {
      'true': 'Ya',
      'false': 'Tidak',
      'classroom': 'Ruang Kelas',
      'meeting_room': 'Ruang Rapat',
      'studio': 'Studio',
      'hall': 'Aula',
      'active': 'Aktif',
      'inactive': 'Tidak Aktif',
      'suspended': 'Disuspend',
      'disabled': 'Dinonaktifkan',
      'deleted': 'Dihapus',
      'pending': 'Menunggu',
      'approved': 'Disetujui',
      'rejected': 'Ditolak',
      'user': 'Pengguna',
      'ADMIN': 'Admin Agensi',
      'SUPER_ADMIN': 'Super Admin',
      'admin': 'Admin Agensi',
      'super_admin': 'Super Admin',
    };
    final mapped = values[text];
    if (mapped != null) return mapped;
    if (text.length > 80) return '${text.substring(0, 80)}...';
    return text;
  }

  String _formatActorId(String? actorId) {
    if (actorId == null) return '-';
    // If it's a UUID, show a shortened version
    if (actorId.length == 36 && actorId.contains('-')) {
      return '${actorId.substring(0, 8)}...';
    }
    return actorId;
  }

  String _formatEntityType(String? entityType, String? entityId) {
    if (entityType == null) return '-';
    final type = _titleCase(entityType);
    if (entityId != null && entityId.length == 36 && entityId.contains('-')) {
      return '$type (${entityId.substring(0, 8)}...)';
    }
    return type;
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
    final title = _actionTitle(action);
    if (action.contains('booking')) {
      return const _AuditDescriptor(
        title: 'Pesanan Dibuat / Diperbarui',
        badge: 'Pesanan',
        icon: Icons.event_note_outlined,
        color: AppColors.primary,
      );
    }
    if (action.contains('payment')) {
      return const _AuditDescriptor(
        title: 'Pembayaran Diperbarui',
        badge: 'Pembayaran',
        icon: Icons.payments_outlined,
        color: AppColors.secondary,
      );
    }
    if (action.contains('password')) {
      return const _AuditDescriptor(
        title: 'Reset Kata Sandi',
        badge: 'Keamanan',
        icon: Icons.lock_reset_outlined,
        color: AppColors.tertiary,
      );
    }
    if (action.contains('agency')) {
      return _AuditDescriptor(
        title: title,
        badge: 'Agensi',
        icon: Icons.apartment_outlined,
        color: action.contains('reject') || action.contains('suspend')
            ? AppColors.error
            : AppColors.secondary,
      );
    }
    if (action.contains('user') || action.contains('role')) {
      return _AuditDescriptor(
        title: title,
        badge: 'Pengguna',
        icon: Icons.person_outline,
        color: action.contains('suspend') || action.contains('disable')
            ? AppColors.error
            : AppColors.primary,
      );
    }
    if (action.contains('login') || action.contains('logout')) {
      return const _AuditDescriptor(
        title: 'Masuk / Keluar',
        badge: 'Autentikasi',
        icon: Icons.login_outlined,
        color: AppColors.primary,
      );
    }
    return _AuditDescriptor(
      title: title,
      badge: _titleCase(log.entityType),
      icon: Icons.history_outlined,
      color: AppColors.onSurfaceVariant,
    );
  }
}

String _actionTitle(String action) {
  const titles = {
    'login': 'Masuk',
    'logout': 'Keluar',
    'user_updated': 'Pengguna Diperbarui',
    'agency_updated': 'Agensi Diperbarui',
    'agency_approved': 'Agensi Disetujui',
    'agency_rejected': 'Agensi Ditolak',
    'agency_suspended': 'Agensi Disuspen',
    'agency_reactivated': 'Agensi Diaktifkan',
    'agency_deleted': 'Agensi Dihapus',
    'room_updated': 'Ruangan Diperbarui',
    'room_deleted': 'Ruangan Dihapus',
    'password_reset_requested': 'Reset Kata Sandi Diminta',
    'agency_ownership_transferred': 'Kepemilikan Agensi Dipindahkan',
  };
  return titles[action] ?? _titleCase(action.replaceAll('_', ' '));
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
