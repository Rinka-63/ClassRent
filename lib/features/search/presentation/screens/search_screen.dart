import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_card.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../shared/presentation/widgets/role_aware_nav_bar.dart';
import '../../../rooms/domain/entities/room.dart';
import '../../../rooms/presentation/providers/rooms_providers.dart';
import '../../../rooms/presentation/widgets/room_card.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

class RoomSearchFilters {
  const RoomSearchFilters({
    this.minPrice,
    this.maxPrice,
    this.minCapacity,
    this.building,
    this.floor,
    this.facilities = const [],
    this.status,
    this.instantOnly = false,
    this.verifiedOnly = false,
    this.sort = RoomSortOption.newest,
  });

  final double? minPrice;
  final double? maxPrice;
  final int? minCapacity;
  final String? building;
  final String? floor;
  final List<String> facilities;
  final String? status;
  final bool instantOnly;
  final bool verifiedOnly;
  final RoomSortOption sort;

  RoomSearchFilters copyWith({
    double? minPrice,
    double? maxPrice,
    int? minCapacity,
    String? building,
    String? floor,
    List<String>? facilities,
    String? status,
    bool? instantOnly,
    bool? verifiedOnly,
    RoomSortOption? sort,
  }) {
    return RoomSearchFilters(
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      minCapacity: minCapacity ?? this.minCapacity,
      building: building ?? this.building,
      floor: floor ?? this.floor,
      facilities: facilities ?? this.facilities,
      status: status ?? this.status,
      instantOnly: instantOnly ?? this.instantOnly,
      verifiedOnly: verifiedOnly ?? this.verifiedOnly,
      sort: sort ?? this.sort,
    );
  }

  int get activeCount {
    var count = 0;
    if (minPrice != null || maxPrice != null) count++;
    if (minCapacity != null) count++;
    if (building != null && building!.isNotEmpty) count++;
    if (floor != null && floor!.isNotEmpty) count++;
    if (facilities.isNotEmpty) count++;
    if (status != null) count++;
    if (instantOnly) count++;
    if (verifiedOnly) count++;
    return count;
  }
}

enum RoomSortOption {
  newest,
  cheapest,
  expensive,
  rating,
  mostBooked,
}

