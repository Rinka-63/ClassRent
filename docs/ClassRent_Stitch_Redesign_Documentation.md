# ClassRent UI Redesign Documentation for Stitch

Dokumen ini dibuat sebagai acuan redesign UI/UX ClassRent di Stitch tanpa mengubah logika bisnis, database, API, role, maupun flow aplikasi yang sudah ada.

## 1. Product Requirement Document (PRD)

### 1.1 Tujuan Aplikasi

ClassRent adalah aplikasi penyewaan ruang kelas dan ruang pendukung kegiatan belajar/meeting. Aplikasi membantu pengguna menemukan ruangan, melihat fasilitas dan jadwal, membuat booking, membayar melalui Midtrans, serta memantau status booking. Untuk pemilik agency, aplikasi menyediakan pengelolaan ruangan, booking, jadwal, laporan, dan aktivitas. Untuk super admin, aplikasi menyediakan kontrol platform lintas agency, user, room, payment, approval, dan audit log.

### 1.2 Target Pengguna

| Segment | Kebutuhan Utama |
|---|---|
| User/Penyewa | Mencari ruang, melihat detail, menyimpan favorit, booking, pembayaran, melihat riwayat. |
| Admin Agency | Mengelola room milik agency, memantau booking, approve/reject/cancel, scan QR, melihat laporan dan audit. |
| Super Admin | Mengawasi seluruh platform, approval agency, manajemen user, room, payment, revenue, dan audit log. |

### 1.3 Value Proposition

- Booking ruang kelas lebih cepat dan transparan.
- Informasi room terstruktur: kapasitas, fasilitas, harga, jadwal, status, rating, dan lokasi.
- Pembayaran online melalui Midtrans.
- Admin agency dapat mengelola inventory room dan booking dalam satu aplikasi.
- Super admin memiliki governance platform melalui approval, audit, analytics, dan user/agency controls.

### 1.4 Ruang Lingkup Aplikasi

In scope:
- Authentication, onboarding, login, register, forgot password.
- Role-based routing untuk User, Admin Agency, Super Admin.
- Room discovery, search, favorites, detail room.
- Booking flow: pilih tanggal/waktu, validasi konflik, konfirmasi, create booking.
- Payment via Midtrans WebView.
- Booking detail, booking list, cancellation/delete untuk user.
- Admin room management, booking management, report, calendar, QR scanner, agency profile, history.
- Super admin dashboard, analytics, agency approval, room/user/payment management, audit log, settings.
- Notification list, unread count, mark read/all read.
- Support ticket placeholder.

Out of scope untuk redesign Stitch:
- Perubahan skema Supabase.
- Perubahan RPC, webhook, storage policy, Midtrans integration.
- Perubahan business logic booking/payment/approval.
- Perubahan flow navigasi.

### 1.5 Fitur per Role

| Role | Fitur |
|---|---|
| User | Onboarding, login/register, dashboard, search room, room detail, favorite room, booking, payment, booking history/detail, notification, profile, support. |
| Admin Agency | Pending approval gate, dashboard, room CRUD, upload image, manage facilities, manage schedules, booking management, reject pending payment, cancel/refund confirmed booking, live room status, QR scanner, calendar, reports, agency profile, history/audit, profile. |
| Super Admin | Platform dashboard, analytics, agency approval/reject/suspend/reactivate, agency edit/deactivate, user management, role change, reset password, transfer ownership, room management, payment monitoring, audit log, settings. |

### 1.6 Business Rules

