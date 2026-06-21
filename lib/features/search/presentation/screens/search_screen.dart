import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../rooms/presentation/providers/rooms_providers.dart';
import '../../../rooms/presentation/widgets/room_card.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchQueryProvider);
    final roomsAsync = ref.watch(roomsProvider);

    return AppScaffold(
      title: 'Pencarian',
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              autofocus: true,
              onChanged: (val) => ref.read(searchQueryProvider.notifier).state = val,
              decoration: InputDecoration(
                hintText: 'Cari nama ruangan, kota, atau kapasitas...',
                prefixIcon: const Icon(Icons.search, color: AppColors.onSurfaceVariant),
                suffixIcon: query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.onSurfaceVariant),
                        onPressed: () {
                          ref.read(searchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                filled: true,
                fillColor: AppColors.surfaceContainerLow,
              ),
            ),
          ),
          Expanded(
            child: roomsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Terjadi kesalahan: $err')),
              data: (rooms) {
                if (query.isEmpty) {
                  return const Center(
                    child: Text('Ketikkan sesuatu untuk mulai mencari', style: TextStyle(color: AppColors.onSurfaceVariant)),
                  );
                }

                final filtered = rooms.where((r) {
                  final q = query.toLowerCase();
                  return r.name.toLowerCase().contains(q) ||
                         r.city.toLowerCase().contains(q) ||
                         r.capacity.toString().contains(q);
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off_rounded, size: 64, color: AppColors.outlineVariant),
                        const SizedBox(height: 16),
                        Text('Tidak ada ruangan yang cocok dengan "$query"', style: const TextStyle(color: AppColors.onSurfaceVariant)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    return RoomCard(room: filtered[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
