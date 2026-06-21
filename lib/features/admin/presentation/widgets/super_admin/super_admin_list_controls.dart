import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

enum SuperAdminSortOption {
  newest('Terbaru'),
  oldest('Terlama'),
  nameAsc('Nama A-Z'),
  nameDesc('Nama Z-A');

  const SuperAdminSortOption(this.label);
  final String label;
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
  final List<String> filterOptions;
  final String? selectedFilter;
  final ValueChanged<String?>? onFilterChanged;
  final List<SuperAdminSortOption> sortOptions;
  final SuperAdminSortOption selectedSort;
  final ValueChanged<SuperAdminSortOption>? onSortChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          decoration: InputDecoration(
            hintText: searchHint,
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: AppColors.surfaceContainerLowest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
            ),
          ),
          onChanged: onSearchChanged,
        ),
        if (filterOptions.isNotEmpty || onSortChanged != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              if (filterOptions.isNotEmpty && onFilterChanged != null)
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    initialValue: selectedFilter,
                    decoration: InputDecoration(
                      labelText: 'Filter',
                      filled: true,
                      fillColor: AppColors.surfaceContainerLowest,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('Semua')),
                      for (final option in filterOptions)
                        DropdownMenuItem(value: option, child: Text(option)),
                    ],
                    onChanged: onFilterChanged,
                  ),
                ),
              if (filterOptions.isNotEmpty && onSortChanged != null) const SizedBox(width: 12),
              if (onSortChanged != null)
                Expanded(
                  child: DropdownButtonFormField<SuperAdminSortOption>(
                    initialValue: selectedSort,
                    decoration: InputDecoration(
                      labelText: 'Urutkan',
                      filled: true,
                      fillColor: AppColors.surfaceContainerLowest,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: [
                      for (final option in sortOptions)
                        DropdownMenuItem(value: option, child: Text(option.label)),
                    ],
                    onChanged: (value) {
                      if (value != null) onSortChanged!(value);
                    },
                  ),
                ),
            ],
          ),
        ],
      ],
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
          onPressed: currentPage > 0 ? () => onPageChanged(currentPage - 1) : null,
          icon: const Icon(Icons.chevron_left),
        ),
        Text('Halaman ${currentPage + 1} / $totalPages'),
        IconButton(
          onPressed: currentPage < totalPages - 1 ? () => onPageChanged(currentPage + 1) : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class SuperAdminStatusChip extends StatelessWidget {
  const SuperAdminStatusChip({required this.label, required this.color, super.key});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
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
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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
