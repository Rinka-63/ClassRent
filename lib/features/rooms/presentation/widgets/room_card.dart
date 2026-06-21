import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/favorites_provider.dart';
import '../../domain/entities/room.dart';
import '../providers/rooms_providers.dart';

// Map dari tag ke icon
const _facilityIcons = <String, IconData>{
  'wifi': Icons.wifi,
  'ac': Icons.ac_unit,
  'projector': Icons.cast,
  'whiteboard': Icons.edit_note_outlined,
  'sound_system': Icons.speaker_outlined,
  'microphone': Icons.mic_outlined,
  'tv': Icons.smart_display_outlined,
  'parking': Icons.local_parking_outlined,
  'toilet': Icons.wc_outlined,
  'kitchen': Icons.kitchen_outlined,
  'camera': Icons.videocam_outlined,
  'printer': Icons.print_outlined,
};

class RoomCard extends ConsumerWidget {
  const RoomCard({required this.room, super.key});

  final Room room;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteState = ref.watch(favoritesProvider);
    final favoriteIds = favoriteState.valueOrNull ?? {};
    final facilitiesAsync = ref.watch(roomFacilitiesProvider(room.id));
    final money = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.outlineVariant),
      ),
      child: InkWell(
        onTap: () => context.push(AppRoutes.roomDetail.replaceFirst(':roomId', room.id)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar / placeholder
            Stack(
              children: [
                Container(
                  height: 130,
                  width: double.infinity,
                  color: AppColors.primaryContainer.withValues(alpha: 0.18),
                  alignment: Alignment.center,
                  child: room.previewUrl != null
                      ? Image.network(
                          room.previewUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 130,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.meeting_room_outlined,
                              size: 48,
                              color: AppColors.primary),
                        )
                      : const Icon(Icons.meeting_room_outlined,
                          size: 48, color: AppColors.primary),
                ),
                // Tombol favorit
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(999),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () => ref.read(favoritesProvider.notifier).toggleFavorite(room.id),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          favoriteIds.contains(room.id)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: favoriteIds.contains(room.id)
                              ? Colors.red
                              : AppColors.onSurfaceVariant,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nama room
                    Text(
                      room.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    // Lokasi + kapasitas
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 13, color: AppColors.onSurfaceVariant),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            '${room.city} • ${room.capacity} kursi',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Fasilitas icons
                    facilitiesAsync.when(
                      loading: () => const SizedBox(height: 20),
                      error: (_, __) => const SizedBox(height: 20),
                      data: (facilities) {
                        if (facilities.isEmpty) return const SizedBox(height: 20);
                        final display = facilities.take(3).toList();
                        final extra = facilities.length - display.length;
                        return Row(
                          children: [
                            ...display.map(
                              (tag) => Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Icon(
                                  _facilityIcons[tag] ?? Icons.check_circle_outline,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            if (extra > 0)
                              Text(
                                '+$extra',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                    ),
                              ),
                          ],
                        );
                      },
                    ),
                    const Spacer(),
                    // Rating + harga
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 15, color: Colors.amber),
                        const SizedBox(width: 3),
                        Text(
                          room.avgRating.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const Spacer(),
                        Flexible(
                          child: Text(
                            '${money.format(room.hourlyRate)}/jam',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
