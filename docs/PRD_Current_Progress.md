# Product Requirements Document

## Product

ClassRent adalah aplikasi booking ruang kelas, ruang meeting, dan fasilitas belajar berbasis Flutter + Supabase. Aplikasi mendukung penyewa umum, staff operasional agency, admin agency, dan super admin platform.

## Current Product Status

Status saat ini: foundation MVP sedang berjalan.

Project sudah memiliki struktur Flutter, routing, autentikasi, role guard, koneksi Supabase, sebagian modul user, serta modul super admin awal untuk approval agency. Beberapa modul masih berupa skeleton UI dan belum memiliki business logic penuh.

## Problem Statement

Pengguna membutuhkan aplikasi untuk mencari, melihat detail, dan melakukan booking ruangan. Pemilik/agency membutuhkan dashboard untuk mengelola ruangan, booking, staff, dan operasional. Super admin membutuhkan kontrol platform untuk memverifikasi agency baru sebelum agency bisa beroperasi.

## Goals

- Menyediakan aplikasi booking ruangan yang mudah digunakan oleh user.
- Memisahkan hak akses berdasarkan role: user, staff, admin, super_admin.
- Memastikan agency baru tidak dapat beroperasi sebelum disetujui super admin.
- Menjaga database Supabase tetap aman dengan RLS dan relasi role yang jelas.
- Menyediakan fondasi Clean Architecture yang mudah dikembangkan untuk tugas Semester 4.

## Non Goals

- Belum menargetkan production-grade marketplace penuh.
- Belum menargetkan integrasi payment gateway nyata secara lengkap.
- Belum menargetkan fitur analytics lanjutan.
- Belum menargetkan sistem chat/support real-time penuh.

## User Roles

### User

User adalah penyewa biasa.

Kemampuan yang ditargetkan:

- Register dan login normal.
- Melihat daftar ruangan.
- Melihat detail ruangan.
- Melakukan pencarian.
- Menyimpan favorit.
- Membuat booking.
- Melihat status booking.
- Melakukan pembayaran.
- Memberi review.
- Membuat support ticket.

Progress saat ini:

- Register/login tersedia.
- Home, search, favorites, booking, payments, profile, notifications, support ticket screen sudah tersedia sebagai route/screen.
- Data rooms sudah mulai terhubung ke Supabase.
- Favorites masih state lokal.
- Booking/payment/review/support belum business logic penuh.

### Agency Admin

Agency Admin adalah pemilik atau pengelola agency.

Kemampuan yang ditargetkan:

- Register melalui aplikasi.
- Setelah register, role menjadi `admin`.
- Agency otomatis dibuat di tabel `agencies`.
- Status agency awal adalah `pending`.
- Tidak dapat masuk dashboard operasional sebelum disetujui super admin.
- Setelah approved dan active, dapat mengakses dashboard admin.
- Dapat membuat staff.
- Dapat mengelola ruangan dan booking agency.

Progress saat ini:

- Register agency tersedia di UI login/register.
- RPC `register_agency_admin_profile` sudah disiapkan melalui migration.
- Tabel `agencies` sudah disiapkan terpisah dari `facilities`.
- Admin pending approval screen sudah tersedia.
- Route guard sudah mengarahkan admin pending ke `/admin/pending`.
- Dashboard admin tersedia sebagai menu awal.
- Create staff screen tersedia.
- Create staff memakai Edge Function `create-staff`, tetapi function harus di-serve/deploy di Supabase agar tidak 404.
- Room management dan booking management masih skeleton.

### Staff

Staff adalah pegawai agency.

Kemampuan yang ditargetkan:

- Tidak bisa register sendiri.
- Dibuat oleh Agency Admin.
- Login menggunakan email/password yang dibuat admin.
- Terhubung ke agency melalui `agency_staff`.
- Hanya dapat mengakses data agency tempat bekerja.

Progress saat ini:

- Role staff sudah ada di entity dan router.
- Staff dashboard screen sudah tersedia.
- Edge Function create staff sudah disiapkan.
- Relasi staff ke agency menggunakan tabel `agency_staff`.
- Business logic operasional staff belum lengkap.

### Super Admin

Super Admin adalah pemilik platform.

Kemampuan yang ditargetkan:

- Tidak register dari aplikasi.
- Akun dibuat manual oleh developer.
- Melihat seluruh agency.
- Approve/reject agency baru.
- Mengaktifkan/menonaktifkan agency.
- Melihat data platform.
- Memiliki akses penuh ke data.

Progress saat ini:

- Role `super_admin` sudah tersedia.
- Route `/super-admin` sudah tersedia.
- Super Admin Dashboard sudah memiliki tab overview, agencies, dan users.
- Tombol logout sudah tersedia.
- Data agency dibaca dari tabel `agencies`.
- Approve/reject/toggle active agency sudah diarahkan ke tabel `agencies`.
- Platform stats sudah tersedia secara awal.

## Current Architecture

Tech stack:

- Flutter
- Riverpod
- GoRouter
- Supabase
- Clean Architecture style

Layer saat ini:

- `core`: config, routing, theme, error, Supabase service, shared widgets.
- `shared`: entity user dan role-aware navigation.
- `features`: auth, rooms, home, search, favorites, booking, payments, profile, notifications, support tickets, admin, staff.
- `supabase`: migrations, config, seed, Edge Function.

## Routing Requirements

Routing menggunakan GoRouter.

Current route:

- `/` splash
- `/login`
- `/home`
- `/search`
- `/favorites`
- `/bookings`
- `/booking/create`
- `/payments`
- `/profile`
- `/notifications`
- `/support`
- `/rooms/:roomId`
- `/admin`
- `/admin/pending`
- `/admin/staff/create`
- `/admin/rooms`
- `/admin/bookings`
- `/staff`
- `/super-admin`
- `/unauthorized`

Current redirect logic:

- Guest diarahkan ke login.
- User diarahkan ke home.
- Staff diarahkan ke staff dashboard.
- Admin pending diarahkan ke admin pending screen.
- Admin approved diarahkan ke admin dashboard.
- Super admin diarahkan ke super admin dashboard.
- Akses role yang salah diarahkan ke unauthorized.

## Database Requirements

Database utama mengikuti Supabase schema yang sudah ada.

Agency approval harus memakai tabel `agencies`, bukan `facilities`.

Tabel penting:

- `users`
- `agencies`
- `agency_staff`
- `facilities`
- `rooms`
- `room_images`
- `room_facilities`
- `bookings`
- `payments`
- `reviews`
- `notifications`
- `user_favorites`
- `support_tickets`
- `ticket_messages`

Catatan:

- `facilities` tetap digunakan untuk fasilitas/lokasi/ruangan sesuai domain ruangan.
- `agencies` digunakan untuk data agency dan approval.
- `agency_staff` digunakan untuk relasi staff ke agency.

## Authentication Requirements

Current requirement:

- Supabase Auth email/password.
- Session persistence.
- Role dibaca dari tabel `users`.
- Agency status dibaca dari tabel `agencies`.
- Staff agency dibaca dari `agency_staff`.
- Redirect berdasarkan role.

Progress saat ini:

- Login tersedia.
- Register user tersedia.
- Register agency tersedia.
- Logout tersedia.
- Session restore tersedia.
- Role guard tersedia.
- Perlu memastikan migration Supabase sudah diterapkan di database aktif.

## Super Admin Requirements

Functional requirements:

- Melihat total agencies, pending agencies, active agencies, users, rooms, bookings.
- Melihat daftar pending agencies.
- Approve agency.
- Reject agency.
- Toggle agency active/inactive.
- Melihat daftar platform users.

Progress:

- Implemented sebagian besar.
- Perlu QA setelah migration diterapkan di Supabase.

## Agency Admin Requirements