final roomSearchFiltersProvider =
    StateProvider<RoomSearchFilters>((ref) => const RoomSearchFilters());

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchQueryProvider);
    final filters = ref.watch(roomSearchFiltersProvider);
    final roomsAsync = ref.watch(roomsProvider);
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppScaffold(
      title: strings.allRooms,
      bottomNavigationBar: const RoleAwareNavBar(currentPath: AppRoutes.search),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            color: colorScheme.surface,
            child: Column(
              children: [
                TextField(
                  onChanged: (val) =>
                      ref.read(searchQueryProvider.notifier).state = val,
                  decoration: InputDecoration(
                    hintText: strings.searchRoomsHint,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (query.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear,
                                color: AppColors.onSurfaceVariant),
                            onPressed: () {
                              ref.read(searchQueryProvider.notifier).state = '';
                            },
                          ),
                        IconButton(
                          icon: Badge(
                            isLabelVisible: filters.activeCount > 0,
                            label: Text('${filters.activeCount}'),
                            child: const Icon(Icons.tune_rounded),
                          ),
                          onPressed: () => _showFilterSheet(context, ref),
                        ),
                      ],
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${strings.sortBy}: ${_sortLabel(strings, filters.sort)}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: roomsAsync.when(
              loading: () => LoadingView(
                message: strings.tr(
                  'Memuat daftar ruangan...',
                  'Loading room list...',
                ),
              ),
              error: (err, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: ErrorCard(message: err.toString()),
              ),
              data: (rooms) {
                final filtered = _applyFilters(rooms, query, filters);

                if (filtered.isEmpty) {
                  return EmptyState(
                    icon: Icons.search_off_rounded,
                    title: strings.roomNotFound,
                    message: query.isEmpty
                        ? strings.noRoomsMatch
                        : strings.tr(
                            'Tidak ada ruangan yang cocok dengan "$query".',
                            'No rooms match "$query".',
                          ),
                    actionLabel: strings.resetFilter,
                    onAction: () {
                      ref.read(roomSearchFiltersProvider.notifier).state =
                          const RoomSearchFilters();
                      ref.read(searchQueryProvider.notifier).state = '';
                    },
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final maxCrossAxisExtent =
                        constraints.maxWidth > 600 ? 280.0 : 210.0;
                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: maxCrossAxisExtent,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        mainAxisExtent: 310,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (_, index) => RoomCard(
                        room: filtered[index],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Room> _applyFilters(
    List<Room> rooms,
    String query,
    RoomSearchFilters filters,
  ) {
    var result = rooms.where((room) {
      final q = query.toLowerCase().trim();
      final matchQuery = q.isEmpty ||
          room.name.toLowerCase().contains(q) ||
          room.city.toLowerCase().contains(q) ||
          (room.address?.toLowerCase().contains(q) ?? false) ||
          room.capacity.toString().contains(q);

      final matchPrice = (filters.minPrice == null ||
              room.hourlyRate >= filters.minPrice!) &&
          (filters.maxPrice == null || room.hourlyRate <= filters.maxPrice!);

      final matchCapacity =
          filters.minCapacity == null || room.capacity >= filters.minCapacity!;

      final matchBuilding = filters.building == null ||
          filters.building!.isEmpty ||
          room.city.toLowerCase().contains(filters.building!.toLowerCase()) ||
          (room.address
                  ?.toLowerCase()
                  .contains(filters.building!.toLowerCase()) ??
              false);

      final matchFloor = filters.floor == null ||
          filters.floor!.isEmpty ||
          (room.address?.toLowerCase().contains(filters.floor!.toLowerCase()) ??
              false);

      final matchStatus = switch (filters.status) {
        'available' => room.isActive,
        'full' => !room.isActive,
        _ => true,
      };

      final matchInstant = !filters.instantOnly || !room.requiresApproval;
      final matchVerified =
          !filters.verifiedOnly || (room.isActive && room.avgRating >= 4);

      return matchQuery &&
          matchPrice &&
          matchCapacity &&
          matchBuilding &&
          matchFloor &&
          matchStatus &&
          matchInstant &&
          matchVerified;
    }).toList();

    switch (filters.sort) {
      case RoomSortOption.cheapest:
        result.sort((a, b) => a.hourlyRate.compareTo(b.hourlyRate));
      case RoomSortOption.expensive:
        result.sort((a, b) => b.hourlyRate.compareTo(a.hourlyRate));
      case RoomSortOption.rating:
        result.sort((a, b) => b.avgRating.compareTo(a.avgRating));
      case RoomSortOption.mostBooked:
        result.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
      case RoomSortOption.newest:
        result.sort((a, b) => b.id.compareTo(a.id));
    }

    return result;
  }

  String _sortLabel(AppStrings strings, RoomSortOption sort) => switch (sort) {
        RoomSortOption.newest => strings.newest,
        RoomSortOption.cheapest => strings.tr('Termurah', 'Cheapest'),
        RoomSortOption.expensive => strings.tr('Termahal', 'Most Expensive'),
        RoomSortOption.rating => strings.tr('Rating', 'Rating'),
        RoomSortOption.mostBooked =>
          strings.tr('Paling Banyak Dipesan', 'Most Booked'),
      };

  Future<void> _showFilterSheet(BuildContext context, WidgetRef ref) async {
    final current = ref.read(roomSearchFiltersProvider);
    final strings = AppStrings.of(context);
    final minPriceCtrl =
        TextEditingController(text: current.minPrice?.toInt().toString() ?? '');
    final maxPriceCtrl =
        TextEditingController(text: current.maxPrice?.toInt().toString() ?? '');
    final capacityCtrl =
        TextEditingController(text: current.minCapacity?.toString() ?? '');
    final buildingCtrl = TextEditingController(text: current.building ?? '');
    final floorCtrl = TextEditingController(text: current.floor ?? '');
    var selectedStatus = current.status;
    var instantOnly = current.instantOnly;
    var verifiedOnly = current.verifiedOnly;
    var sort = current.sort;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.outlineVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(strings.filterSort,
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    Text(strings.pricePerHour,
                        style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: minPriceCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: strings.min,
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: maxPriceCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: strings.max,
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: capacityCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: strings.minimumCapacity,
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: buildingCtrl,
                      decoration: InputDecoration(
                        labelText: strings.buildingOrCity,
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: floorCtrl,
                      decoration: InputDecoration(
                        labelText: strings.floor,
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(strings.status,
                        style: Theme.of(context).textTheme.labelLarge),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: Text(strings.allStatuses),
                          selected: selectedStatus == null,
                          onSelected: (_) =>
                              setState(() => selectedStatus = null),
                        ),
                        ChoiceChip(
                          label: Text(strings.available),
                          selected: selectedStatus == 'available',
                          onSelected: (_) =>
                              setState(() => selectedStatus = 'available'),
                        ),
                        ChoiceChip(
                          label: Text(strings.full),
                          selected: selectedStatus == 'full',
                          onSelected: (_) =>
                              setState(() => selectedStatus = 'full'),
                        ),
                      ],
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(strings.tr('Booking Instan', 'Instant Booking')),
                      value: instantOnly,
                      onChanged: (v) => setState(() => instantOnly = v),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(strings.tr('Terverifikasi', 'Verified')),
                      value: verifiedOnly,
                      onChanged: (v) => setState(() => verifiedOnly = v),
                    ),
                    const SizedBox(height: 8),
                    Text(strings.sortBy,
                        style: Theme.of(context).textTheme.labelLarge),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: RoomSortOption.values.map((option) {
                        return ChoiceChip(
                          label: Text(_sortLabel(strings, option)),
                          selected: sort == option,
                          onSelected: (_) => setState(() => sort = option),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              ref
                                  .read(roomSearchFiltersProvider.notifier)
                                  .state = const RoomSearchFilters();
                              Navigator.pop(sheetContext);
                            },
                            child: Text(strings.reset),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              ref
                                  .read(roomSearchFiltersProvider.notifier)
                                  .state = RoomSearchFilters(
                                minPrice: double.tryParse(minPriceCtrl.text),
                                maxPrice: double.tryParse(maxPriceCtrl.text),
                                minCapacity: int.tryParse(capacityCtrl.text),
                                building: buildingCtrl.text.trim().isEmpty
                                    ? null
                                    : buildingCtrl.text.trim(),
                                floor: floorCtrl.text.trim().isEmpty
                                    ? null
                                    : floorCtrl.text.trim(),
                                status: selectedStatus,
                                instantOnly: instantOnly,
                                verifiedOnly: verifiedOnly,
                                sort: sort,
                              );
                              Navigator.pop(sheetContext);
                            },
                            child: Text(strings.apply),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
