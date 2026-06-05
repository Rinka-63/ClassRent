# ClassRent PRD Progress v6

Dokumen ini dibuat untuk menjelaskan kondisi project ClassRent saat ini dengan bahasa yang sederhana, supaya tim baru atau teman satu tim bisa langsung paham alur produk, progres yang sudah ada, dan pembagian jobdesk.

---

## 1. Gambaran Singkat Produk

ClassRent adalah aplikasi penyewaan ruangan berbasis Flutter + Supabase.

Tujuan utama aplikasi:
- user bisa mencari dan booking ruangan
- admin agency bisa mengelola ruangan miliknya
- super admin bisa mengawasi seluruh platform dan menyetujui agency baru

Role yang aktif saat ini:
- `super_admin`
- `admin`
- `user`

Catatan:
- role `staff` sudah tidak dipakai di runtime aktif
- flow auth yang sudah berjalan jangan diubah lagi kecuali ada bug

---

## 2. Status Produk Saat Ini

Secara umum, project sudah berada di fase:
- foundation sudah jadi
- auth sudah berjalan
- role redirect sudah berjalan
- dashboard tiap role sudah ada
- CRUD room dan booking admin sudah mulai tersambung ke backend
- super admin dashboard sedang difokuskan ke tampilan modern dan data yang rapi

Artinya:
- project belum final
- tapi arsitektur dasarnya sudah cukup stabil untuk dilanjutkan oleh beberapa orang

---

## 3. Tujuan Dokumen Ini

Dokumen ini dipakai sebagai:
- panduan kerja tim
- pembagian tanggung jawab
- referensi progress saat ini
- acuan supaya tiap orang tidak mengerjakan fitur yang sama

---

## 4. Pembagian Tugas Tim

### A. Aris

Fokus:
- database
- semua auth flow
- dashboard super admin
- semua fitur super admin

Tanggung jawab Aris:
1. Menjaga schema Supabase tetap konsisten.
2. Menulis migration baru jika diperlukan.
3. Menjaga RLS tetap aman.
4. Menangani login, register, session, dan redirect role.
5. Menyelesaikan dan merapikan Super Admin Dashboard.
6. Menjaga modul Super Admin:
   - agency management
   - user management
   - audit logs
   - analytics
   - settings

Catatan penting untuk Aris:
- jangan mengubah alur registrasi agency yang sudah berjalan
- jangan mengacaukan role system yang sudah stabil
- prioritas utama adalah data benar, UI stabil, dan error handling rapi

---

### B. Guritno

Fokus:
- CRUD admin agency
- semua fitur admin agency

Tanggung jawab Guritno:
1. Menyelesaikan CRUD room.
2. Menjaga fitur fasilitas room.
3. Menyelesaikan jadwal room.
4. Menyelesaikan sistem booking untuk agency.
5. Menyelesaikan booking management.
6. Menyelesaikan laporan internal admin agency.
7. Menjaga tampilan admin agency konsisten dengan design system ClassRent.

Catatan penting untuk Guritno:
- dashboard admin agency sekarang harus tetap fokus ke list room
- fitur tambahan harus masuk ke menu terpisah
- logout tetap di halaman profile

---

### C. Lutfi

Fokus:
- CRUD user
- semua fitur user, tapi masih dasar sesuai progress saat ini

Tanggung jawab Lutfi:
1. Menjaga halaman user agar rapi dan stabil.
2. Menyelesaikan fitur dasar user seperti:
   - home
   - search
   - favorites
   - room detail
   - booking flow dasar
   - profile
3. Menjaga UI user tidak rusak saat fitur admin berubah.
4. Menyederhanakan fitur user supaya sesuai tahap progress sekarang.

Catatan penting untuk Lutfi:
- user masih dalam tahap dasar
- jangan memaksakan fitur yang belum dibutuhkan
- fokus ke flow yang stabil dulu

---

## 5. Struktur Modul Saat Ini

### Modul Auth

Status:
- sudah berjalan
- jangan dibongkar kalau tidak perlu

Isi modul:
- login
- register
- logout
- session persistence
- role redirect

### Modul Super Admin

Status:
- aktif
- sedang difinalkan

Isi modul:
- overview dashboard
- agency management
- user management
- audit logs
- analytics
- settings

### Modul Admin Agency

Status:
- aktif
- fokus ke operasi agency

Isi modul:
- room list
- room management
- fasilitas room
- jadwal room
- booking management
- reports

### Modul User

Status:
- aktif
- masih dasar

Isi modul:
- home
- search
- favorites
- room detail
- booking flow
- profile

---

## 6. Alur Produk yang Benar

### 6.1 Alur User

1. User register.
2. User login.
3. User melihat daftar ruangan.
4. User membuka detail ruangan.
5. User booking ruangan.
6. User melihat booking dan profile.

### 6.2 Alur Agency Admin

1. Admin agency register.
2. Data agency masuk ke tabel `agencies` dengan status `pending`.
3. Super admin melihat agency baru di dashboard.
4. Super admin approve atau reject agency.
5. Setelah approved, admin agency bisa login normal.
6. Admin agency mengelola room, fasilitas, jadwal, dan booking.

