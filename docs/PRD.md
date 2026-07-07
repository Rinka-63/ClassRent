# ClassRent Product Requirements Document

Status: Active source of truth
Last updated: 2026-07-07
Product: ClassRent
Platforms: Android, iOS, Web-ready Flutter

## 1. Overview

ClassRent is a room rental and booking application for classrooms, meeting rooms, studios, and similar spaces. The product connects users who need a room with agencies or facility owners who manage room inventory, schedules, approvals, payments, and operational reporting.

ClassRent supports three primary roles:

- User: searches rooms, books rooms, pays, tracks bookings, saves favorites, receives notifications, and manages profile settings.
- Agency Admin: manages agency profile, rooms, room photos, facilities, schedules, bookings, QR scanning, payments, reports, withdrawal requests, and history.
- Super Admin: supervises the platform, agencies, users, rooms, payments, withdrawals, audit logs, app settings, and approval/status actions.

## 2. Goals

- Make it easy for users to find and book available rooms with clear pricing, schedule information, and payment status.
- Give agency admins a reliable operational dashboard for managing rooms, bookings, revenue, and agency profile data.
- Give super admins enough control to approve agencies, moderate platform data, monitor activity, and keep the marketplace trustworthy.
- Keep all role-based access predictable, with navigation and screens matching the current authenticated role.
- Support Indonesian and English UI text through the app localization layer.

## 3. Non-Goals

- ClassRent is not a property management ERP.
- ClassRent is not a chat-first marketplace.
- ClassRent does not manage physical access control beyond QR/scanner-based booking verification.
- ClassRent does not replace payment provider settlement systems; it records and synchronizes payment state.

## 4. Users And Personas

### 4.1 User

Needs to quickly find a room, compare options, book a time, pay, and track booking status. Users value simple filters, trustworthy room photos, clear schedules, and notifications.

### 4.2 Agency Admin

Manages listed rooms and daily bookings. Agency admins need room CRUD, image upload, operational schedules, booking approval, booking history, reporting, and withdrawal request support.

### 4.3 Super Admin

Runs platform operations. Super admins need dashboards, agency approval, user and room moderation, payment visibility, withdrawal transfer workflow, audit logs, and app update settings.

## 5. Core User Journeys

### 5.1 User Onboarding And Authentication

1. User opens app.
2. App checks required update status.
3. User selects language if needed.
4. User views onboarding or welcome auth screen.
5. User registers as a regular user or agency admin.
6. User logs in.
7. App routes user by role and agency approval status.

Acceptance criteria:

- Unauthenticated users cannot access protected app screens.
- Authenticated users are routed to the correct home screen by role.
- Agency admins with pending approval are routed to pending approval state.
- Suspended or disabled accounts cannot continue normal app usage.

### 5.2 Browse And Search Rooms

1. User opens Home or Search.
2. User sees room recommendations and available rooms.
3. User searches by room name, city, capacity, or filters.
4. User opens room detail.

Acceptance criteria:

- Room cards show image, name, city, capacity, price, and availability signal.
- Search results update based on query and filters.
- Room detail shows overview, facilities, schedule, bookings, preview image, and room photo gallery.
- Preview image and room gallery images can be opened in zoomable image preview.

### 5.3 Booking Flow

1. User opens a room detail page.
2. User taps book.
3. User selects booking date and time.
4. System validates room schedules and existing bookings.
5. User confirms booking details.
6. Booking is created with correct status.
7. User is directed to payment when required.

Acceptance criteria:

- Booking cannot overlap active bookings for the same room.
- Booking respects minimum hours, buffer time, schedule, and approval requirement.
- Pending unpaid bookings are detected before creating duplicate bookings.
- Booking detail displays room, schedule, price, status, and payment actions.

### 5.4 Payment Flow

1. User selects a payment method.
2. App creates or loads payment data.
3. User completes payment in Midtrans WebView.
4. Payment status synchronizes back to booking.
5. User can view payment and booking status.

Acceptance criteria:

- Payment page supports the configured payment provider flow.
- Success, pending, failed, expired, and cancelled states are visible.
- Booking status follows payment status according to platform rules.

### 5.5 Profile Management

1. User opens Profile.
2. User taps Edit Profile.
3. User changes name.
4. User taps Save Profile.
5. App updates `public.users.full_name`, syncs auth metadata, refreshes current user state, closes the sheet, and shows success.

Acceptance criteria:

- Empty name is rejected.
- Saved name immediately appears in the profile header without logout or app restart.
- Pull-to-refresh reloads current profile data from Supabase.
- Existing phone and avatar values are not cleared when only editing name.

### 5.6 Favorites

1. User opens a room.
2. User toggles favorite.
3. User opens Saved Rooms.
4. Saved rooms are shown.

Acceptance criteria:

- Favorite state persists per user.
- Favorite icon reflects saved state.
- Saved Rooms only shows the current user's favorite rooms.

### 5.7 Notifications

1. User receives app notifications for booking/payment/platform events.
2. Notification badge appears in relevant navigation/profile entry.
3. User opens Notifications.
4. User can read and mark notifications.

Acceptance criteria:

- Unread counts are displayed consistently.
- Notification permission prompt is shown when needed.
- FCM token is saved for authenticated users when available.

## 6. Agency Admin Requirements

### 6.1 Agency Dashboard

Agency admins can see operational summaries: total rooms, bookings, revenue, pending actions, recent activity, and shortcuts.

### 6.2 Room Management

Agency admins can create, edit, archive, and view rooms.

Room data includes:

