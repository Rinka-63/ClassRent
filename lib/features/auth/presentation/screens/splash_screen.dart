import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/providers/app_update_provider.dart';
import '../../../../core/providers/shared_prefs_provider.dart';
import '../../../../shared/domain/entities/app_user.dart';
import '../providers/auth_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_brand_mark.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
    _animation = Tween<double>(begin: 0.94, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _decideNextRoute());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _decideNextRoute() async {
    if (!mounted) return;
    if (ref.read(isAuthLoadingProvider)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _decideNextRoute());
      return;
    }

    final updateStatus = await ref.read(appUpdateStatusProvider.future);
    if (!mounted) return;
    if (updateStatus.requiresUpdate) {
      context.go(AppRoutes.updateRequired);
      return;
    }

    final hasSeenLanguage = ref.read(hasSeenLanguageSelectionProvider);
    final isAuthenticated = ref.read(isAuthenticatedProvider);
    final user = ref.read(currentUserProvider);

    if (!hasSeenLanguage) {
      context.go(AppRoutes.languageSelection);
      return;
    }

    if (!isAuthenticated) {
      context.go(AppRoutes.onboarding);
      return;
    }

    context.go(_landingPathFor(user));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary, AppColors.primaryDeep],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _animation,
            child: ScaleTransition(
              scale: _animation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const AppBrandMark(size: 96),
                  const SizedBox(height: 28),
                  Text(
                    'ClassRent',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.onPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sewa Ruang Kelas & Meeting, Mudah dan Terpercaya',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.onPrimary.withValues(alpha: 0.9),
                        ),
                  ),
                  const SizedBox(height: 44),
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.onPrimary,
                      backgroundColor:
                          AppColors.onPrimary.withValues(alpha: 0.25),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'MEMUAT',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.onPrimary.withValues(alpha: 0.65),
                          letterSpacing: 1.6,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _landingPathFor(AppUser? user) {
  return switch (user?.role ?? UserRole.user) {
    UserRole.admin => user?.hasApprovedAgency == true
        ? AppRoutes.admin
        : AppRoutes.adminPending,
    UserRole.superAdmin => AppRoutes.superAdmin,
    UserRole.user => AppRoutes.home,
  };
}
