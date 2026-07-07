import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum RoomAvailabilityBadge {
  available,
  full,
  instant,
  verified,
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    this.icon,
    super.key,
  });

  const StatusBadge.available({super.key})
      : label = 'Tersedia',
        backgroundColor = AppColors.successContainer,
        foregroundColor = AppColors.success,
        icon = Icons.check_circle_outline;

  const StatusBadge.full({super.key})
      : label = 'Penuh',
        backgroundColor = AppColors.errorContainer,
        foregroundColor = AppColors.error,
        icon = Icons.block_outlined;

  const StatusBadge.instant({super.key})
      : label = 'Instant',
        backgroundColor = AppColors.infoContainer,
        foregroundColor = AppColors.info,
        icon = Icons.flash_on_outlined;

  const StatusBadge.verified({super.key})
      : label = 'Terverifikasi',
        backgroundColor = AppColors.primaryContainer,
        foregroundColor = AppColors.primary,
        icon = Icons.verified_outlined;

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: foregroundColor),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foregroundColor,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
