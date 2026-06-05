-- Admin CRUD refinements for room facilities, booking status, and audit logging.

alter table public.room_facilities
  add column if not exists facility_id uuid references public.facilities(id) on delete cascade;

create index if not exists idx_room_facilities_facility_id
  on public.room_facilities(facility_id);

drop policy if exists audit_admin_insert on public.audit_logs;
create policy audit_admin_insert on public.audit_logs
for insert with check (
  actor_id = auth.uid()
  and public.is_admin_or_super_admin()
);

alter table public.bookings
  drop constraint if exists bookings_status_check;

alter table public.bookings
  add constraint bookings_status_check check (
    status in (
      'draft',
      'pending',
      'approved',
      'pending_approval',
      'pending_payment',
      'pending_checkin',
      'confirmed',
      'checked_in',
      'checked_out',
      'completed',
      'cancelled',
      'rejected',
      'no_show',
      'expired',
      'refunded'
    )
  );