### 6.3 Alur Super Admin

1. Super admin login manual.
2. Super admin melihat overview platform.
3. Super admin mengelola agency.
4. Super admin mengelola user.
5. Super admin melihat audit logs.
6. Super admin melihat analytics platform.
7. Super admin bisa logout lewat settings.

---

## 7. Progress Saat Ini

### Sudah Ada dan Berjalan

- auth login/register/logout
- session restore
- role redirect
- super admin dashboard
- agency approval flow
- admin agency dashboard
- room list
- room detail
- fasilitas room
- jadwal room
- booking list
- audit logs dasar
- reports dasar

### Sudah Tersambung ke Backend

- load agency dari Supabase
- approve/reject agency
- load users
- load audit logs
- load analytics
- room CRUD dasar
- fasilitas room
- jadwal room
- booking data dasar

### Masih Perlu Dirapikan

- UI super admin dashboard masih perlu dihaluskan
- audit log detail masih perlu dibuat benar-benar ringkas
- chart analytics masih bisa diperkaya
- pagination di beberapa list masih perlu dipastikan nyaman
- user management masih perlu disederhanakan

---

## 8. Database yang Dipakai Saat Ini

Tabel penting:
- `users`
- `agencies`
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

Catatan:
- `agencies` adalah tabel utama untuk agency
- `facilities` bukan tabel agency
- `room_facilities` dipakai untuk fasilitas per room

---

## 9. Standar Kerja yang Harus Dijaga

1. Jangan ubah auth flow yang sudah stabil.
2. Jangan ubah role system tanpa alasan kuat.
3. Jangan hapus data lama.
4. Jangan drop table yang masih dipakai.
5. Kalau perlu perubahan database, pakai migration baru.
6. Kalau ada error, perbaiki dari sumbernya, bukan ditutup dengan UI kosong.
7. UI harus konsisten dengan design system ClassRent.

---

## 10. Super Admin Dashboard - Scope Final

Super Admin Dashboard harus berisi:
- Overview
- Agency Management
- User Management
- Audit Logs
- Settings

### Overview

Tampilan overview harus:
- modern
- profesional
- jelas
- tidak overflow
- tidak menampilkan error mentah

Data yang ditampilkan:
- total users
- total agencies
- pending agencies
- active rooms
- total bookings
- growth chart
- recent activity

### Agency Management

Harus ada:
- search
- filter status
- pagination
- detail agency
- approve
- reject
- suspend
- reactivate

### User Management

Harus ada:
- search
- filter role
- filter status
- pagination
- detail user
- suspend
- activate

Catatan:
- `super admin` tidak perlu muncul sebagai opsi filter user biasa

### Audit Logs

Harus ada:
- list audit
- search
- filter
- detail dialog ringkas

Catatan:
- jangan tampilkan JSON mentah kalau tidak perlu
- jangan tampilkan before/after kalau bikin UI berat di emulator kecil

### Settings

Harus ada:
- theme mode
- language
- about app
- developer info
- logout

---

## 11. Prioritas Kerja ke Depan

### Untuk Aris

1. Stabilkan super admin dashboard.
2. Rapikan analytics dan audit log.
3. Pastikan RLS dan query Supabase aman.
4. Pastikan settings theme/language stabil.

### Untuk Guritno

1. Selesaikan CRUD room agency.
2. Selesaikan fasilitas room.
3. Selesaikan jadwal room.
4. Selesaikan booking action per room.

### Untuk Lutfi

1. Rapikan home user.
2. Rapikan search dan favorites.
3. Rapikan room detail user.
4. Rapikan booking flow dasar.

---

## 12. Risiko Yang Harus Dihindari

- error layout pada layar kecil
- overflow pada card dashboard
- query Supabase yang mentah
- audit log yang terlalu teknis
- perubahan auth yang memecahkan redirect
- perubahan role yang mengacaukan akses
- UI yang terlalu berbeda antar role

---

## 13. Definisi Selesai

Sebuah fitur dianggap selesai kalau:
- tidak error saat dibuka
- datanya benar
- UI konsisten
- tidak overflow
- analyzer bersih
- user bisa mengerti alurnya tanpa kebingungan

---

## 14. Ringkasan Untuk Pemula

Kalau kamu baru masuk project ini, ingat 4 hal:

1. `super_admin` mengawasi platform.
2. `admin` mengelola ruangan agency.
3. `user` menyewa ruangan.
4. Jangan merusak auth dan role yang sudah jalan.

Kalau bingung mau mulai dari mana:
- Aris kerjakan server, auth, dan super admin
- Guritno kerjakan admin agency
- Lutfi kerjakan user

---

## 15. Penutup

Dokumen ini adalah gambaran progress ClassRent saat ini.  
Tujuan utamanya adalah supaya tim bisa lanjut kerja tanpa harus membongkar ulang fondasi yang sudah jadi.

