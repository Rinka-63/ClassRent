# ClassRent PRD and Current Progress

## Product Summary

ClassRent is a Flutter + Supabase room booking platform for Indonesia that supports three production roles:

- `SUPER_ADMIN`
- `ADMIN`
- `USER`

The project is currently aligned to the three-role architecture. The old `staff` role has been removed from the active Flutter app and the latest cleanup migration.

## Product Goal

Build a scalable semester-project-friendly booking platform where:

- Users can register, browse rooms, and book them.
- Agency admins can register their agency, wait for approval, and then manage agency operations.
- Super admins can approve agencies and oversee the platform.

## Current Architecture

- Flutter
- Riverpod
- GoRouter
- Supabase Auth
- Supabase PostgreSQL
- Clean Architecture inspired structure

## Role Model

### SUPER_ADMIN

- Created manually in the database.
- Cannot register from the app.
- Has full access to all agencies and platform data.

### ADMIN

- Registers through the app as an agency.
- Agency row is created automatically.
- Agency status starts as `pending`.
- Cannot access operational admin area until approved.
- After approval, can use the agency dashboard.

### USER

- Registers normally.
- Gets immediate access after signup.
- Can browse and book rooms.

## What Is Done Now

### Authentication

- Email/password login works.
- Email/password registration works.
- Session restore works.
- Logout works.
- Role-based redirect is active.
- Admin pending approval redirect is active.

### Database

- Agency data now uses a dedicated `agencies` table.
- Staff-related runtime flow has been removed from the active app.
- A cleanup migration exists to normalize roles and remove staff tables.

### Super Admin

- Super Admin dashboard exists.
- Agencies can be reviewed from the dashboard.
- Approve/reject and activate/deactivate actions are available.
- Platform summary cards are available.
- Logout is available.

### Admin Agency

- Admin dashboard now acts as the agency control center.
- Dashboard includes:
  - agency status panel
  - quick actions for rooms, bookings, payments, support, notifications, and profile
  - platform summary cards
  - operations checklist
  - logout button
- Room management screen is now a real operational entry point.
- Booking management screen is now a real operational entry point.

### User Experience

- Role-aware navigation is in place.
- Shared navigation exists for user-facing modules.
- Existing UI language is preserved so the app feels consistent across roles.

## What Has Been Removed

- Active `staff` role from Flutter runtime
- Staff dashboard route
- Create staff screen
- Create staff Edge Function
- Staff-specific navigation
- Staff-specific repository API

## Current Progress Estimate

### Overall

The project is now about **70% complete** for the current semester-project scope.

### By Area

- Authentication and routing: 90%
- Super admin module: 85%
- Admin agency dashboard: 80%
- User browsing foundation: 50%
- Booking engine: 25%
- Payments: 15%
- Reviews: 10%
- Notifications: 20%
- Support tickets: 20%
- Database cleanup and role normalization: 80%

## Immediate Next Steps

1. Apply the latest migrations to the active Supabase database.
2. Verify that the remote migration history matches the cleaned local migration set.
3. Test register flow for `USER` and `ADMIN`.
4. Test approval flow from Super Admin to Admin dashboard.
5. Build the next layer of admin features:
   - room CRUD
   - booking review/approval
   - payment list and status
   - support inbox
   - review moderation

## Remaining Risk

- Remote Supabase migration history must be reconciled after staff cleanup.
- Some admin screens are now operational shells and still need business logic wiring to real data.
- Payment, reviews, and support are still mostly foundation-level.

## Success Criteria For This Stage

- App compiles without analyzer errors.
- Login and logout work.
- Admin agency can reach the dashboard after approval.
- Super admin sees pending agency registrations.
- No active Flutter route depends on the removed `staff` role.

