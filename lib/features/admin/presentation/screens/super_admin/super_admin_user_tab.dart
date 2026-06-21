import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/empty_state.dart';
import '../../../../../core/widgets/error_card.dart';
import '../../../../../shared/domain/entities/app_user.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../domain/entities/platform_user.dart';
import '../../providers/super_admin_providers.dart';
import '../../widgets/super_admin/super_admin_list_controls.dart';
import 'super_admin_user_detail_screen.dart';

class SuperAdminUserTab extends ConsumerStatefulWidget {
  const SuperAdminUserTab({super.key});

  @override
  ConsumerState<SuperAdminUserTab> createState() => _SuperAdminUserTabState();
}

class _SuperAdminUserTabState extends ConsumerState<SuperAdminUserTab> {
  String _search = '';
  String? _filter;
  SuperAdminSortOption _sort = SuperAdminSortOption.newest;
  int _page = 0;
  static const _pageSize = 10;

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(platformUsersProvider);
    final dateFormat = DateFormat('dd MMM yyyy');

    return usersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: ErrorCard(
          message: error.toString(),
          onRetry: () => ref.invalidate(platformUsersProvider),
        ),
      ),
      data: (users) {
        final filtered = _applyFilters(users);
        final paged = paginateList(filtered, _page, _pageSize);
        final totalPages = totalPagesFor(filtered.length, _pageSize);

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(platformUsersProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SuperAdminListControls(
                searchHint: 'Cari user...',
                onSearchChanged: (value) => setState(() {
                  _search = value.toLowerCase();
                  _page = 0;
                }),
                filterOptions: const [
                  'User',
                  'Agency Admin',
                  'Super Admin',
                  'Active',
                  'Pending',
                  'Suspended',
                  'Disabled',
                  'Deleted',
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
                const EmptyState(title: 'User tidak ditemukan')
              else ...[
                for (final user in paged) ...[
                  _UserListTile(
                    user: user,
                    dateFormat: dateFormat,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            SuperAdminUserDetailScreen(userId: user.id),
                      ),
                    ),
                    onEdit: () => _editUser(context, user),
                    onDelete: () => _deleteUser(context, user),
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

  List<PlatformUser> _applyFilters(List<PlatformUser> users) {
    var result = users.where((user) {
      final query = _search.trim();
      if (query.isEmpty) return true;
      return user.fullName.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query) ||
          (user.agencyName?.toLowerCase().contains(query) ?? false);
    }).toList();

    if (_filter != null) {
      result = result.where((user) {
        return switch (_filter) {
          'User' => user.role == UserRole.user,
          'Agency Admin' => user.role == UserRole.admin,
          'Super Admin' => user.role == UserRole.superAdmin,
          'Active' => user.accountStatus == 'active',
          'Pending' => user.accountStatus == 'pending',
          'Suspended' => user.accountStatus == 'suspended',
          'Disabled' => user.accountStatus == 'disabled',
          'Deleted' => user.accountStatus == 'deleted',
          _ => true,
        };
      }).toList();
    }

    result.sort((a, b) {
      return switch (_sort) {
        SuperAdminSortOption.newest =>
          (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
              .compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)),
        SuperAdminSortOption.oldest =>
          (a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
              .compareTo(b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)),
        SuperAdminSortOption.nameAsc => a.fullName.compareTo(b.fullName),
        SuperAdminSortOption.nameDesc => b.fullName.compareTo(a.fullName),
      };
    });

    return result;
  }

  Future<void> _editUser(BuildContext context, PlatformUser user) async {
    final nameController = TextEditingController(text: user.fullName);
    final phoneController = TextEditingController(text: user.phone ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nama')),
            TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Telepon')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Simpan')),
        ],
      ),
    );

    if (saved == true) {
      await ref.read(superAdminRepositoryProvider).updateUser(user.id, {
        'full_name': nameController.text.trim(),
        'phone': phoneController.text.trim(),
      });
      invalidateSuperAdminData(ref);
    }
  }

  Future<void> _deleteUser(BuildContext context, PlatformUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus User?'),
        content: Text('User "${user.fullName}" akan di-soft delete.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Hapus')),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(superAdminRepositoryProvider).deleteUser(user.id);
      invalidateSuperAdminData(ref);
    }
  }
}