| Area | Rule |
|---|---|
| Auth | User tidak login diarahkan ke onboarding/welcome/login. User sudah login diarahkan berdasarkan role. |
| Onboarding | Jika belum pernah melihat onboarding, user diarahkan ke onboarding sebelum welcome auth. |
| Admin Approval | Admin agency dengan `hasApprovedAgency == false` diarahkan ke pending approval. |
| Role Access | Path `/admin` hanya untuk admin/super admin; path `/super-admin` hanya untuk super admin. |
| Booking | Booking dibuat dengan `pending_payment`. |
| Availability | Booking conflict dicek berdasarkan room, tanggal, waktu overlap; status `cancelled` dan `rejected` diabaikan. |
| Payment | Payment dibuat/diambil per booking. Midtrans WebView callback success mengubah booking menjadi `confirmed`. |
| Cancel/Delete User Booking | Pending booking bisa dibatalkan; cancelled/rejected bisa dihapus dari sisi user. |
| Admin Refund | Admin bisa cancel/refund booking `confirmed` via Midtrans refund flow. |
| Room Delete | Room delete pada admin bersifat arsip/soft delete; data booking tetap disimpan. |
| Super Admin Agency | Agency bisa approve, reject, suspend, reactivate, deactivate. |
| Super Admin User | User bisa activate, suspend, disable, delete, reset password, change role, transfer agency ownership. |

### 1.7 Batasan Sistem

- Beberapa halaman masih placeholder: payments list, support tickets, beberapa legal/help content.
- Midtrans WebView masih memiliki tombol simulasi bayar QR yang perlu diperlakukan sebagai non-production control.
- Agency profile memakai repository super admin untuk load/update agency detail.
- Beberapa UI menggunakan campuran bahasa Indonesia dan Inggris.
- `dart analyze` pada kondisi project saat ini menghasilkan lint warning/info; tidak ada perubahan flow yang diminta di dokumen ini.

## 2. Sitemap

### 2.1 Shared / Public

- Splash `/`
- Onboarding `/onboarding`
- Welcome Auth `/welcome-auth`
- Login/Register/Forgot Password `/login`
- Unauthorized `/unauthorized`

### 2.2 User Sitemap

- Home `/home`
  - Notifications `/notifications`
  - Profile `/profile`
- Search Rooms `/search`
  - Room Detail `/rooms/:roomId`
    - Booking Create `/booking/create/:roomId`
      - Payment Method `/payments/method/:bookingId`
      - Midtrans WebView `/payments/webview/:bookingId`
- Bookings `/bookings`
  - Booking Detail `/bookings/:bookingId`
  - Payment Method `/payments/method/:bookingId`
- Favorites `/favorites`
  - Room Detail `/rooms/:roomId`
- Payments `/payments`
- Support `/support`

### 2.3 Admin Agency Sitemap

- Pending Approval `/admin/pending`
- Admin Dashboard `/admin`
  - Notifications `/notifications`
  - Profile `/profile`
- Room Management `/admin/rooms`
  - Add/Edit Room Bottom Sheet
  - Room Detail `/rooms/:roomId`
    - Overview
    - Facilities edit
    - Schedule edit
    - Bookings tab
- Booking Management `/admin/bookings`
  - Booking Detail `/bookings/:bookingId`
  - Admin Calendar `/admin/calendar`
  - QR Scanner `/admin/scanner`
- Reports `/admin/reports`
- History `/admin/history`
- Agency Profile `/agency-profile`

### 2.4 Super Admin Sitemap

- Super Admin Shell `/super-admin`
  - Beranda / Dashboard
  - Agency
    - Agency Detail
    - Pending Registrations
  - Room
    - Room Detail
  - Payment
  - Lainnya
    - User Management
      - User Detail
    - Audit Log
- Settings `/super-admin/settings`
- Profile `/profile`
- Notifications `/notifications`

## 3. Information Architecture

| Category | Screens/Modules |
|---|---|
| Authentication | Splash, Onboarding, Welcome Auth, Login/Register, Forgot Password, Unauthorized |
| Dashboard | User Home, Admin Dashboard, Super Admin Home |
| Room Discovery | Search, Room Card, Room Detail, Favorites |
| Booking | Booking Flow, Bookings List, Booking Detail, Admin Booking Management, Room Bookings Tab |
| Payment | Payment Method, Midtrans WebView, Payments List, Super Admin Payment Tab |
| Notification | Notification List, Unread Count, Mark Read/All Read |
| Profile & Settings | Profile, Agency Profile, Super Admin Settings |
| Admin Management | Room Management, Booking Management, Calendar, QR Scanner, Reports, History |
| Super Admin Governance | Agency Tab, Agency Detail, User Tab, User Detail, Room Tab, Room Detail, Payment Tab, Audit Log |
| Support & Legal | Support Tickets, FAQ, Privacy Policy, Terms & Conditions, About Application placeholders |

