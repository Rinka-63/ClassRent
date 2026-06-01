import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin/presentation/screens/booking_management_screen.dart';
import '../../features/admin/presentation/screens/room_management_screen.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/booking/presentation/screens/booking_flow_screen.dart';
import '../../features/booking/presentation/screens/bookings_screen.dart';
import '../../features/favorites/presentation/screens/favorites_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/payments/presentation/screens/payments_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/rooms/presentation/screens/room_detail_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import '../../features/support_tickets/presentation/screens/support_tickets_screen.dart';
import '../../shared/domain/entities/app_user.dart';
import '../constants/app_routes.dart';
import 'unauthorized_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final role = ref.watch(currentRoleProvider);
  final isAuthenticated = ref.watch(isAuthenticatedProvider);

  return GoRouter(
    initialLocation: AppRoutes.home,
    redirect: (context, state) {
      final path = state.uri.path;
      if (!isAuthenticated && path != AppRoutes.login) return AppRoutes.login;
      if (isAuthenticated && path == AppRoutes.login) return AppRoutes.home;
      if (path.startsWith('/admin') &&
          role != UserRole.admin &&
          role != UserRole.superAdmin) {
        return AppRoutes.unauthorized;
      }
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(path: AppRoutes.home, builder: (_, __) => const HomeScreen()),
      GoRoute(path: AppRoutes.search, builder: (_, __) => const SearchScreen()),
      GoRoute(
        path: AppRoutes.favorites,
        builder: (_, __) => const FavoritesScreen(),
      ),
      GoRoute(
        path: AppRoutes.bookings,
        builder: (_, __) => const BookingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.bookingCreate,
        builder: (_, __) => const BookingFlowScreen(),
      ),
      GoRoute(
        path: AppRoutes.payments,
        builder: (_, __) => const PaymentsScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (_, __) => const NotificationsScreen(),
      ),
      GoRoute(path: AppRoutes.profile, builder: (_, __) => const ProfileScreen()),
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
