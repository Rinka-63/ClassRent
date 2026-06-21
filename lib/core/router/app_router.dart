import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin/presentation/screens/admin_pending_approval_screen.dart';
import '../../features/admin/presentation/screens/admin_history_screen.dart';
import '../../features/admin/presentation/screens/admin_calendar_screen.dart';
import '../../features/admin/presentation/screens/qr_scanner_screen.dart' as qr_scanner;
import '../../features/admin/presentation/screens/coupon_management_screen.dart';
import '../../features/admin/presentation/screens/booking_management_screen.dart';
import '../../features/admin/presentation/screens/admin_reports_screen.dart';
import '../../features/admin/presentation/screens/room_management_screen.dart';
import '../../features/admin/presentation/screens/super_admin/super_admin_settings_screen.dart';
import '../../features/admin/presentation/screens/super_admin/super_admin_shell_screen.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/welcome_auth_screen.dart';
import '../../features/booking/presentation/screens/booking_detail_screen.dart';
import '../../features/booking/presentation/screens/booking_flow_screen.dart';
import '../../features/booking/presentation/screens/bookings_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/home/presentation/screens/promo_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/payments/presentation/screens/payments_screen.dart';
import '../../features/payments/presentation/screens/payment_method_screen.dart';
import '../../features/payments/presentation/screens/midtrans_webview_screen.dart';
import '../../features/profile/presentation/screens/agency_profile_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/rooms/presentation/screens/favorites_screen.dart';
import '../../features/rooms/presentation/screens/room_detail_screen.dart';
import '../../features/support_tickets/presentation/screens/support_tickets_screen.dart';
import '../../shared/domain/entities/app_user.dart';
import '../constants/app_routes.dart';
import '../providers/shared_prefs_provider.dart';
import 'unauthorized_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final role = ref.watch(currentRoleProvider);
  final user = ref.watch(currentUserProvider);
  final isAuthenticated = ref.watch(isAuthenticatedProvider);
  final isAuthLoading = ref.watch(isAuthLoadingProvider);
  final hasSeenOnboarding = ref.watch(hasSeenOnboardingProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final path = state.uri.path;
      if (isAuthLoading) return path == AppRoutes.splash ? null : AppRoutes.splash;
      
      if (!isAuthenticated) {
        if (!hasSeenOnboarding && path != AppRoutes.onboarding) {
          return AppRoutes.onboarding;
        }
        if (hasSeenOnboarding && 
            path != AppRoutes.welcomeAuth && 
            path != AppRoutes.login && 
            path != AppRoutes.onboarding) {
          return AppRoutes.welcomeAuth;
        }
        return null;
      }

      if (isAuthenticated && 
          (path == AppRoutes.login || 
           path == AppRoutes.splash || 
           path == AppRoutes.welcomeAuth || 
           path == AppRoutes.onboarding)) {
        return _landingPathFor(user);
      }

      if (role == UserRole.admin &&
          user?.hasApprovedAgency == false &&
          path != AppRoutes.adminPending) {
        return AppRoutes.adminPending;
      }
      if (path == AppRoutes.adminPending &&
          (role != UserRole.admin || user?.hasApprovedAgency == true)) {
        return _landingPathFor(user);
      }
      if (path.startsWith('/admin') &&
          role != UserRole.admin &&
          role != UserRole.superAdmin) {
        return AppRoutes.unauthorized;
      }
      if (path.startsWith('/super-admin') && role != UserRole.superAdmin) {
        return AppRoutes.unauthorized;
      }
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(path: AppRoutes.onboarding, builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: AppRoutes.welcomeAuth, builder: (_, __) => const WelcomeAuthScreen()),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final isRegister = extra?['isRegister'] as bool? ?? false;
          return LoginScreen(isRegister: isRegister);
        },
      ),
      GoRoute(path: AppRoutes.home, builder: (_, __) => const HomeScreen()),
      GoRoute(
        path: AppRoutes.promos,
        builder: (_, __) => const PromoScreen(),
      ),
      GoRoute(
        path: AppRoutes.favorites,
        builder: (context, state) => const FavoritesScreen(),
      ),
      GoRoute(
        path: AppRoutes.bookings,
        builder: (_, __) => const BookingsScreen(),
      ),
      GoRoute(
        path: '/bookings/:bookingId',
        builder: (context, state) => BookingDetailScreen(
          bookingId: state.pathParameters['bookingId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.bookingCreate,
        builder: (_, state) => BookingFlowScreen(
          roomId: state.pathParameters['roomId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.payments,
        builder: (_, __) => const PaymentsScreen(),
      ),
      GoRoute(
        path: AppRoutes.paymentMethod,
        builder: (_, state) => PaymentMethodScreen(
          bookingId: state.pathParameters['bookingId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.paymentWebView,
        builder: (_, state) => MidtransWebViewScreen(
          paymentUrl: state.extra as String,
          bookingId: state.pathParameters['bookingId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (_, __) => const NotificationsScreen(),
      ),
      GoRoute(path: AppRoutes.profile, builder: (_, __) => const ProfileScreen()),
      GoRoute(
        path: AppRoutes.agencyProfile,
        builder: (_, __) => const AgencyProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.support,
        builder: (_, __) => const SupportTicketsScreen(),
      ),
      GoRoute(
        path: AppRoutes.roomDetail,
        builder: (_, state) => RoomDetailScreen(
          roomId: state.pathParameters['roomId']!,
        ),
      ),
      GoRoute(path: AppRoutes.admin, builder: (_, __) => const AdminDashboardScreen()),
      GoRoute(
        path: AppRoutes.adminReports,
        builder: (_, __) => const AdminReportsScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminHistory,
        builder: (_, __) => const AdminHistoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminCalendar,
        builder: (_, __) => const AdminCalendarScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminScanner,
        builder: (_, __) => const qr_scanner.AdminScannerScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminCoupons,
        builder: (_, __) => const CouponManagementScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminPending,
        builder: (_, __) => const AdminPendingApprovalScreen(),
      ),
      GoRoute(
        path: AppRoutes.superAdmin,
        builder: (_, __) => const SuperAdminShellScreen(),
        routes: [
          GoRoute(
            path: 'settings',
            builder: (_, __) => const SuperAdminSettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.roomManagement,
        builder: (_, __) => const RoomManagementScreen(),
      ),
      GoRoute(
        path: AppRoutes.bookingManagement,
        builder: (_, __) => const BookingManagementScreen(),
      ),
      GoRoute(
        path: AppRoutes.unauthorized,
        builder: (_, __) => const UnauthorizedScreen(),
      ),
    ],
  );
});

String _landingPathFor(AppUser? user) {
  return switch (user?.role ?? UserRole.user) {
    UserRole.admin =>
      user?.hasApprovedAgency == true ? AppRoutes.admin : AppRoutes.adminPending,
    UserRole.superAdmin => AppRoutes.superAdmin,
    UserRole.user => AppRoutes.home,
  };
}
