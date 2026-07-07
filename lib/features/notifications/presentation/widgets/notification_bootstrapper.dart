import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/supabase/supabase_client_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/services/fcm_service.dart';

final fcmServiceProvider = Provider<FcmService?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  return FcmService(client);
});

class NotificationBootstrapper extends ConsumerStatefulWidget {
  const NotificationBootstrapper({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<NotificationBootstrapper> createState() =>
      _NotificationBootstrapperState();
}

class _NotificationBootstrapperState
    extends ConsumerState<NotificationBootstrapper> {
  String? _initializedUserId;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final service = ref.watch(fcmServiceProvider);
    if (user != null && service != null && _initializedUserId != user.id) {
      _initializedUserId = user.id;
      Future.microtask(() => service.initialize(userId: user.id));
    }
    if (user == null) {
      _initializedUserId = null;
    }
    return widget.child;
  }
}
