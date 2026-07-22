# Pembagian Kontribusi Anggota Kelompok — Proyek ClassRent

Dokumen ini merangkum pembagian kontribusi 3 orang yang terlibat dalam pengerjaan proyek ClassRent. Data disusun berdasarkan audit histori commit pada repository ini per tanggal 2026-07-22, terutama dari `git log --pretty=format:'%an|%ae|%ad' --date=short` dan `git log --numstat --all`.

## Metode Audit

Audit disusun dari:

1. Histori commit Git pada repository ClassRent.
2. Area folder dan file yang paling sering disentuh tiap kontributor berdasarkan `git log --numstat --all`.
3. Mapping username GitHub ke identitas anggota kelompok yang diberikan.

Catatan penting:

- `Rinka-63` teridentifikasi sebagai Aris Wahyu Prasetyo.
- `garet132` teridentifikasi sebagai Guritno Wulandoro Suryosaputro.
- `lutfi211` teridentifikasi sebagai Muhammad Lutfi Samsul.
- Tidak ditemukan author lain di hasil `git shortlog -sne --all`.

## Ringkasan Pembagian

| Kontributor | Nama | NIM | Peran Utama | Fokus Pekerjaan |
| --- | --- | --- | --- | --- |
| `Rinka-63` | Aris Wahyu Prasetyo | 240103126 | Lead implementer, integrator, dan penjaga fondasi teknis | Fondasi Flutter, routing, auth, admin dan super admin, Supabase, payment, dokumentasi, dan stabilisasi fitur inti |
| `garet132` | Guritno Wulandoro Suryosaputro | 240103132 | Pengembang modul booking, admin room, dan backend pendukung | Booking flow, coupon, room management, repository rooms, migrasi database admin room, policy, dan soft delete |
| `lutfi211` | Muhammad Lutfi Samsul | 240103141 | Pengembang UI pengguna dan penyempurnaan pengalaman pencarian ruangan | Home, promo, profile, room detail, room card, favorites, dan search |

## Bukti Aktivitas per Kontributor

### 1) `Rinka-63` — Aris Wahyu Prasetyo

`Rinka-63` terlihat sebagai kontributor yang banyak berperan pada fondasi aplikasi, integrasi lintas modul, fitur admin, backend Supabase, serta dokumentasi proyek.

**Kontribusi utama di aplikasi Flutter:**

- Membangun dan menyempurnakan fondasi aplikasi seperti routing, konfigurasi, konstanta route, konstanta tabel Supabase, shared preferences, dan struktur dasar aplikasi.
- Mengembangkan modul autentikasi, termasuk repository Supabase auth, provider auth, login screen, onboarding, splash screen, dan welcome auth screen.
- Mengembangkan banyak bagian modul admin dan super admin, termasuk dashboard, kalender admin, histori, laporan, manajemen booking, manajemen ruangan, coupon management, QR scanner, audit log, detail agency, detail user, dan navigasi super admin.
- Mengembangkan modul booking, rooms, favorites, payments, dan notifications.
- Menangani integrasi payment melalui Midtrans service dan Midtrans webview.

**Kontribusi utama di backend dan konfigurasi:**

- Menambahkan dan menyesuaikan migrasi Supabase untuk super admin, agency registration, coupons, favorites, audit log, policy, serta relasi data pendukung.
- Menambahkan Supabase functions terkait Midtrans dan staff.
- Menangani konfigurasi lintas platform Flutter untuk Android, iOS, macOS, Linux, Windows, dan web.
- Menyusun dan memperbarui dokumentasi proyek seperti PRD progress, ERD, blueprint, dan Flutter foundation.

**Area file yang paling sering disentuh:**

- `lib/features/admin/*`
- `lib/core/*`
- `lib/features/auth/*`
- `lib/features/booking/*`
- `lib/features/rooms/*`
- `lib/features/payments/*`
- `lib/features/notifications/*`
- `supabase/migrations/*`
- `supabase/functions/*`
- `android/*`, `ios/*`, `macos/*`, `linux/*`, `windows/*`, dan `web/*`

**Kesimpulan peran:**

Aris berperan sebagai penggerak utama implementasi teknis dan integrator proyek. Porsi terbesarnya berada pada fondasi sistem, fitur admin/super admin, autentikasi, backend Supabase, payment, dokumentasi, serta stabilisasi aplikasi agar ClassRent menjadi MVP yang utuh.

### 2) `garet132` — Guritno Wulandoro Suryosaputro

`garet132` terlihat banyak berkontribusi pada alur booking, manajemen ruangan admin, serta migrasi database yang mendukung operasional admin. Area pekerjaannya memperkuat hubungan antara fitur booking, rooms, coupon, dan policy Supabase.

**Kontribusi utama di aplikasi Flutter:**

- Mengembangkan dan menyesuaikan booking repository, booking flow provider, booking entity, coupon DTO, coupon repository, dan booking flow screen.
- Menambahkan utilitas auto cancel pending bookings.
- Menyentuh modul admin seperti room management screen, QR scanner screen, admin dashboard, admin calendar, booking management, admin history, dan repository agency.
- Menyesuaikan repository rooms dan bagian navigasi admin.

**Kontribusi utama di backend dan database:**

- Menambahkan migrasi untuk admin CRUD room facilities.
- Menyesuaikan audit booking status.
- Memperbaiki policy soft delete room.
- Memperbaiki RLS update pada rooms.
- Menambahkan policy select rooms untuk admin.
- Membuat RPC soft delete room.

**Area file yang paling sering disentuh:**

