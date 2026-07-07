import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppBrandMark extends StatelessWidget {
  const AppBrandMark({
    this.size = 56,
    this.showWordmark = false,
    this.foregroundColor,
    this.backgroundColor,
    super.key,
  });

  final double size;
  final bool showWordmark;
  final Color? foregroundColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final mark = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.primary,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(size * 0.28),
            child: Image.asset(
              'assets/images/classrent_logo.png',
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.school_rounded,
                color:
                    (foregroundColor ?? Colors.white).withValues(alpha: 0.92),
                size: size * 0.54,
              ),
            ),
          ),
        ],
      ),
    );

    if (!showWordmark) return mark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        const SizedBox(width: 12),
        Text(
          'ClassRent',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: foregroundColor ?? AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }
}
