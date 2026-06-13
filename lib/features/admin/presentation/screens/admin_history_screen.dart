import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_card.dart';
import '../../../../shared/presentation/widgets/admin_nav_bar.dart';
import '../providers/admin_overview_providers.dart';

class AdminHistoryScreen extends ConsumerWidget {
  const AdminHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyValue = ref.watch(adminHistoryProvider);
    final formatter = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');

    return AppScaffold(
      title: 'History',
      actions: [
        IconButton(
          onPressed: () => context.push(AppRoutes.profile),
          icon: const Icon(Icons.person_outline),
        ),
      ],
      body: historyValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(16),
          child: ErrorCard(
            message: error.toString(),
            onRetry: () => ref.invalidate(adminHistoryProvider),
          ),
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return const EmptyState(
              title: 'Riwayat belum tersedia',
              message: 'Belum ada audit log untuk agency ini.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(adminHistoryProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: entries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, index) {
                final entry = entries[index];
                return Card(
                  child: ListTile(
                    onTap: () => context.push(
                      AppRoutes.adminAuditDetail.replaceFirst(':auditId', entry.id),
                    ),
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.surfaceContainerLow,
                      child: Icon(Icons.history_outlined),
                    ),
                    title: Text(entry.action),
                    subtitle: Text(
                      '${entry.entityType} ${entry.entityId ?? '-'}\n${formatter.format(entry.createdAt)}',
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
          );
        },
      ),
      bottomNavigationBar: const AdminNavBar(currentPath: AppRoutes.adminHistory),
    );
  }
}
