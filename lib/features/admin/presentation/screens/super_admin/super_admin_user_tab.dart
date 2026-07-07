import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/l10n/app_strings.dart';
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
    final strings = AppStrings.of(context);

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
                searchHint: strings.searchUsersHint,
                onSearchChanged: (value) => setState(() {
                  _search = value.toLowerCase();
                  _page = 0;
                }),
                filterOptions: [
                  SuperAdminFilterOption(
                    value: 'user',
                    label: strings.userLabel,
                  ),
                  SuperAdminFilterOption(
                    value: 'admin',
                    label: strings.adminAgencyLabel,
                  ),
                  SuperAdminFilterOption(
                    value: 'super_admin',
                    label: strings.superAdminLabel,
                  ),
                  SuperAdminFilterOption(
                    value: 'active',
                    label: strings.tr('Aktif', 'Active'),
                  ),
                  SuperAdminFilterOption(
                    value: 'pending',
                    label: strings.tr('Menunggu', 'Pending'),
                  ),
                  SuperAdminFilterOption(
                    value: 'suspended',
                    label: strings.tr('Disuspen', 'Suspended'),
                  ),
                  SuperAdminFilterOption(
                    value: 'disabled',
                    label: strings.tr('Diblokir', 'Banned'),
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
                  title: strings.tr(
                    'Pengguna tidak ditemukan',
                    'No users found',
                  ),
                )
              else ...[
                for (final user in paged) ...[
                  _UserListTile(
                    user: user,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            SuperAdminUserDetailScreen(userId: user.id),
                      ),
                    ),
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
          'user' => user.role == UserRole.user,
          'admin' => user.role == UserRole.admin,
          'super_admin' => user.role == UserRole.superAdmin,
          'active' => user.accountStatus == 'active',
          'pending' => user.accountStatus == 'pending',
          'suspended' => user.accountStatus == 'suspended',
          'disabled' => user.accountStatus == 'disabled',
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
}

class _UserListTile extends ConsumerWidget {
  const _UserListTile({
    required this.user,
    required this.onTap,
  });

  final PlatformUser user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelf = ref.watch(currentUserProvider)?.id == user.id;
    final strings = AppStrings.of(context);
    final lastLogin = user.lastLoginAt == null
        ? '-'
        : DateFormat('dd MMM yyyy, HH:mm').format(user.lastLoginAt!);
    final roleLabel = switch (user.role) {
      UserRole.superAdmin => strings.superAdminLabel,
      UserRole.admin => strings.adminAgencyLabel,
      UserRole.user => strings.userLabel,
    };
    final agencyLabel =
        user.agencyName ?? strings.tr('Tanpa agensi', 'No agency');
    final metadata = '$roleLabel - $agencyLabel - ${user.statusLabel}';

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
                    metadata,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.onSurfaceVariant),
                  ),
                  Text(
                    '${strings.tr('Login', 'Login')}: $lastLogin',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            _UserActionMenu(user: user, isSelf: isSelf),
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
    final strings = AppStrings.of(context);
    return PopupMenuButton<String>(
      tooltip: strings.tr('Aksi pengguna', 'User actions'),
      icon: const Icon(Icons.more_vert),
      onSelected: (value) async {
        final repository = ref.read(superAdminRepositoryProvider);
        String successMessage =
            strings.tr('Aksi pengguna berhasil.', 'User action completed.');
        Object? result;
        if (value == 'suspend') {
          result = await repository.suspendUser(user.id);
          successMessage = strings.tr(
            'Pengguna berhasil disuspen.',
            'User suspended successfully.',
          );
        } else if (value == 'ban') {
          result = await repository.disableUser(user.id);
          successMessage = strings.tr(
            'Pengguna berhasil diblokir.',
            'User banned successfully.',
          );
        } else if (value == 'activate') {
          result = await repository.activateUser(user.id);
          successMessage = strings.tr(
            'Pengguna berhasil diaktifkan kembali.',
            'User reactivated successfully.',
          );
        }
        if (!context.mounted || result == null) return;
        final either = result as dynamic;
        either.match(
          (failure) => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(failure.message)),
          ),
          (_) {
            invalidateSuperAdminData(ref);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(successMessage)),
            );
          },
        );
      },
      itemBuilder: (context) {
        final status = user.accountStatus.toLowerCase();
        final canReactivate =
            status == 'suspended' || status == 'disabled' || status == 'banned';

        return [
          if (canReactivate)
            PopupMenuItem(
              value: 'activate',
              enabled: !isSelf,
              child: Text(
                strings.tr('Aktifkan kembali', 'Reactivate'),
              ),
            )
          else ...[
            PopupMenuItem(
              value: 'suspend',
              enabled: !isSelf,
              child: Text(strings.tr('Disuspen', 'Suspend')),
            ),
            PopupMenuItem(
              value: 'ban',
              enabled: !isSelf,
              child: Text(strings.tr('Blokir', 'Ban')),
            ),
          ],
        ];
      },
    );
  }
}
