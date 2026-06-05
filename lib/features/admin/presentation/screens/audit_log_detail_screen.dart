import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/error_card.dart';
import '../../domain/entities/audit_log_entry.dart';
import '../../../../shared/presentation/widgets/admin_nav_bar.dart';
import '../providers/admin_overview_providers.dart';

class AuditLogDetailScreen extends ConsumerWidget {
  const AuditLogDetailScreen({required this.auditId, super.key});

  final String auditId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyValue = ref.watch(adminHistoryProvider);

    return AppScaffold(
      title: 'Audit Detail',
      actions: [
        IconButton(
          onPressed: () => context.go(AppRoutes.adminHistory),
          icon: const Icon(Icons.arrow_back),
        ),
      ],
      bottomNavigationBar: const AdminNavBar(currentPath: AppRoutes.adminHistory),
      body: historyValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(16),
          child: ErrorCard(message: error.toString()),
        ),
        data: (entries) {
          AuditLogEntry? entry;
          for (final item in entries) {
            if (item.id == auditId) {
              entry = item;
              break;
            }
          }
          if (entry == null) {
            return const Center(child: Text('Audit log not found'));
          }
          final AuditLogEntry log = entry;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _HeaderCard(log: log),
              const SizedBox(height: 16),
              _ChangeCard(log: log),
              const SizedBox(height: 16),
              _JsonCard(title: 'Old Data', data: log.oldData),
              const SizedBox(height: 12),
              _JsonCard(title: 'New Data', data: log.newData),
            ],
          );
        },
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.log});

  final dynamic log;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(log.action, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(log.description),
            const SizedBox(height: 12),
            _detailRow('Agency', log.agencyName ?? '-'),
            _detailRow('Admin', log.actorName ?? '-'),
            _detailRow('Role', log.actorRole ?? '-'),
            _detailRow('Entity', log.entityName ?? log.entityType),
            _detailRow('Time', formatter.format(log.createdAt)),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Flexible(child: Text(value, textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}

class _ChangeCard extends StatelessWidget {
  const _ChangeCard({required this.log});

  final dynamic log;

  @override
  Widget build(BuildContext context) {
    final oldData = log.oldData as Map<String, dynamic>?;
    final newData = log.newData as Map<String, dynamic>?;
    if (oldData == null && newData == null) {
      return const SizedBox.shrink();
    }

    final keys = <String>{...?oldData?.keys, ...?newData?.keys}.toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Changes', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            for (final key in keys)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(key.replaceAll('_', ' '), style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    _ChangeLine(
                      oldValue: oldData?[key]?.toString() ?? '-',
                      newValue: newData?[key]?.toString() ?? '-',
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ChangeLine extends StatelessWidget {
  const _ChangeLine({required this.oldValue, required this.newValue});

  final String oldValue;
  final String newValue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(oldValue, style: const TextStyle(color: AppColors.onSurfaceVariant)),
        const SizedBox(height: 4),
        const Icon(Icons.arrow_downward, size: 16, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(newValue, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _JsonCard extends StatelessWidget {
  const _JsonCard({
    required this.title,
    required this.data,
  });

  final String title;
  final Map<String, dynamic>? data;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Text(data?.entries.map((e) => '${e.key}: ${e.value}').join('\n') ?? '-'),
          ],
        ),
      ),
    );
  }
}
