# PROGRESS UAS – ClassRent

## 1. Identitas Proyek

- Nama aplikasi: ClassRent
- Teknologi:
  - Flutter
  - Riverpod
  - GoRouter
  - Supabase
  - Midtrans (in progress)

## 2. Ringkasan Sistem

ClassRent adalah aplikasi penyewaan ruang kelas, ruang meeting, studio, dan ruang belajar yang menghubungkan user sebagai penyewa dengan admin sebagai pengelola ruangan. Berdasarkan kondisi repository saat ini, sistem sudah memiliki pondasi aplikasi Flutter, autentikasi Supabase, role-based routing, modul admin, modul ruangan, modul booking, modul payment, serta persiapan integrasi Midtrans melalui Supabase Edge Function.

Sistem sudah mendukung tiga role utama:

- `super_admin`
  - Masuk ke dashboard super admin.
  - Mengelola approval agency.
  - Melihat audit log dan laporan platform.
  - Mengakses area `/super-admin`.

- `admin`
  - Masuk ke dashboard admin jika agency sudah approved.
  - Mengelola room melalui fitur CRUD.
  - Melihat booking management.
  - Melihat payment management.
  - Melihat laporan, calendar, dan history admin.

- `user`
  - Masuk ke halaman home.
  - Mencari dan melihat detail room.
  - Membuat booking dari detail room.
  - Masuk ke payment checkout.
  - Melihat payment history dan payment detail.

Alur utama aplikasi:

1. User login atau register melalui Supabase Auth.
2. User masuk ke home dan melihat daftar room aktif.
3. User membuka detail room dan memulai booking.
4. Booking disimpan ke tabel `bookings`.
5. User masuk ke daftar booking atau payment checkout.
6. Payment dibuat melalui modul payment dan Edge Function `create-payment`.
7. Status payment disimpan pada tabel `payments`.
8. Admin memantau booking dan payment melalui dashboard admin.
9. Super admin memantau agency, user, audit log, dan laporan platform.

## 3. Product Requirement Document (PRD)

ClassRent adalah aplikasi penyewaan ruang kelas, ruang meeting, studio, dan fasilitas belajar lain yang membantu user mencari ruangan, melakukan booking, dan melakukan pembayaran secara digital. Aplikasi ini juga menyediakan panel admin untuk pengelolaan ruangan, booking, payment, dan laporan operasional.

Role aplikasi:

- `super_admin`
  - Mengelola platform secara keseluruhan.
  - Melihat dashboard super admin.
  - Mengelola approval agency.
  - Melihat audit log dan laporan platform.

- `admin`
  - Mengelola data agency.
  - Mengelola CRUD room.
  - Mengelola booking dari user.
  - Melihat payment management.
  - Melihat laporan dan histori aktivitas.

- `user`
  - Login/register.
  - Melihat daftar ruangan.
  - Melihat detail ruangan.
  - Membuat booking.
  - Mengakses payment checkout.
  - Melihat payment history.

Alur aplikasi secara ringkas:

1. User melakukan login atau register.
2. User mencari dan memilih ruangan.
3. User membuat booking.
4. Booking terhubung ke payment.
5. User menekan tombol bayar.
6. Sistem menyiapkan pembayaran melalui modul payment.
7. Admin memantau booking dan payment melalui dashboard admin.
8. Super admin memantau agency, user, audit log, dan kondisi platform.

Fitur utama:

- Authentication berbasis Supabase.
- Role-based routing untuk `super_admin`, `admin`, dan `user`.
- Agency approval untuk admin.
- CRUD room untuk admin.
- Booking management.
- Payment module.
- Payment history user.
- Payment management admin.
- Persiapan integrasi Midtrans melalui Supabase Edge Function.
- Audit log untuk aktivitas penting.

## 4. Arsitektur Saat Ini

### Frontend

Frontend menggunakan Flutter dengan struktur utama:

- `lib/core`
  - konfigurasi environment
  - router GoRouter
  - Supabase client provider
  - theme
  - reusable widgets

- `lib/features`
  - `auth`
  - `admin`
  - `booking`
  - `rooms`
  - `payments`
  - `home`
  - `search`
  - `favorites`
  - `notifications`
  - `profile`
  - `support_tickets`

