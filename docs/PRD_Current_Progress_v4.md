# ClassRent PRD Progress Update

## Current Product Direction

The active product direction is now:

- `SUPER_ADMIN` approves agencies and oversees the platform.
- `ADMIN` manages only the agency they own.
- `USER` uses the booking app as a tenant.

The removed `staff` role is no longer part of the active Flutter runtime.

## Admin Scope

The admin experience has been narrowed to match the intended flow:

- The admin dashboard shows only the room list of the admin's own agency.
- Other admin capabilities are moved into separate menus and pages.
- Logout is kept in the profile page.
- Reports and history are available as separate admin pages.

## Admin Features Now Implemented

- Agency room list dashboard
- Room detail access from the dashboard list
- Menu entries for room management, booking management, reports, and history
- Automatic room-based report summary
- Audit log based history screen

## Report Module

The reports page currently summarizes the admin's room inventory using live data:

- total rooms
- active rooms
- rooms requiring approval
- total capacity
- average room rating
- hourly price range

This is a real data-driven foundation that can later be extended to:

- booking funnel
- revenue
- occupancy
- cancellations
- payment success rate

## History Module

The history page uses `audit_logs` as the source of truth and shows:

- action name
- entity type
- entity id
- timestamp

This gives the admin a practical activity trail without depending on fake sample data.

## Progress Status

### Already done

- Role model cleaned to 3 roles
- Staff role removed from runtime
- Super admin module available
- Admin dashboard refactored into room-list dashboard
- Reports page added
- History page added
- Logout remains on profile
- Flutter analyzer is clean

### Still in progress

- Full room CRUD
- Facilities CRUD within room management
- Schedule management UI and wiring
- Booking approval workflow
- Payment integration
- Review moderation
- Support ticket operational flow

## Estimated Completion

- Foundation and architecture: 90%
- Authentication and routing: 90%
- Super admin flow: 85%
- Admin dashboard and menu structure: 80%
- Reports and history: 60%
- Room CRUD and schedule management: 30%
- Booking system: 25%
- Payments: 15%
- Reviews and support: 20%

Overall progress: around **65-70%**

## Verification Status

- `flutter analyze` passes with no issues.
- The admin dashboard no longer acts as a platform-wide control center.
- The dashboard now focuses on the admin's own room list.
- Reports and history are separated from the dashboard and accessible from menu actions.

