import 'package:flutter/material.dart';

import '../../../../../core/l10n/app_strings.dart';

enum SuperAdminSortOption {
  newest('Terbaru'),
  oldest('Terlama'),
  nameAsc('Nama A-Z'),
  nameDesc('Nama Z-A');

  const SuperAdminSortOption(this.label);
  final String label;
}

extension SuperAdminSortOptionLabel on SuperAdminSortOption {
  String localizedLabel(AppStrings strings) => switch (this) {
        SuperAdminSortOption.newest => strings.newest,
        SuperAdminSortOption.oldest => strings.oldest,
        SuperAdminSortOption.nameAsc => strings.nameAsc,
        SuperAdminSortOption.nameDesc => strings.nameDesc,
      };
}

class SuperAdminListControls extends StatelessWidget {
  const SuperAdminListControls({
    required this.searchHint,
    required this.onSearchChanged,
    this.filterOptions = const [],
    this.selectedFilter,
    this.onFilterChanged,
    this.sortOptions = SuperAdminSortOption.values,
    this.selectedSort = SuperAdminSortOption.newest,
    this.onSortChanged,
    super.key,
  });

  final String searchHint;
  final ValueChanged<String> onSearchChanged;
  final List<SuperAdminFilterOption> filterOptions;
  final String? selectedFilter;
  final ValueChanged<String?>? onFilterChanged;
  final List<SuperAdminSortOption> sortOptions;
  final SuperAdminSortOption selectedSort;
  final ValueChanged<SuperAdminSortOption>? onSortChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        TextField(
          decoration: InputDecoration(
            hintText: searchHint,
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: colorScheme.surfaceContainerLow,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.45),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.45),
              ),
            ),
          ),
          onChanged: onSearchChanged,
        ),
        if (filterOptions.isNotEmpty || onSortChanged != null) ...[
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final filter = filterOptions.isNotEmpty && onFilterChanged != null
                  ? _FilterDropdown(
                      strings: strings,
                      filterOptions: filterOptions,
                      selectedFilter: selectedFilter,
                      onFilterChanged: onFilterChanged!,
                    )
                  : null;
              final sort = onSortChanged != null
                  ? _SortDropdown(
                      strings: strings,
                      sortOptions: sortOptions,
                      selectedSort: selectedSort,
                      onSortChanged: onSortChanged!,
                    )
                  : null;

              if (constraints.maxWidth < 330) {
                return Column(
                  children: [
                    if (filter != null) filter,
                    if (filter != null && sort != null)
                      const SizedBox(height: 10),
                    if (sort != null) sort,
                  ],
                );
              }

              return Row(
                children: [
                  if (filter != null) Expanded(child: filter),
                  if (filter != null && sort != null) const SizedBox(width: 12),
                  if (sort != null) Expanded(child: sort),
                ],
              );
            },
          ),
        ],
      ],
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.strings,
    required this.filterOptions,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  final AppStrings strings;
  final List<SuperAdminFilterOption> filterOptions;
  final String? selectedFilter;
  final ValueChanged<String?> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String?>(
      initialValue: selectedFilter,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: strings.filter,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: [
        DropdownMenuItem<String?>(
          value: null,
          child: Text(strings.all),
        ),
        for (final option in filterOptions)
          DropdownMenuItem(
            value: option.value,
            child: Text(option.label, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: onFilterChanged,
    );
  }
}

class _SortDropdown extends StatelessWidget {
  const _SortDropdown({
    required this.strings,
    required this.sortOptions,
    required this.selectedSort,
    required this.onSortChanged,
  });

  final AppStrings strings;
  final List<SuperAdminSortOption> sortOptions;
  final SuperAdminSortOption selectedSort;
  final ValueChanged<SuperAdminSortOption> onSortChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<SuperAdminSortOption>(
      initialValue: selectedSort,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: strings.sortBy,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: [
        for (final option in sortOptions)
          DropdownMenuItem(
            value: option,
            child: Text(option.localizedLabel(strings),
                overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (value) {
        if (value != null) onSortChanged(value);
      },
    );
  }
}

class SuperAdminPaginationBar extends StatelessWidget {
  const SuperAdminPaginationBar({
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    super.key,
  });

  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed:
              currentPage > 0 ? () => onPageChanged(currentPage - 1) : null,
          icon: const Icon(Icons.chevron_left),
        ),
        Text(
          AppStrings.of(context).tr(
            'Halaman ${currentPage + 1} / $totalPages',
            'Page ${currentPage + 1} / $totalPages',
          ),
        ),
        IconButton(
          onPressed: currentPage < totalPages - 1
              ? () => onPageChanged(currentPage + 1)
              : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class SuperAdminStatusChip extends StatelessWidget {
  const SuperAdminStatusChip({
    required this.label,
    required this.color,
    super.key,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(
            alpha: colorScheme.brightness == Brightness.dark ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}

class SuperAdminSectionHeader extends StatelessWidget {
  const SuperAdminSectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        if (actionLabel != null && onAction != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

List<T> paginateList<T>(List<T> items, int page, int pageSize) {
  if (items.isEmpty) return const [];
  final start = page * pageSize;
  if (start >= items.length) return const [];
  final end = (start + pageSize).clamp(0, items.length);
  return items.sublist(start, end);
}

int totalPagesFor(int itemCount, int pageSize) {
  if (itemCount == 0) return 1;
  return (itemCount / pageSize).ceil();
}

class SuperAdminFilterOption {
  const SuperAdminFilterOption({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;
}