- `lib/shared`
  - entity bersama seperti `AppUser`
  - widget navigasi role-aware dan admin nav bar

State management menggunakan Riverpod. Routing menggunakan GoRouter dengan redirect berdasarkan autentikasi, role, dan status approval agency.

### Backend

Backend utama menggunakan Supabase:

- Supabase Auth untuk login/register/session.
- Supabase Database untuk tabel user, agency, room, booking, payment, notification, audit log, dan fitur pendukung lain.
- Supabase RLS untuk pembatasan akses.
- Supabase Edge Function untuk integrasi Midtrans.

Repository layer di Flutter menggunakan pola domain repository dan data repository. Contoh yang sudah tersedia:

- `SupabaseAuthRepository`
- `SupabaseRoomsRepository`
- `SupabaseBookingRepository`
- `SupabasePaymentRepository`
- `SupabaseAgencyRepository`

### Database

Migration Supabase sudah tersedia di folder `supabase/migrations`. Kondisi schema saat ini mencakup:

- `users`
- `agencies`
- `facilities`
- `rooms`
- `bookings`
- `payments`
- `payment_logs`
- `payment_refunds`
- `notifications`
- `audit_logs`
- `reviews`
- `support_tickets`
- tabel pendukung room schedule, favorite, consent, session, dan lain-lain.

Migration payment Midtrans juga sudah tersedia:

- `20260611120000_prepare_midtrans_payments.sql`

Migration tersebut menyiapkan field payment seperti:

- `order_id`
- `transaction_id`
- `gross_amount`
- `payment_method`
- `payment_type`
- `transaction_status`
- `snap_token`
- `snap_redirect_url`
- `midtrans_response`
- `paid_at`
- `expired_at`

### Integrasi Eksternal

Integrasi eksternal yang sedang dikerjakan:

- Midtrans Snap melalui Edge Function `create-payment`.
- Midtrans webhook melalui Edge Function `midtrans-webhook`.

Function yang tersedia:

- `supabase/functions/create-payment/index.ts`
  - menerima `booking_id`
  - mengambil booking dari Supabase
  - membuat Snap transaction
  - menyimpan payment ke tabel `payments`

- `supabase/functions/midtrans-webhook/index.ts`
  - menerima payload webhook Midtrans
  - verifikasi signature
  - update `transaction_status`
  - update `paid_at`
  - menyimpan `midtrans_response`
  - sinkron booking menjadi `confirmed` saat status `settlement` atau `capture`

Status integrasi Midtrans: sudah disiapkan secara struktur dan fungsi, tetapi masih perlu validasi deployment, secret environment, CORS/JWT, dan koneksi function hosted Supabase.

## 5. Fitur yang Sudah Berjalan

### Stabil

- Struktur project Flutter modular.
- Routing dasar menggunakan GoRouter.
- Role-based redirect untuk user, admin, dan super admin.
- Authentication dan session restore.
- Agency approval flow untuk admin.
- Admin navigation dan user navigation.
- Room list dan room detail.
- CRUD room admin.
- Soft delete room.
- Search room.
- Profile update.

### Tersambung Backend

- Authentication ke Supabase.
- Room public list dari tabel `rooms`.
- Room management admin dari tabel `rooms`.
- Booking creation dari room detail ke tabel `bookings`.
- Booking list user dari tabel `bookings`.
- Booking management admin dari tabel `bookings`.
- Payment history dari tabel `payments`.
- Payment detail dari tabel `payments`.
- Admin payment management dari tabel `payments`.
- Admin history dari tabel `audit_logs`.
- Supabase migrations dan RLS.

### Masih Skeleton / Parsial

- Beberapa dashboard masih memakai ringkasan sederhana.
- Analytics admin/super admin belum sepenuhnya matang.
- Favorites, notifications, support tickets, dan reviews sudah memiliki struktur tetapi belum seluruhnya menjadi flow final.
- Payment checkout sudah memanggil Edge Function, tetapi masih ada kendala runtime pada pemanggilan function hosted.
- Auto refresh status payment sudah disiapkan pada sisi user checkout, tetapi keberhasilannya bergantung pada webhook dan function deployment.

### Belum Selesai