Functional requirements:

- Register agency.
- Menunggu approval.
- Setelah approved, akses dashboard admin.
- Create staff.
- Kelola rooms.
- Kelola bookings.
- Kelola support tickets.

Progress:

- Register agency dan pending flow tersedia.
- Create staff UI dan Edge Function tersedia.
- Room management dan booking management masih placeholder/skeleton.

## User Module Requirements

Functional requirements:

- Browse rooms.
- Room detail.
- Search rooms.
- Favorites.
- Booking flow.
- Payments.
- Reviews.
- Notifications.
- Support tickets.

Progress:

- Browse rooms dan room detail sudah mulai terhubung Supabase.
- Screen lain sudah tersedia sebagai foundation.
- Business logic lanjutan belum penuh.

## Staff Module Requirements

Functional requirements:

- Dashboard staff.
- Melihat booking agency.
- Membantu update status booking.
- Support ticket handling.

Progress:

- Staff dashboard route sudah tersedia.
- Business logic belum penuh.

## Edge Function Requirements

Current function:

- `create-staff`

Behavior:

- Dipanggil oleh Agency Admin.
- Validasi session caller.
- Validasi agency milik caller, approved, dan active.
- Membuat Supabase Auth user untuk staff.
- Membuat profile di `users`.
- Membuat relasi di `agency_staff`.

Progress:

- File function sudah ada.
- Perlu deploy/serve di Supabase runtime.

## UI Requirements

Theme current:

- Material UI.
- Warna utama biru ClassRent.
- Shared scaffold dan role-aware navigation.
- Super admin dashboard sudah disesuaikan dengan kebutuhan approval.

Progress:

- UI existing dipertahankan.
- Beberapa screen masih placeholder.
- Perlu polish untuk admin/staff operational screens.

## Security Requirements

Current security target:

- RLS aktif untuk tabel utama.
- Super admin punya akses penuh.
- Agency Admin hanya bisa akses agency miliknya setelah approved dan active.
- Staff hanya bisa akses agency tempat bekerja.
- Public/user hanya akses data yang relevan.

Progress:

- Migration RLS sudah disiapkan.
- Perlu diterapkan dan diuji langsung di Supabase aktif.

## Known Issues

- Edge Function `create-staff` akan error 404 jika belum di-serve/deploy.
- Migration baru harus dijalankan agar `agencies`, `agency_staff`, dan RPC baru tersedia.
- Beberapa screen masih belum memiliki repository/business logic.
- Payment belum integrasi payment gateway nyata.
- Booking flow masih foundation, belum transaksi penuh.

## MVP Completion Estimate

Progress kasar saat ini:

- Project foundation: 90%
- Authentication and role routing: 80%
- Super admin approval module: 75%
- Agency admin module: 40%
- Staff module: 25%
- User room browsing/detail: 50%
- Booking module: 25%
- Payment module: 15%
- Reviews: 10%
- Notifications: 10%
- Support tickets: 15%
- RLS/database role architecture: 70%

Overall MVP progress: sekitar 50-60%.

## Next Priority

1. Apply Supabase migrations ke database aktif.
2. Deploy/serve Edge Function `create-staff`.
3. Test full agency flow: register agency, pending, super admin approve, admin login, create staff.
4. Implement room management CRUD.
5. Implement booking management.
6. Implement booking flow user.
7. Implement payments.
8. Implement support tickets.
9. Add tests for auth redirect and role guard.

## Acceptance Criteria For Current Milestone

- User bisa register dan login.
- Agency admin bisa register dan muncul di Super Admin Dashboard sebagai pending agency.
- Super admin bisa approve/reject agency.
- Agency admin yang belum approved diarahkan ke pending page.
- Agency admin yang approved bisa masuk admin dashboard.
- Agency admin bisa membuat staff setelah Edge Function aktif.
- Staff bisa login dan hanya terhubung ke agency yang membuatnya.
- App compile tanpa analyzer error.