class _UserListTile extends ConsumerWidget {
  const _UserListTile({
    required this.user,
    required this.dateFormat,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final PlatformUser user;
  final DateFormat dateFormat;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelf = ref.watch(currentUserProvider)?.id == user.id;
    final lastLogin = user.lastLoginAt == null
        ? '-'
        : DateFormat('dd MMM yyyy, HH:mm').format(user.lastLoginAt!);
    final roleLabel = switch (user.role) {
      UserRole.superAdmin => 'Super Admin',
      UserRole.admin => 'Agency Admin',
      UserRole.user => 'User',
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.surfaceContainerLow,
              child: Text(user.fullName.characters.first.toUpperCase()),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.fullName,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(user.email,
                      style: const TextStyle(
                          color: AppColors.onSurfaceVariant, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(
                    '$roleLabel • ${user.agencyName ?? 'Tanpa agency'} • ${user.statusLabel}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.onSurfaceVariant),
                  ),
                  Text(
                    'Last Login: $lastLogin | Created: ${dateFormat.format(user.createdAt ?? DateTime.now())}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            _UserActionMenu(user: user, isSelf: isSelf),
            IconButton(
                onPressed: onEdit, icon: const Icon(Icons.edit_outlined)),
            IconButton(
                onPressed: onDelete, icon: const Icon(Icons.delete_outline)),
          ],
        ),
      ),
    );
  }
}

class _UserActionMenu extends ConsumerWidget {
  const _UserActionMenu({required this.user, required this.isSelf});

  final PlatformUser user;
  final bool isSelf;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      tooltip: 'Aksi user',
      icon: const Icon(Icons.more_vert),
      onSelected: (value) async {
        final repository = ref.read(superAdminRepositoryProvider);
        if (value == 'activate') {
          await repository.activateUser(user.id);
        } else if (value == 'suspend') {
          await repository.suspendUser(user.id);
        } else if (value == 'disable') {
          await repository.disableUser(user.id);
        } else if (value == 'reset') {
          await repository.resetUserPassword(user.email);
        } else if (value == 'role') {
          await _changeRole(context, ref);
        } else if (value == 'transfer') {
          await _transferOwnership(context, ref);
        } else if (value == 'delete') {
          await repository.deleteUser(user.id);
        }
        invalidateSuperAdminData(ref);
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'activate',
          enabled: !isSelf,
          child: const Text('Activate'),
        ),
        PopupMenuItem(
          value: 'suspend',
          enabled: !isSelf,
          child: const Text('Suspend'),
        ),
        PopupMenuItem(
          value: 'disable',
          enabled: !isSelf,
          child: const Text('Disable'),
        ),
        const PopupMenuItem(value: 'reset', child: Text('Reset Password')),
        PopupMenuItem(
          value: 'role',
          enabled: !isSelf,
          child: const Text('Change Role'),
        ),
        if (user.agencyId != null)
          PopupMenuItem(
            value: 'transfer',
            enabled: !isSelf,
            child: const Text('Transfer Agency Ownership'),
          ),
        PopupMenuItem(
          value: 'delete',
          enabled: !isSelf,
          child: const Text('Delete Account'),
        ),
      ],
    );
  }

  Future<void> _changeRole(BuildContext context, WidgetRef ref) async {
    var selected = user.role.dbValue.toLowerCase();
    final role = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change Role'),
        content: StatefulBuilder(
          builder: (context, setState) => DropdownButtonFormField<String>(
            initialValue: selected,
            items: const [
              DropdownMenuItem(value: 'user', child: Text('User')),
              DropdownMenuItem(value: 'admin', child: Text('Agency Admin')),
              DropdownMenuItem(
                  value: 'super_admin', child: Text('Super Admin')),
            ],
            onChanged: (value) => setState(() => selected = value ?? selected),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, selected),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (role != null) {
      await ref
          .read(superAdminRepositoryProvider)
          .changeUserRole(user.id, role);
    }
  }

  Future<void> _transferOwnership(BuildContext context, WidgetRef ref) async {
    final emailController = TextEditingController();
    final email = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Transfer Agency Ownership'),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(labelText: 'Email pemilik baru'),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, emailController.text.trim()),
            child: const Text('Transfer'),
          ),
        ],
      ),
    );
    if (email != null && email.isNotEmpty && user.agencyId != null) {
      await ref.read(superAdminRepositoryProvider).transferAgencyOwnership(
            agencyId: user.agencyId!,
            newOwnerEmail: email,
          );
    }
  }
}