## 4. User Flow

### 4.1 User Flow

1. Splash
2. Jika belum onboarding: Onboarding
3. Welcome Auth
4. Login atau Register User
5. Dashboard User
6. Search Room atau buka rekomendasi/favorit
7. Room Detail
   - lihat image, lokasi, kapasitas, harga, rating/status
   - tab overview/fasilitas/jadwal/booking
   - favorite/unfavorite
8. Booking Create
   - pilih tanggal
   - pilih jam mulai dan selesai
   - validasi waktu selesai setelah waktu mulai
   - cek konflik booking existing
9. Confirmation
   - ringkasan ruang, tanggal, waktu, durasi
   - ringkasan harga
10. Create Booking
    - status awal `pending_payment`
11. Payment Method
    - cek payment existing
    - cek booking amount
    - create Midtrans transaction
12. Midtrans WebView
    - loading progress
    - callback success/fail
13. Success
    - booking status menjadi `confirmed`
    - user kembali ke bookings
14. Booking Detail / History
    - lihat status dan detail pembayaran
    - action cancel/delete sesuai status
15. Profile
    - account, favorites, notification, support, app info, logout

### 4.2 Admin Agency Flow

1. Splash
2. Login/Register sebagai Agency Admin
3. Jika agency belum approved: Pending Approval
   - refresh status
   - logout
4. Admin Dashboard
   - stats rooms/bookings/revenue/pending
   - booking per room
   - room terbaru
   - quick actions
5. Room Management
   - search/filter kategori
   - add/edit room
   - upload/pilih gambar
   - set capacity, hourly rate, type, active, requires approval
   - set facilities
   - delete/soft delete
6. Room Detail
   - edit facilities
   - edit schedule operational
   - lihat bookings per room
   - confirm/cancel booking room
7. Booking Management
   - metrics pending/active/revenue/occupied
   - live room status
   - recent bookings
   - reject pending payment
   - cancel/refund confirmed booking
8. Calendar
   - lihat booking berdasarkan tanggal
9. QR Scanner
   - scan/check-in/check-out booking
10. Reports
    - total rooms, active rooms, approval, capacity, rating, price range
11. History
    - search/filter/sort audit log
12. Notification
13. Agency Profile
14. Profile / Logout

### 4.3 Super Admin Flow

1. Splash
2. Login sebagai Super Admin
3. Super Admin Dashboard
   - platform stats
   - analytics chart
   - alert cards
   - recent activity
4. Analytics
   - booking, payment, revenue, agency/user metrics
5. Agency Approval
   - pending registrations
   - agency list search/filter/sort
   - agency detail
   - approve/reject/suspend/reactivate/edit/deactivate
6. User Management
   - search/filter/sort users
   - user detail
   - edit user
   - activate/suspend/disable/delete
   - reset password
   - change role
   - transfer agency ownership
7. Room Management
   - platform room list by agency
   - room detail
   - edit room
   - archive/delete room
8. Payment / Revenue
   - payment transaction list
   - status settlement/capture/pending/cancel/deny/expire
9. Audit Log
   - timeline/list
   - search/filter/sort
   - detail perubahan
10. Settings
11. Profile / Logout

## 5. Screen Inventory

