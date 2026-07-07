import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/status_badge.dart';
import '../providers/favorites_provider.dart';
import '../../domain/entities/room.dart';

class RoomCard extends ConsumerWidget {
  const RoomCard({
    required this.room,
    this.showFavorite = true,
    this.trailing,
    super.key,
  });

  final Room room;
  final bool showFavorite;
  final Widget? trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final favoriteState = ref.watch(favoritesProvider);
    final favoriteIds = favoriteState.valueOrNull ?? {};
    final money =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    final isAvailable = room.isActive;
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      color: colorScheme.surface,
      child: InkWell(
        onTap: () =>
            context.push(AppRoutes.roomDetail.replaceFirst(':roomId', room.id)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 132,
                  width: double.infinity,
                  color: colorScheme.primaryContainer.withValues(alpha: 0.18),
                  alignment: Alignment.center,
                  child: room.previewUrl != null && room.previewUrl!.isNotEmpty
                      ? Image.network(
                          room.previewUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 132,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.meeting_room_outlined,
                            size: 48,
                            color: AppColors.primary,
                          ),
                        )
                      : const Icon(
                          Icons.meeting_room_outlined,
                          size: 48,
                          color: AppColors.primary,
                        ),
                ),
                if (room.avgRating > 0)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.surface.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 14, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            room.avgRating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: AppColors.onSurface,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (showFavorite)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Material(
                      color: colorScheme.surface.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(999),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: () => ref
                            .read(favoritesProvider.notifier)
                            .toggleFavorite(room.id),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            favoriteIds.contains(room.id)
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: favoriteIds.contains(room.id)
                                ? AppColors.error
                                : AppColors.onSurfaceVariant,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (trailing != null)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: trailing!,
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 14, color: AppColors.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            room.city,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        if (isAvailable)
                          const StatusBadge.available()
                        else
                          const StatusBadge.full(),
                        if (room.avgRating >= 4) const StatusBadge.verified(),
                      ],
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          money.format(room.hourlyRate),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '/ jam • ${room.capacity} kursi',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
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
