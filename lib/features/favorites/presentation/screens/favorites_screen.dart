import 'package:flutter/material.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../shared/presentation/widgets/role_aware_nav_bar.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'Favorites',
      bottomNavigationBar: RoleAwareNavBar(currentPath: AppRoutes.favorites),
      body: EmptyState(
        title: 'No favorite rooms yet',
        message: 'Favorites will sync with the user_favorites table.',
      ),
    );
  }
}