| Screen | Tujuan | Informasi | Action | Loading/Error/Empty |
|---|---|---|---|---|
| Splash | Entry point dan auth restore | Logo, app name, tagline | Auto route | Loading indicator |
| Onboarding | Edukasi awal | 3 value props | Next, Skip | Tidak ada data state |
| Welcome Auth | Pilihan auth | Brand, intro | Masuk, Daftar | Tidak ada data state |
| Login/Register | Auth user/admin agency | Email/password, full name, agency fields | Login, register, forgot password | Loading button, error message |
| Home User | Dashboard user | Greeting, search, metrics, recommended rooms | Search, notification, profile, room detail | Loading rooms, error card, empty rooms |
| Search | Cari room | Search input, filter chips, room list | Filter, open room | Loading, error, empty no result |
| Favorites | Saved rooms | Favorite room grid | Refresh, open room | Loading, custom error, empty favorite |
| Room Detail | Detail room | Image, name, city, capacity, price, facilities, schedule, bookings | Favorite, pesan, admin edit facilities/schedule, confirm/cancel booking | Loading, error card, empty facilities/schedule/bookings |
| Booking Flow | Buat booking | Date/time, details, price summary | Select date/time, continue, create booking | Room loading, error text, processing button |
| Bookings | Riwayat booking user | Filter/sort, status, date, room, price | Detail, bayar, cancel, delete | Loading, error/retry, empty |
| Booking Detail | Detail booking | Status, room, schedule, payment info | Pay/cancel/delete depending status | Loading/error states |
| Payment Method | Start Midtrans payment | Explanation, payment method badges | Bayar sekarang | Dialog loading, snackbar error |
| Midtrans WebView | Payment execution | WebView, progress | Close, continue/exit, simulate QR | Progress loading, success/fail snackbar |
| Payments | Payment history placeholder | Empty message | None | Empty placeholder |
| Notifications | Notification center | Grouped notification, unread badge | Mark read/all read | Loading, error, empty |
| Support Tickets | Help placeholder | Empty help state | None | Empty placeholder |
| Profile | Account center | User identity, role, agency, contact, app/legal info | Navigate tools, dialogs, logout | Refresh current user |
| Agency Profile | Edit agency | Name, logo URL, email, phone, address, city, description | Save changes | Loading, snackbar error/success |
| Admin Pending | Approval wait state | Agency status | Refresh, logout | Static state |
| Admin Dashboard | Agency overview | Stats, revenue, booking chart, latest rooms, quick actions | Notifications, profile, room/bookings nav | Loading/error per provider, empty rooms |
| Room Management | CRUD rooms | Search/filter, room cards, facilities, image | Add/edit/delete room, upload image | Loading, error, empty rooms |
| Booking Management | Manage bookings | Metrics, live room status, recent bookings | Reject, refund/cancel, scan QR, calendar | Loading, error, empty booking |
| Admin Calendar | Calendar booking view | Calendar/list bookings | Filter/select date | Loading/error expected |
| QR Scanner | Check-in/out scan | Camera scanner, booking validation | Scan QR, check-in/out | Camera/error feedback |
| Admin Reports | Agency report | Room metrics, capacity, rating, price range | Profile nav | Loading, error/retry |
| Admin History | Agency audit | Search/filter/sort logs, timeline | Pagination, expand detail | Loading, error/retry, empty |
| Super Admin Shell | Role dashboard shell | AppBar, tab nav | Switch tabs | IndexedStack |
| Super Admin Home | Platform overview | Stats, analytics, alerts, recent activity | Open audit | Loading, error/retry |
| Super Admin Agency | Agency governance | Pending, status, owner, contact, metrics | Approve/reject/suspend/reactivate/edit/deactivate/detail | Loading, error/retry, empty |
| Agency Detail | Detail agency | Stats, status, owner/contact/room/booking | Approve/suspend/update | Loading/error |
| Super Admin User | User governance | Role, agency, status, login, created date | Edit, activate/suspend/disable/delete/reset/change role/transfer | Loading, error, empty |
| User Detail | Detail user | User metadata | Admin actions | Loading/error |
| Super Admin Room | Platform rooms | Room, agency, capacity, rate, facilities | Detail, edit, delete | Loading, error, empty |
| Room Detail Super Admin | Room governance detail | Room metadata | Update/delete | Loading/error |
| Super Admin Payment | Payment monitoring | Amount, booking id, status, timestamp | Refresh | Loading, text error, empty |
| Super Admin Audit Log | Platform audit | Action, actor, target, changes | Search/filter/sort/pagination/expand | Loading, error/retry, empty |
| Super Admin Settings | System preferences | Toggles/settings | Toggle/save | Local UI state |
| Unauthorized | Access denied | Empty state | Back/home expected | Static |