- Validasi end-to-end Midtrans dari Flutter sampai status settlement.
- Deployment Edge Function ke project Supabase production.
- Secret management final untuk `MIDTRANS_SERVER_KEY`, `SUPABASE_SERVICE_ROLE_KEY`, dan environment production.
- Verifikasi webhook Midtrans pada URL hosted.
- Hardening error handling payment.
- Analytics yang benar-benar berbasis data transaksi final.

## 6. Progress Implementasi

Estimasi progress berdasarkan kondisi repository saat ini:

| Area | Estimasi | Keterangan |
| --- | ---: | --- |
| Foundation Flutter | 85% | Struktur core/features/shared, routing, theme, widget dasar, dan env sudah tersedia. |
| Authentication | 85% | Login, register, session restore, role provider, dan profile update sudah tersedia. |
| Admin Module | 80% | Dashboard, approval, room management, booking management, report, calendar, dan history tersedia. |
| Room Management | 90% | CRUD, update, soft delete, list admin, list public, detail, schedule/facility support sudah tersedia. |
| Booking | 70% | Booking user dari room detail sudah masuk database, list user dan admin tersedia, tetapi flow approval/status masih perlu penyempurnaan. |
| Payment | 65% | Model, repository, provider, checkout, history, detail, admin management, dan summary tersedia; integrasi function masih perlu distabilkan. |
| Integration | 55% | Supabase kuat, Midtrans function sudah dibuat, tetapi deployment/secret/webhook belum final. |
| Deployment Readiness | 45% | Environment template ada, tetapi perlu validasi hosted Supabase, Edge Function deploy, dan environment secrets. |

## 7. Pembagian Tugas Kelompok

| Nama | NIM | Jobdesk | Progress |
| --- | --- | --- | --- |
| [Guritno Wulandoro S] | [240103132] | Perbaikan CRUD Admin, perbaikan delete room, pengembangan payment, persiapan integrasi Midtrans, sinkronisasi payment user-admin, perbaikan bug payment | In progress |
| [Nama Anggota 2] | [NIM] | [Jobdesk] | [Progress] |
| [Nama Anggota 3] | [NIM] | [Jobdesk] | [Progress] |
| [Nama Anggota 4] | [NIM] | [Jobdesk] | [Progress] |

### Progress Pekerjaan Saya

Pekerjaan yang sudah selesai:

- Memperbaiki CRUD Admin pada modul room.
- Memperbaiki soft delete room agar admin dapat mengarsipkan room.
- Menambahkan dan menyempurnakan modul Payment.
- Menyiapkan model, repository, provider, dan screen payment.
- Menambahkan payment history user.
- Menambahkan payment checkout user.
- Menambahkan payment detail user.
- Menambahkan admin payment management.
- Menambahkan admin payment detail.
- Menyiapkan migration payment untuk field Midtrans.
- Menyiapkan Edge Function `create-payment`.
- Menyiapkan Edge Function `midtrans-webhook`.
- Menambahkan sinkronisasi payment user-admin melalui tabel `payments`.
- Menambahkan filter dan summary admin payment.
- Menambahkan logging untuk debugging payment.
- Memperbaiki beberapa bug payment seperti route checkout, history kosong karena payment belum dibuat, dan URL Supabase function.

Pekerjaan yang sedang berjalan:

- Menstabilkan pemanggilan Edge Function `create-payment` dari Flutter.
- Memastikan deployment Edge Function dan secret Supabase sesuai project.
- Menyelesaikan sinkronisasi booking-payment setelah webhook Midtrans.
- Menyempurnakan error handling payment agar lebih informatif.

Pekerjaan berikutnya:

- Deploy ulang Edge Function ke project Supabase yang benar.
- Memasang secret Supabase Edge Function secara aman.
- Menguji webhook Midtrans pada environment sandbox.
- Memastikan status `settlement`, `capture`, `cancel`, `expire`, `deny`, `failure`, dan `refund` tampil benar pada user dan admin.
- Menyiapkan screenshot dan bukti progres untuk laporan UAS.

## 8. Progress Saat Ini

Selesai:

- Authentication
- Agency approval
- Admin CRUD Room
- Booking Management
- Payment module
- Edge Function Midtrans
- Payment UI

