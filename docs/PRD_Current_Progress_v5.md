# ClassRent PRD Progress Update v5

Dokumen ini dibuat untuk membantu tim memahami kondisi produk saat ini, alur yang sudah aktif, dan pekerjaan lanjutan yang masih perlu dikerjakan.

## 1. Ringkasan Produk

ClassRent adalah aplikasi penyewaan ruangan berbasis Flutter + Supabase dengan tiga role aktif:

- `super_admin`
- `admin`
- `user`

Alur utama produk saat ini:

1. `user` register dan login normal.
2. `admin` register sebagai agency admin.
3. Agency admin masuk ke status `pending`.
4. `super_admin` melihat agency baru dan melakukan approve / reject.
5. Setelah approved, `admin` bisa mengelola room milik agency-nya.
6. `user` tetap memakai aplikasi untuk mencari dan booking ruangan.

Role `staff` sudah dihapus dari runtime Flutter aktif.

## 2. Tujuan Dokumen Ini

PRD ini bukan blueprint awal, tetapi progress brief agar tim bisa:

- memahami alur produk yang benar
- tahu fitur mana yang sudah hidup
- tahu fitur mana yang masih skeleton / dummy
- melanjutkan jobdesk tanpa membangun ulang dari nol

## 3. Status Arsitektur Saat Ini

### Frontend

- Flutter
- Riverpod
- GoRouter
- UI mengikuti design system ClassRent yang sudah ada
- logout dipusatkan di halaman profile

### Backend

- Supabase Auth
- Supabase Postgres
- RLS sudah aktif untuk banyak tabel inti
- migration terbaru sudah dipisah untuk agency, room CRUD, booking access, dan schedule

### Role Model Aktif

- `super_admin`
  - approve / reject agency
  - aktif / nonaktif agency
  - akses lintas platform
- `admin`
  - mengelola agency miliknya
  - CRUD room
  - kelola fasilitas room
  - kelola jadwal room
  - kelola booking room
- `user`
  - register / login normal
  - mencari room
  - booking ruangan

## 4. Alur Produk yang Sudah Disepakati

### A. Alur Agency Admin

1. Admin register dari aplikasi.
2. Sistem membuat row `users` dengan role `admin`.
3. Sistem membuat row `agencies` dengan `approval_status = pending`.
4. Super admin melihat agency baru di dashboard.
5. Super admin approve agency.
6. Agency menjadi `approved` dan `is_active = true`.
7. Admin bisa login dan masuk ke dashboard agency.

### B. Alur User

1. User register.
2. User login.
3. User melihat daftar ruangan.
4. User buka detail room.
5. User mulai booking.

### C. Alur Super Admin

1. Super admin login manual.
2. Super admin melihat daftar agency pending.
3. Super admin approve / reject.
4. Super admin bisa memantau data platform.

### D. Alur Admin Agency

1. Admin login.
2. Dashboard menampilkan list room milik agency.
3. Admin masuk ke room management.
4. Admin edit detail room, fasilitas, dan jadwal.
5. Admin melihat booking per room.
6. Admin melihat history / audit logs.
7. Logout ada di halaman profile.

## 5. Progress Fitur Saat Ini

### Sudah Stabil

- Auth login / register / logout
- Session persistence
- Role-based redirect
- Super admin dashboard
- Agency approval flow
- Admin dashboard room list
- Room management screen
- Booking management screen
- History screen berbasis audit log
- Reports screen berbasis data room
- Room detail screen dengan tab:
  - Overview
  - Facilities
  - Schedule
  - Bookings
- Riverpod provider structure
- GoRouter role guard
- Supabase repository layer

### Sudah Tersambung ke Backend

- baca room dari Supabase
- create / update / soft delete room
- baca fasilitas room
- simpan fasilitas room
- baca jadwal room
- simpan jadwal room
- baca booking per agency
- baca booking per room
- approve / reject agency
- aktif / nonaktif agency

### Masih Skeleton / Perlu Dilanjutkan

- form fasilitas room yang lebih nyaman daripada input teks
- form jadwal room yang lebih user-friendly
- booking approval action yang lebih lengkap
- payment workflow penuh
- review moderation workflow
- support ticket workflow
- calendar visual yang lebih interaktif
- dashboard analytics yang lebih akurat berbasis booking nyata