## 6. UI Audit

### Findings

| Area | Issue | Recommendation |
|---|---|---|
| Language | Campuran Indonesia/Inggris: `Rooms`, `Booking`, `Profile`, `Add Room`, `Search bookings`. | Pilih satu tone utama. Untuk pasar Indonesia gunakan Indonesia formal: Ruangan, Pemesanan, Profil, Tambah Ruangan. |
| Theme | Banyak component masih styling lokal. | Pakai token global: color, radius, spacing, typography, button, card, input, chip, snackbar. |
| Spacing | Padding 12/16/20/24 campur tanpa skala eksplisit. | Gunakan spacing scale 4/8/12/16/20/24/32. |
| Typography | Headline/card label tidak konsisten; beberapa uppercase berlebihan. | Definisikan type role: display, page title, section title, card title, metadata, caption. |
| Color | Primary/secondary/tertiary dipakai tidak selalu semantik; `primaryContainer` dipakai sebagai accent text. | Pisahkan semantic colors: success, warning, error, info, neutral. |
| Icon | Icon style umumnya Material, tetapi beberapa emoji/garbled text muncul. | Hindari emoji dalam production UI; gunakan Material Icons konsisten. |
| Card | Radius 12/16/20/24 bercampur; shadow lokal. | Standard radius: card 16, sheet/dialog 24, chip 999; elevation halus. |
| Button | Filled/Outlined/Tonal campur tanpa priority jelas. | Primary CTA = FilledButton; secondary = Outlined; destructive = Filled/Outlined error. |
| Dialog | Dialog konfirmasi belum selalu punya severity visual. | Gunakan title + icon + clear action hierarchy. |
| Bottom Navigation | User/Admin/Super Admin label berbeda bahasa dan role. | Konsisten label pendek: Beranda, Ruangan, Booking/Pemesanan, Favorit, Profil. |
| AppBar | Beberapa action kurang jelas tanpa tooltip. | Tambahkan hierarchy: title, subtitle optional, icon action dengan tooltip. |
| Responsive | Grid memakai fixed height; beberapa Row action dapat overflow. | Gunakan breakpoints mobile/tablet, Wrap untuk action buttons, responsive grid max width. |
| Empty State | Beberapa masih hanya Text atau Card. | Setiap empty state: icon/illustration, title, description, action bila relevan. |
| Loading | Banyak `CircularProgressIndicator` polos. | Pakai skeleton/card shimmer ringan untuk list/card; loading message untuk full page. |
| Error | Error kadang text center saja. | Pakai error component dengan message, retry, dan action fallback. |

### Catatan Bug/Inconsistency yang Ditemukan

- `MidtransWebViewScreen` memiliki tombol `Simulasi Bayar QR`; ini sebaiknya tidak tampil di production.
- Beberapa string terlihat encoding rusak seperti `â€¢`, `ðŸ...`; perlu normalisasi copy sebelum desain final.
- `PaymentMethodScreen` memiliki import repository yang tidak dipakai.
- `BookingManagementScreen` search bar belum benar-benar mengubah filter list.
- `AdminNavBar` tidak memasukkan Reports/Calendar/Scanner meski route tersedia; route diakses dari action/link.
- Super Admin `PaymentTab` error/empty state masih text sederhana.

## 7. UX Audit

