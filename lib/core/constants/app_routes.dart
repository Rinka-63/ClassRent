class AppRoutes {
  const AppRoutes._();

  static const splash = '/';
  static const login = '/login';
  static const home = '/home';
  static const search = '/search';
  static const favorites = '/favorites';
  static const bookings = '/bookings';
  static const bookingCreate = '/booking/create';
  static const payments = '/payments';
  static const paymentCheckout = '/payments/checkout/:bookingId';
  static const paymentDetail = '/payments/:paymentId';
  static const profile = '/profile';
  static const notifications = '/notifications';
  static const support = '/support';
  static const roomDetail = '/rooms/:roomId';
  static const admin = '/admin';
  static const adminPending = '/admin/pending';
  static const adminReports = '/admin/reports';
  static const adminHistory = '/admin/history';
  static const adminAuditDetail = '/admin/history/:auditId';
  static const adminCalendar = '/admin/calendar';
  static const superAdmin = '/super-admin';
  static const superAdminSettings = '/super-admin/settings';
  static const roomManagement = '/admin/rooms';
  static const bookingManagement = '/admin/bookings';
  static const paymentManagement = '/admin/payments';
  static const adminPaymentDetail = '/admin/payments/:paymentId';
  static const unauthorized = '/unauthorized';

  static String paymentCheckoutPath(String bookingId) {
    return '/payments/checkout/$bookingId';
  }

  static String paymentDetailPath(String paymentId) {
    return '/payments/$paymentId';
  }

  static String adminPaymentDetailPath(String paymentId) {
    return '/admin/payments/$paymentId';
  }
}
