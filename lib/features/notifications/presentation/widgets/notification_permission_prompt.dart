import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/providers/shared_prefs_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class NotificationPermissionPrompt extends ConsumerStatefulWidget {
  const NotificationPermissionPrompt({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<NotificationPermissionPrompt> createState() =>
      _NotificationPermissionPromptState();
}

class _NotificationPermissionPromptState
    extends ConsumerState<NotificationPermissionPrompt> {
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowPrompt());
  }

  @override
  void didUpdateWidget(covariant NotificationPermissionPrompt oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowPrompt());
  }

  Future<void> _maybeShowPrompt() async {
    if (!mounted || _isChecking) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final prefs = ref.read(sharedPreferencesProvider);
    final key = 'notification_permission_prompted_${user.id}';
    if (prefs.getBool(key) == true) return;

    _isChecking = true;
    await prefs.setBool(key, true);

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => const _NotificationPermissionSheet(),
    );

    _isChecking = false;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _NotificationPermissionSheet extends StatelessWidget {
  const _NotificationPermissionSheet();

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.notifications_active_outlined,
                color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            strings.tr(
              'Aktifkan notifikasi booking',
              'Enable booking notifications',
            ),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            strings.tr(
              'ClassRent dapat mengirim status pembayaran, konfirmasi booking, dan pembaruan penting tanpa perlu membuka aplikasi.',
              'ClassRent can send payment status, booking confirmations, and important updates without opening the app.',
            ),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  height: 1.45,
                ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(strings.tr('Nanti', 'Later')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () async {
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  child: Text(strings.tr('Aktifkan', 'Enable')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