| Area | Finding | UX Recommendation |
|---|---|---|
| Booking | Flow dua step jelas, tetapi tidak menampilkan kalender availability secara visual di booking create. | Di Stitch, tampilkan availability hint, booked indicator, dan validation inline. |
| Payment | User diarahkan ke Midtrans setelah klik bayar, tetapi waiting/pending state belum kuat. | Tambahkan payment status screen/state: Waiting, Pending, Success, Failed dengan CTA jelas. |
| Admin Approval | Pending approval sudah ada tetapi belum memberi estimasi/proses. | Tambahkan info: agency data submitted, waiting review, contact support, refresh. |
| Admin Booking | Search bar tidak berdampak jelas. | Desain filter/search yang benar-benar terhubung: status, date, room, user. |
| Room Management | Bottom sheet form panjang. | Pecah visual menjadi sections: Basic Info, Pricing, Media, Facilities, Rules. |
| Room Detail | Tab banyak, tetapi CTA booking hanya di hero. | Sticky CTA untuk user di bawah; admin actions tetap contextual di tab. |
| Profile | Banyak placeholder legal/help. | Jadikan pages/sheets khusus dengan konten ringkas agar tidak terasa dummy. |
| Error Handling | Error belum selalu actionable. | Semua error harus punya `Coba Lagi` dan copy non-teknis. |
| Empty State | Beberapa empty state kurang memberi next step. | Tambahkan CTA: Cari Ruangan, Tambah Ruangan, Refresh, Hubungi Support. |
| Super Admin | Banyak action berisiko di popup. | Beri confirmation dialog dengan summary dan severity untuk suspend/delete/role transfer. |

## 8. Design System Recommendation

### 8.1 Color Palette

| Token | Hex | Usage |
|---|---:|---|
| Primary | `#2354C5` | CTA utama, active nav, brand mark |
| Primary Container | `#DCE7FF` | Selected state, subtle brand background |
| Secondary | `#0F766E` | Success-adjacent, confirmed status |
| Accent | `#FF8A3D` | Price highlight, key accent |
| Success | `#14804A` | Confirmed, active, paid |
| Warning | `#B7791F` | Pending, needs attention |
| Error | `#C2413D` | Rejected, failed, destructive |
| Info | `#0369A1` | System info |
| Background | `#F7F8FB` | Scaffold |
| Surface | `#FFFFFF` | Cards/sheets |
| Surface Low | `#EEF2F7` | Inputs, chips |
| Text Primary | `#151923` | Main text |
| Text Secondary | `#5D6678` | Metadata |
| Outline | `#D6DCE7` | Borders |

### 8.2 Typography

Gunakan Inter atau system sans-serif.

| Role | Size/Weight | Usage |
|---|---|---|
| Display | 32/800 | Splash/welcome hero |
| Page Title | 22/800 | AppBar/page header |
| Section Title | 18/700 | Dashboard sections |
| Card Title | 16/700 | Room/booking cards |
| Body | 14-16/400 | Description |
| Metadata | 12-13/500 | Date/status helper |
| Button | 14-16/700 | CTA |

### 8.3 Components

| Component | Recommendation |
|---|---|
| Border Radius | Card 16, input 14, button 14, dialog/sheet 24, chip/badge 999. |
| Elevation/Shadow | Minimal, soft shadow `0 8 24 rgba(21,32,51,.10)` only for elevated cards/hero. |
| Button | Filled for primary, Outlined for secondary, TextButton for low priority, destructive uses error color. |
| Card | White surface, outline border, optional light shadow; avoid nested cards. |
| Text Field | Filled white/surface low, icon prefix, helper/error text, min height 52. |
| Icon | Material Icons rounded/outlined, 20-24px default, semantic color only when needed. |
| Chip | FilterChip/ChoiceChip for filters, AssistChip for metadata, StatusChip for state. |
| Badge | Small count badges for unread notification, status badges for booking/payment/agency. |
| Snackbar | Floating, rounded, semantic color, concise copy. |
| Dialog | Icon + title + description + secondary/primary action; destructive action separated. |
| Bottom Sheet | Drag handle, sectioned content, sticky CTA for long forms. |
| Skeleton Loading | Use room card skeleton, booking row skeleton, dashboard stat skeleton. |

