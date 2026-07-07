import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';

class ErrorCard extends StatelessWidget {
  const ErrorCard({
    required this.message,
    this.onRetry,
    this.title,
    super.key,
  });

  final String message;
  final VoidCallback? onRetry;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title ?? strings.tr('Terjadi kesalahan', 'Something went wrong'),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(strings.tr('Coba lagi', 'Try Again')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
