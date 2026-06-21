class AppRoutes {
  const AppRoutes._();

  static const splash = '/';
  static const onboarding = '/onboarding';
  static const welcomeAuth = '/welcome-auth';
  static const login = '/login';
  static const home = '/home';
  static const search = '/search';
  static const favorites = '/favorites';
  static const bookings = '/bookings';
  static const bookingCreate = '/booking/create/:roomId';
  static const paymentMethod = '/payments/method/:bookingId';
  static const paymentWebView = '/payments/webview/:bookingId';
  static const payments = '/payments';
  static const promos = '/promos';
  static const profile = '/profile';
  static const agencyProfile = '/agency-profile';
  static const notifications = '/notifications';
  static const support = '/support';
  static const roomDetail = '/rooms/:roomId';
  static const admin = '/admin';
  static const adminPending = '/admin/pending';
  static const adminReports = '/admin/reports';
  static const adminHistory = '/admin/history';
  static const adminCalendar = '/admin/calendar';
  static const adminScanner = '/admin/scanner';
  static const adminCoupons = '/admin/coupons';
  static const superAdmin = '/super-admin';
  static const superAdminSettings = '/super-admin/settings';
  static const roomManagement = '/admin/rooms';
  static const bookingManagement = '/admin/bookings';
  static const unauthorized = '/unauthorized';
}