## 9. Branding

### 9.1 Brand Positioning

ClassRent adalah platform booking ruang kelas yang modern, tepercaya, efisien, dan profesional. Visual harus terasa seperti SaaS operasional premium: clean, tenang, jelas, tidak dekoratif berlebihan.

### 9.2 Logo Concept

Logo disarankan berupa simbol ruang/gedung sederhana dengan aksen kotak kecil sebagai representasi kelas/slot booking. Bentuk harus flat, mudah terbaca di ukuran kecil, dan cocok sebagai launcher icon.

### 9.3 App Icon

- Background primary blue.
- Foreground line/icon gedung atau ruang kelas.
- Accent orange kecil untuk menandakan booking slot/availability.
- Adaptive icon Android: background solid + foreground vector sederhana.

### 9.4 Splash Screen

- Background soft blue-to-surface atau solid surface.
- Logo centered, app name, short tagline.
- Animasi halus: fade/scale 0.9 -> 1.0, bukan pulse berlebihan.
- Loading indicator kecil.

### 9.5 Tone Visual

- Modern, clean, premium, professional.
- Dominan neutral/surface dengan primary blue sebagai fokus.
- Accent orange hanya untuk harga/highlight.
- Hindari gradient terlalu ramai, emoji, dan shadow berat.

## 10. Stitch Preparation

### Screen Brief Table

| Screen | Layout | Hierarchy | CTA | Navigasi/Data |
|---|---|---|---|---|
| Splash | Center brand stack | Logo > name > tagline > loading | Auto | Auth restore |
| Onboarding | PageView | Icon/illustration > title > copy > progress | Lanjut/Mulai, Lewati | SharedPrefs onboarding |
| Welcome Auth | Full-screen brand intro | Logo > value copy > auth card | Masuk, Daftar Baru | Push login extra |
| Login/Register | Centered form max width | Brand > title > form > error > CTA | Masuk/Daftar, Forgot Password | Auth provider |
| Home | Header + metrics + grid | Greeting/search > metrics > recommended rooms | Lihat Semua, room card | Rooms provider |
| Search | Search/filter top + list | Search > chips > room cards | Open room | Rooms provider/filter local |
| Favorites | AppBar + grid | Favorite room cards | Refresh, open room | Favorites + rooms provider |
| Room Detail | Hero + tabs | Image/name/status/price > CTA > tabs | Pesan Sekarang/Edit | Room/facility/schedule/bookings |
| Booking Flow | Stepper/progress + form | Date/time > availability > confirm summary | Lanjutkan, Buat Pesanan | Booking flow provider |
| Bookings | Filter/sort + cards | Controls > booking cards | Bayar/Cancel/Delete | Realtime booking stream |
| Booking Detail | Detail summary | Status > room/time > payment > actions | Pay/Cancel/Delete | Booking repository |
| Payment Method | Center payment intro | Icon > title > explanation > badges | Bayar Sekarang | Payment + booking repo |
| Midtrans WebView | WebView fullscreen | AppBar progress > WebView | Exit/continue | Midtrans URL |
| Notifications | Grouped list | Date header > notification card | Mark read/all read | Notifications provider |
| Profile | Account dashboard | Profile card > security > menus > contact/app/legal > logout | Logout, menu items | Current user |
| Support | Empty/help center | Icon > title > description | Contact/create ticket future | Placeholder |
| Payments | Payment history | List/status future | None/future detail | Placeholder |
| Admin Pending | Center status | Icon > status > explanation | Refresh, Logout | Auth restore |
| Admin Dashboard | Analytics feed | Stats > chart > rooms > actions | Add room/manage booking | Admin providers |
| Room Management | Search/filter + list + FAB | Controls > room cards | Add/Edit/Delete | Admin rooms provider |
| Booking Management | Metrics + status + list | Search > metrics > live rooms > recent bookings | Reject/Refund/Scan | Agency bookings |
| Admin Calendar | Calendar/list | Calendar > selected day bookings | Open booking | Agency bookings |
| QR Scanner | Camera + result | Scanner > validation result | Scan/check in/out | Booking validation |
| Reports | Metrics cards | Summary cards > explanatory note | None/Profile | Admin reports |
| History | Controls + timeline | Search/filter > audit tiles | Expand detail | Admin history |
| Super Admin Home | Dashboard | Hero > stats > charts > alerts > recent | Audit quick action | Platform providers |
| Super Admin Agency | Controls + list | Pending registrations > agency cards | Approve/reject/suspend/detail | Agencies provider |
| Agency Detail | Detail dashboard | Stats > profile > actions | Approve/suspend/edit | Agency detail |
| Super Admin User | Controls + list | User cards > action menu | Edit/reset/role/status | Users provider |
| User Detail | Detail page | Profile/status/activity | Admin actions | User detail |
| Super Admin Room | Controls + list | Room cards by agency | Detail/edit/delete | Platform rooms |
| Room Detail SA | Detail page | Room profile/facilities | Update/delete | Room detail |
| Super Admin Payment | Payment list | Amount/status/date | Refresh | Platform payments |
| Audit Log | Controls + timeline | Action > metadata > changes | Expand | Audit logs |
| Settings | Settings list | Sections/toggles | Toggle/save | Local/system settings |