## 6. Modul yang Sudah Ada

### Authentication

- register user
- register agency admin
- login
- logout
- session restore
- role redirect

### Profile

- profile card
- security card
- settings list
- logout button

### Rooms

- room list
- room detail
- room CRUD
- room facilities
- room schedules

### Booking

- booking list screen
- booking flow skeleton
- booking per room
- booking action placeholder / basic confirm-cancel

### Admin

- dashboard
- reports
- history
- room management
- booking management
- schedule page

### Super Admin

- agency list
- approval / rejection
- platform overview

## 7. Database Status

Database inti yang dipakai runtime sekarang:

- `users`
- `agencies`
- `facilities`
- `rooms`
- `room_facilities`
- `room_schedules`
- `bookings`
- `payments`
- `reviews`
- `notifications`
- `audit_logs`
- `support_tickets`
- `ticket_messages`

Catatan penting:

- `agencies` dipakai untuk approval agency.
- `facilities` bukan tabel agency.
- `rooms` adalah entitas utama yang dikelola admin agency.

## 8. Migration Status

Migration aktif yang sekarang relevan:

- `20260601120000_classrent_schema.sql`
- `20260601121000_classrent_rls.sql`
- `20260602103000_separate_agencies_from_facilities.sql`
- `20260602110000_remove_staff_role_and_cleanup.sql`
- `20260602112000_agency_room_booking_backend.sql`

Yang paling penting untuk deployment remote:

- migration terakhir harus di-push
- history migration Supabase harus selaras dengan folder lokal

## 9. Masalah / Risiko yang Masih Perlu Diperhatikan

### A. Setting manual Supabase

Beberapa hal tetap perlu dicek manual:

- migration harus benar-benar ter-apply
- RLS harus aktif
- super admin account harus ada
- agency admin lama harus punya row `agencies`

### B. UI data yang masih bisa dikembangkan

Beberapa layar masih memakai pendekatan sederhana agar stabil:

- fasilitas room masih edit berbasis teks comma-separated
- jadwal room masih edit berbasis format teks per baris
- booking action masih basic

### C. Kalender dan laporan

Saat ini kalender dan laporan sudah ada sebagai fondasi, tetapi belum menjadi analytics engine penuh.

## 10. Prioritas Pengerjaan Berikutnya

Urutan kerja yang paling aman:

1. rapikan form fasilitas room
2. rapikan form jadwal room
3. lengkapi action booking per room
4. tambahkan detail booking screen
5. sambungkan payment workflow
6. sambungkan review workflow
7. sambungkan support ticket workflow
8. upgrade dashboard analytics dari dummy summary ke data booking nyata

## 11. Jobdesk untuk Tim

### Frontend

- mempercantik editor room detail
- membuat form fasilitas room lebih friendly
- membuat editor jadwal room lebih proper
- menambah detail booking dan aksi admin

### Backend / Supabase

- memastikan migration terbaru sudah ter-apply
- memastikan policy RLS cocok dengan flow admin agency
- memvalidasi data agency pending / approved
- menyiapkan data awal untuk testing

### QA

- test register agency
- test approval agency
- test login admin setelah approval
- test CRUD room
- test edit fasilitas room
- test edit jadwal room
- test booking list per room

## 12. Acceptance Check Current Milestone

Dokumen ini dianggap sesuai bila:

- role `staff` tidak muncul di runtime aktif
- agency admin daftar masuk `pending`
- super admin bisa approve agency
- admin hanya melihat room milik agency-nya
- admin bisa CRUD room
- room detail bisa dipakai untuk fasilitas, jadwal, dan booking
- logout ada di profile
- `dart analyze` tetap bersih

## 13. Overall Progress Estimate

Estimasi progress saat ini:

- Foundation dan arsitektur: 90%
- Authentication dan routing: 90%
- Super admin approval flow: 85%
- Admin dashboard dan room management: 80%
- Room detail editor: 70%
- Booking flow backend: 55%
- Payments: 20%
- Reviews: 20%
- Support tickets: 20%

Overall project progress: sekitar **70-75%**

## 14. Catatan Penutup

Progress ini sudah cukup kuat untuk dikerjakan bersama tim. Titik lanjut paling aman adalah memperhalus editor room detail dan booking flow supaya backend yang sudah nyambung benar-benar dipakai penuh dari UI.

