import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class AppStrings {
  const AppStrings(this.locale);

  final Locale locale;

  static AppStrings of(BuildContext context) {
    final strings = Localizations.of<AppStrings>(context, AppStrings);
    if (strings != null) return strings;
    return const AppStrings(Locale('id'));
  }

  static const LocalizationsDelegate<AppStrings> delegate =
      _AppStringsDelegate();

  String _t(String id, String en) =>
      locale.languageCode.toLowerCase() == 'en' ? en : id;

  String tr(String id, String en) => _t(id, en);

  String get home => _t('Beranda', 'Home');
  String get rooms => _t('Ruangan', 'Rooms');
  String get bookings => _t('Pesanan', 'Bookings');
  String get profile => _t('Profil', 'Profile');
  String get users => _t('Pengguna', 'Users');
  String get payments => _t('Pembayaran', 'Payments');
  String get menu => _t('Menu', 'Menu');
  String get welcome => _t('Selamat datang,', 'Welcome,');
  String get agency => _t('Agensi', 'Agencies');
  String get history => _t('Riwayat', 'History');
  String get allRooms => _t('Semua Ruangan', 'All Rooms');
  String get roomDetail => _t('Detail Ruangan', 'Room Detail');
  String get searchRoomsHint =>
      _t('Cari nama ruangan, kota, atau kapasitas...', 'Search rooms...');
  String get searchAgencyHint => _t('Cari agency...', 'Search agencies...');
  String get searchUsersHint => _t('Cari user...', 'Search users...');
  String get searchActivitiesHint =>
      _t('Cari aktivitas, user, entity...', 'Search activities...');
  String get sortBy => _t('Urutkan', 'Sort');
  String get filter => _t('Filter', 'Filter');
  String get all => _t('Semua', 'All');
  String get newest => _t('Terbaru', 'Newest');
  String get oldest => _t('Terlama', 'Oldest');
  String get nameAsc => _t('Nama A-Z', 'Name A-Z');
  String get nameDesc => _t('Nama Z-A', 'Name Z-A');
  String get resetFilter => _t('Reset Filter', 'Reset Filters');
  String get roomNotFound => _t('Ruangan tidak ditemukan', 'Room not found');
  String get noRoomsMatch => _t('Belum ada ruangan yang cocok dengan filter.',
      'No rooms match the current filters.');
  String get tips => _t('Tips ClassRent', 'ClassRent Tips');
  String get recommendation => _t('Rekomendasi Ruangan', 'Room Picks');
  String get seeAll => _t('Lihat Semua', 'See All');
  String get bookingUpcoming => _t('Booking Mendatang', 'Upcoming Booking');
  String get roomSchedule => _t('Jadwal Room', 'Room Schedule');
  String get roomImages => _t('Foto Detail Ruangan', 'Room Photos');
  String get detailChanges => _t('Detail Perubahan', 'Change Details');
  String get bookingHistory => _t('Riwayat Booking', 'Booking History');
  String get agencyLabel => _t('Agency', 'Agency');
  String get capacity => _t('Kapasitas', 'Capacity');
  String get type => _t('Tipe', 'Type');
  String get city => _t('Kota', 'City');
  String get address => _t('Alamat', 'Address');
  String get price => _t('Harga', 'Price');
  String get status => _t('Status', 'Status');
  String get facilities => _t('Fasilitas', 'Facilities');
  String get available => _t('Tersedia', 'Available');
  String get full => _t('Penuh', 'Full');
  String get filterSort => _t('Filter & Urutkan', 'Filter & Sort');
  String get pricePerHour => _t('Harga (Rp/jam)', 'Price (IDR/hour)');
  String get min => _t('Min', 'Min');
  String get max => _t('Max', 'Max');
  String get minimumCapacity => _t('Kapasitas minimum', 'Minimum capacity');
  String get buildingOrCity => _t('Gedung / Kota', 'Building / City');
  String get floor => _t('Lantai', 'Floor');
  String get allStatuses => _t('Semua', 'All');
  String get reset => _t('Reset', 'Reset');
  String get apply => _t('Terapkan', 'Apply');
  String get settings => _t('Pengaturan', 'Settings');
  String get logout => _t('Keluar', 'Logout');
  String get languageTheme => _t('Bahasa & Tema', 'Language & Theme');
  String get language => _t('Bahasa', 'Language');
  String get appLanguage => _t('Bahasa aplikasi', 'App language');
  String get chooseLanguage => _t('Pilih Bahasa', 'Choose Language');
  String get chooseLanguageSubtitle =>
      _t('Pilih bahasa yang ingin digunakan di aplikasi.',
          'Choose the language you want to use in the app.');
  String get continueLabel => _t('Lanjut', 'Continue');
  String get skip => _t('Lewati', 'Skip');
  String get indonesian => _t('Bahasa Indonesia', 'Indonesian');
  String get english => _t('Bahasa Inggris', 'English');
  String get generalSettings => _t('Pengaturan Umum', 'General Settings');
  String get adminTools => _t('Alat Admin', 'Admin Tools');
  String get account => _t('Akun', 'Account');
  String get editProfile => _t('Edit Profil', 'Edit Profile');
  String get savedRooms => _t('Ruangan Tersimpan', 'Saved Rooms');
  String get notifications => _t('Notifikasi', 'Notifications');
  String get help => _t('Bantuan', 'Help');
  String get about => _t('Tentang', 'About');
  String get aboutClassRent =>
      _t('Tentang ClassRent', 'About ClassRent');
  String get privacyPolicy => _t('Kebijakan Privasi', 'Privacy Policy');
  String get termsAndConditions =>
      _t('Syarat & Ketentuan', 'Terms & Conditions');
  String get closeLabel => _t('Tutup', 'Close');
  String get appVersion => _t('ClassRent v0.1.0', 'ClassRent v0.1.0');
  String get generalProfileDescription =>
      _t('Kelola bahasa, profil, dan preferensi akun.', 'Manage language, profile, and account preferences.');
  String get profileEdit => _t('Edit Profil', 'Edit Profile');
  String get profileName => _t('Nama', 'Name');
  String get profilePhone => _t('Nomor HP', 'Phone Number');
  String get emptyNameError =>
      _t('Nama tidak boleh kosong.', 'Name cannot be empty.');
  String get profileUpdated =>
      _t('Profil berhasil diperbarui.', 'Profile updated successfully.');
  String get profileUpdateFailed =>
      _t('Gagal memperbarui profil.', 'Failed to update profile.');
  String get userLabel => _t('Pengguna', 'User');
  String get classRentUser => _t('Pengguna ClassRent', 'ClassRent User');
  String get emailPlaceholder => _t('email@placeholder.com', 'email@placeholder.com');
  String get superAdminLabel => _t('Super Admin', 'Super Admin');
  String get adminAgencyLabel => _t('Admin Agensi', 'Agency Admin');
  String get onboardingRoomsTitle => _t('Cari Ruangan', 'Find Rooms');
  String get onboardingRoomsDescription => _t(
      'Temukan ruangan kelas dan meeting yang sesuai dengan kebutuhan Anda.',
      'Find classrooms and meeting rooms that fit your needs.');
  String get onboardingBookingTitle => _t('Booking Mudah', 'Easy Booking');
  String get onboardingBookingDescription => _t(
      'Pilih tanggal, waktu, dan selesaikan booking dalam hitungan menit.',
      'Choose a date, time, and finish booking in minutes.');
  String get onboardingPaymentTitle => _t('Bayar Aman', 'Secure Payment');
  String get onboardingPaymentDescription => _t(
      'Pembayaran online terintegrasi dengan Midtrans, aman dan terpercaya.',
      'Online payments are integrated with Midtrans, safe and reliable.');
  String get start => _t('Mulai', 'Get Started');
  String get system => _t('Sistem', 'System');
  String get light => _t('Terang', 'Light');
  String get dark => _t('Gelap', 'Dark');
  String get save => _t('Simpan', 'Save');
  String get cancel => _t('Batal', 'Cancel');
  String get delete => _t('Hapus', 'Delete');
  String get edit => _t('Edit', 'Edit');
  String get confirm => _t('Konfirmasi', 'Confirm');
  String get close => _t('Tutup', 'Close');
  String get target => _t('Target', 'Target');
  String get actor => _t('Pelaku', 'Actor');
  String get role => _t('Role', 'Role');
  String get time => _t('Waktu', 'Time');
  String get details => _t('Detail', 'Details');
  String get adminPanel => _t('ClassRent Admin Panel', 'ClassRent Admin Panel');
  String get superAdminPanel =>
      _t('ClassRent Super Admin Panel', 'ClassRent Super Admin Panel');
}

class _AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const _AppStringsDelegate();

  @override
  bool isSupported(Locale locale) {
    final code = locale.languageCode.toLowerCase();
    return code == 'id' || code == 'en';
  }

  @override
  Future<AppStrings> load(Locale locale) {
    return SynchronousFuture<AppStrings>(AppStrings(locale));
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppStrings> old) => false;
}