- `lib/features/booking/*`
- `lib/features/admin/*`
- `lib/features/rooms/*`
- `lib/shared/*`
- `supabase/migrations/*`

**Kesimpulan peran:**

Guritno berperan sebagai penguat modul booking dan operasional admin, terutama pada room management, coupon/booking flow, repository rooms, serta migrasi database yang membuat proses pengelolaan ruangan dan booking lebih siap digunakan.

### 3) `lutfi211` — Muhammad Lutfi Samsul

`lutfi211` kontribusinya paling terlihat pada sisi tampilan pengguna. Perubahan yang dikerjakan banyak menyentuh halaman yang langsung digunakan user saat mencari, melihat detail, dan menyimpan ruangan.

**Kontribusi utama di aplikasi Flutter:**

- Mengembangkan dan menyempurnakan home screen.
- Menambahkan atau menyesuaikan promo screen.
- Menyentuh room detail screen dan room card.
- Menyesuaikan favorites provider dan favorites screen.
- Menyempurnakan profile screen dan agency profile screen.
- Menyentuh search screen untuk pengalaman pencarian ruangan.

**Area file yang paling sering disentuh:**

- `lib/features/home/*`
- `lib/features/rooms/*`
- `lib/features/profile/*`
- `lib/features/search/*`

**Kesimpulan peran:**

Lutfi berperan pada pengembangan UI pengguna dan penyempurnaan pengalaman pemakaian aplikasi, terutama pada halaman home, promo, profile, room detail, favorites, dan search yang menjadi bagian penting dari perjalanan pengguna.

## Pembagian Tanggung Jawab Berdasarkan Modul

| Modul | Penanggung Jawab Dominan | Catatan |
| --- | --- | --- |
| Fondasi project Flutter, routing, konfigurasi, dan struktur aplikasi | `Rinka-63` | Termasuk `lib/core`, `main.dart`, konfigurasi environment, dan setup platform |
| Autentikasi dan flow masuk pengguna | `Rinka-63` | Termasuk repository auth, provider auth, login, onboarding, splash, dan welcome screen |
| Admin dashboard dan operasional admin | `Rinka-63` dengan dukungan `garet132` | `Rinka-63` dominan pada cakupan admin/super admin, `garet132` mendukung room management dan booking management |
| Super admin, audit log, agency, dan platform management | `Rinka-63` | Termasuk tab super admin, detail agency/user/room, audit log, dan repository super admin |
| Booking flow dan coupon | `Rinka-63` dan `garet132` | `Rinka-63` dominan secara cakupan, `garet132` kuat pada booking flow, coupon, repository, dan utilitas booking |
| Rooms dan room detail | `Rinka-63`, `garet132`, dan `lutfi211` | `Rinka-63` dominan pada implementasi luas, `garet132` pada repository/management, `lutfi211` pada tampilan user |
| Home, promo, profile, favorites, dan search | `lutfi211` dengan dukungan `Rinka-63` | `lutfi211` fokus pada UI pengguna, `Rinka-63` juga menyentuh modul terkait dalam pengembangan keseluruhan |
| Payment dan Midtrans | `Rinka-63` | Termasuk service Midtrans, payment method, dan webview pembayaran |
| Supabase migrations, functions, dan policy database | `Rinka-63` dan `garet132` | `Rinka-63` dominan secara volume, `garet132` kuat pada migrasi admin room, policy, dan soft delete |
| Dokumentasi proyek | `Rinka-63` | Termasuk PRD progress, ERD, blueprint, dan foundation Flutter |

## Pembagian Akhir Untuk Laporan

Jika diringkas untuk kebutuhan laporan akademik, pembagian kontribusinya dapat ditulis seperti ini:

1. Aris Wahyu Prasetyo (`Rinka-63`) bertanggung jawab sebagai kontributor utama yang mengerjakan fondasi project, routing, autentikasi, modul admin dan super admin, integrasi backend Supabase, payment, dokumentasi, serta stabilisasi aplikasi.
2. Guritno Wulandoro Suryosaputro (`garet132`) bertanggung jawab pada penguatan modul booking, coupon, admin room management, repository rooms, serta migrasi Supabase yang mendukung policy, soft delete, dan operasional admin.
3. Muhammad Lutfi Samsul (`lutfi211`) bertanggung jawab pada pengembangan UI pengguna, terutama home, promo, profile, room detail, favorites, room card, dan search.

## Kesimpulan

Secara keseluruhan, pembagian kerja di proyek ClassRent menunjukkan peran yang berbeda pada tiap anggota:

- `Rinka-63` sebagai penggerak utama teknis, integrator, dan pengembang fondasi serta fitur inti.
- `garet132` sebagai penguat modul booking, admin room, dan backend operasional.
- `lutfi211` sebagai pengembang tampilan pengguna dan flow pencarian/eksplorasi ruangan.

Pola kontribusi ini membuat ClassRent berkembang sebagai aplikasi MVP yang mencakup fondasi teknis, fitur operasional admin, backend Supabase, serta pengalaman pengguna untuk mencari dan memesan ruangan.

## Catatan Metodologi

Data pada dokumen ini disusun dari riwayat Git repository pada tanggal 2026-07-22. Histori commit dan area file digunakan sebagai bahan audit untuk melihat pola kontribusi, tetapi bukan satu-satunya ukuran kontribusi anggota. Aktivitas seperti diskusi desain, perencanaan fitur, testing manual, review, debugging bersama, dan penyusunan laporan dapat berkontribusi besar terhadap proyek namun tidak selalu tercatat langsung di Git.