## 11. UI Improvement Recommendation

| Screen/Area | Current Condition | Recommended Content for Stitch |
|---|---|---|
| Payments | Empty placeholder only | Payment history cards: amount, booking room, method, status, date, receipt CTA. Empty CTA: “Lihat Booking”. |
| Support Tickets | Empty placeholder only | Help Center with FAQ categories, contact support CTA, ticket list empty state. |
| Profile Legal | Dialog placeholder | Separate bottom sheet/page content for About, FAQ, Privacy, Terms, App Version. |
| Agency Pending | Basic status | Add submitted agency summary, review steps, expected action, support contact. |
| Super Admin Payment | Text error/empty | Use full state component and filters: status, date range, agency. |
| Favorites | Custom state | Standard empty state with CTA to Search. |
| Booking Management Search | Search not clearly applied | Add functional visual filter spec: status chips, date filter, room/user search. |
| Room Management Form | Very long sheet | Sectioned form with step anchors or grouped panels. |
| Midtrans WebView | Simulation FAB | Hide simulation in production design; show secure payment notice and pending state. |
| Admin Reports | Basic summary | Add occupancy, revenue trend, top rooms, booking conversion placeholders if backend available later. |
| Super Admin More | Internal tabs | Design “More” as segmented/tab layout: User Management and Audit Log. |
| Empty Room/Facility/Schedule | Some are text only | Add icon, title, helper text, CTA edit/add for admin. |

## 12. Final Deliverable Summary

### Primary Design Principles

1. Preserve all existing routes, role gates, and data flows.
2. Use one Material 3 design system across User, Admin Agency, and Super Admin.
3. Make operational screens dense but readable: dashboards, tables/lists, filters, status chips.
4. Every async screen must define loading, error, and empty states.
5. Every destructive/admin action must use confirmation with clear consequence.
6. Avoid decorative excess; prioritize clarity, status visibility, and trust.

### Stitch Usage Notes

- Generate designs per role separately: User app, Admin Agency console, Super Admin console.
- Keep mobile-first layout, with tablet responsive adaptations for dashboard/list pages.
- Use the sitemap and screen brief table as the required screen list.
- Do not introduce new flows such as cart, chat, coupons, or subscription unless added to product scope later.
- Preserve existing CTA naming where tied to business logic: booking, payment, approve, reject, suspend, refund, scan QR.

