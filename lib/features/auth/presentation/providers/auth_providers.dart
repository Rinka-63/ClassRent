import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/domain/entities/app_user.dart';

final currentUserProvider = StateProvider<AppUser?>((ref) => null);

final currentRoleProvider = Provider<UserRole>((ref) {
  return ref.watch(currentUserProvider)?.role ?? UserRole.user;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});