Dalam progres:

- Midtrans webhook
- booking → payment sync
- analytics

Detail progress:

- Struktur frontend Flutter sudah menggunakan Riverpod untuk state management dan GoRouter untuk routing.
- Supabase digunakan sebagai backend utama untuk authentication, database, RLS, dan Edge Function.
- Admin sudah dapat mengelola room melalui fitur CRUD.
- Booking Management sudah tersedia pada sisi admin.
- Modul Payment sudah dibuat untuk sisi user dan admin.
- Payment user memiliki flow checkout, payment history, dan payment detail.
- Admin Payment Management sudah membaca data dari tabel `payments`.
- Supabase Edge Function `create-payment` dan `midtrans-webhook` sudah disiapkan untuk integrasi Midtrans.
- Integrasi Midtrans masih dalam tahap penyempurnaan, terutama pada pemanggilan Edge Function, webhook, dan sinkronisasi status booking-payment.

## 9. Screenshot Yang Harus Dilampirkan

### Screenshot Aplikasi

(tempel manual)

### Screenshot CRUD Admin

(tempel manual)

### Screenshot Payment

(tempel manual)

### Screenshot Midtrans

(tempel manual)

### Screenshot Git Graph

(tempel manual)

## 10. Risiko dan Kendala

Blocker dan risiko yang ditemukan dari analisis repository:

- Edge Function `create-payment` sudah ada, tetapi pemanggilan hosted masih mengalami `ClientException: Failed to fetch` pada sisi Flutter.
- Kemungkinan penyebab payment function gagal adalah deployment function belum sesuai project, CORS/JWT function, atau secret environment belum lengkap.
- File `.env` lokal harus dipastikan memakai root Supabase URL, bukan URL `/rest/v1`.
- Secret `MIDTRANS_SERVER_KEY` tidak boleh masuk Flutter dan harus hanya berada di Supabase Edge Function.
- Booking-payment sync belum sepenuhnya final karena status booking setelah payment bergantung pada webhook.
- Webhook Midtrans perlu endpoint hosted yang stabil dan terdaftar pada dashboard Midtrans.
- Payment History hanya menampilkan row tabel `payments`, sehingga user harus masuk flow `Bayar Sekarang` agar payment dibuat.
- Analytics masih belum final dan sebagian masih berupa ringkasan sederhana.
- Deployment readiness belum penuh karena perlu validasi Supabase hosted, Edge Function deploy, dan environment secrets.

## 11. Next Step

Roadmap pendek berdasarkan progres aktual:

1. Validasi konfigurasi Supabase URL dan environment Flutter.
2. Deploy `create-payment` dan `midtrans-webhook` ke project Supabase yang sama dengan aplikasi.
3. Set Supabase secrets:
   - `SUPABASE_SERVICE_ROLE_KEY`
   - `MIDTRANS_SERVER_KEY`
   - `MIDTRANS_CLIENT_KEY`
   - `MIDTRANS_IS_PRODUCTION`
4. Uji create payment dari booking user sampai mendapatkan `snap_redirect_url`.
5. Uji pembayaran sandbox Midtrans.
6. Uji webhook agar `transaction_status`, `paid_at`, dan status booking tersinkron.
7. Lengkapi analytics admin berdasarkan data booking/payment aktual.
8. Siapkan screenshot UAS dan bukti Git Graph.
9. Review final role access untuk user, admin, dan super admin.
10. Persiapan demo dan dokumentasi final.

## 12. Repository

Repository:
[isi link github]

Catatan:
Jika repository private tambahkan dosen:
`triyono777`

## 13. Kesimpulan

ClassRent sudah memiliki pondasi aplikasi yang cukup lengkap untuk kebutuhan UAS. Modul authentication, role-based routing, admin room management, booking, payment UI, payment repository, database Supabase, migration, dan Edge Function Midtrans sudah tersedia di repository. Bagian yang masih menjadi fokus utama adalah penyelesaian integrasi Midtrans secara end-to-end, terutama deployment Edge Function, secret management, webhook, dan sinkronisasi status booking-payment. Secara keseluruhan, project sudah berada pada tahap integrasi dan stabilisasi fitur sebelum demo akhir.