- Name
- Type
- City
- Address
- Capacity
- Description
- Hourly rate
- Daily rate
- Minimum hours
- Buffer minutes
- Requires approval
- Active status
- Preview image
- Detail images
- Facilities
- Operating schedules

Acceptance criteria:

- Room changes refresh the relevant room lists and detail pages.
- Room image upload stores images in configured Supabase Storage bucket.
- Room image gallery can be managed and displayed to users.

### 6.3 Booking Management

Agency admins can view, confirm, reject, cancel, and inspect bookings for their managed rooms.

Acceptance criteria:

- Agency admins only manage bookings scoped to their own agency/rooms.
- Booking status changes are persisted and visible to users.
- Calendar view highlights dates with bookings.

### 6.4 QR Scanner

Agency admins can scan booking QR codes for operational verification.

Acceptance criteria:

- Scanner validates booking payloads.
- Invalid or expired booking codes are handled gracefully.

### 6.5 Reports And Withdrawals

Agency admins can review revenue summaries and request withdrawals where enabled.

Acceptance criteria:

- Reports show useful booking and revenue summaries.
- Withdrawal requests record bank and account information.
- Withdrawal status is visible after submission.

## 7. Super Admin Requirements

### 7.1 Dashboard

Super admins can view platform-wide stats and trends for users, agencies, rooms, payments, withdrawals, and bookings.

### 7.2 Agency Moderation

Super admins can approve, reject, suspend, reactivate, soft-delete, and inspect agencies.

Acceptance criteria:

- Agency status changes are audited.
- Agency activation affects admin access and room availability according to app rules.

### 7.3 User Management

Super admins can inspect users, change role/status where allowed, reset password workflows, suspend, disable, and view audit context.

Acceptance criteria:

- Super admins cannot accidentally perform unsafe self-targeting actions where prohibited.
- User status changes are reflected in authentication routing.

### 7.4 Room Moderation

Super admins can inspect rooms across agencies and suspend/reactivate/archive rooms.

### 7.5 Payment And Withdrawal Oversight

Super admins can view platform payments and process agency withdrawal transfers.

### 7.6 Audit Logs

Super admins can view audit log entries with actor, action, entity, timestamp, and contextual labels.

### 7.7 Platform Settings

Super admins can manage settings such as app update requirement and operational configuration.

## 8. Data Model Summary

Primary tables:

- `users`: authenticated user profile, role, account status, phone, avatar, FCM token.
- `agencies`: agency profile, admin ownership, approval status, active status.
- `rooms`: room inventory and pricing.
- `room_facilities`: room facility tags.
- `room_images`: detail photo gallery.
- `bookings`: room reservations and lifecycle status.
- `payments`: payment records and provider status.
- `notifications`: user notifications.
- `favorite_rooms` or configured favorites table: saved room relationships.
- `agency_withdrawals`: agency withdrawal requests.
- `audit_logs`: platform and admin action history.
- `system_settings`: platform configuration.

## 9. Permissions And Security

- All protected data access requires authenticated Supabase session.
- Role-aware routing gates user, agency admin, and super admin screens.
- Row Level Security should scope users to their own data, agency admins to their agency data, and super admins to platform-wide data.
- Profile name updates use `update_own_profile` RPC to avoid legacy role casing policy conflicts and to keep auth metadata synchronized.
- Sensitive status changes must be audited.
- Soft delete/anonymization should preserve booking/payment records while protecting personal data.

## 10. Localization

The app supports Indonesian and English through `AppStrings`.

Requirements:

- User-facing labels, empty states, errors, and action text should use localization helpers.
- Language selection persists locally.
- New features must add both Indonesian and English strings.

## 11. Notifications

Notification channels:

- Booking created/updated/cancelled.
- Payment pending/success/failed/expired.
- Agency approval/status changes.
- Withdrawal status updates.
- Platform announcements where needed.

Requirements:

- Save FCM token for authenticated users.
- Keep unread counts accurate.
- Allow marking notifications as read.

## 12. Analytics And Reporting

Core reporting needs:

- Booking count by period.
- Revenue by period.
- Room utilization.
- Agency performance.
- Payment status distribution.
- Withdrawal request status.
- Recent platform activity.

## 13. Technical Architecture

- Frontend: Flutter.
- State management: Riverpod.
- Routing: GoRouter.
- Backend: Supabase Auth, Postgres, RLS, RPC, Storage, Edge Functions.
- Payments: Midtrans integration through app service and WebView.
- Notifications: Firebase Messaging and local notifications.
- Media: Supabase Storage buckets for room and profile images.

## 14. Quality Requirements

- Profile update must reflect immediately after save.
- Booking validation must avoid double-booking.
- Room image previews must be zoomable from preview and gallery.
- Admin actions must not expose cross-agency data.
- Super admin actions must be audited.
- App must handle network/API failures with user-friendly messages.
- Flutter analyze should remain free of new errors when changing code.

## 15. Release Readiness Checklist

- Authentication and role routing verified.
- User profile edit verified against real Supabase environment.
- Room search, detail, gallery zoom, and booking flow verified.
- Payment status synchronization verified.
- Agency admin room and booking management verified.
- Super admin agency/user/room/payment/withdrawal flows verified.
- Notifications and unread badge verified.
- RLS/RPC migrations applied in target Supabase project.
- App version/update requirement configured.

## 16. Open Decisions

- Final cancellation/refund policy.
- Exact withdrawal SLA and transfer proof requirements.
- Whether room availability should support recurring exceptions and holidays.
- Whether reviews are user-visible in the first production release.
- Whether web deployment is production-supported or internal only.
