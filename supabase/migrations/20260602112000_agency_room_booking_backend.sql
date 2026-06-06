-- Enable admin agency room CRUD and agency-scoped booking access.

create or replace function public.can_manage_room(target_room_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1
    from public.rooms r
    join public.agencies a on a.admin_id = r.admin_id
    where r.id = target_room_id
      and r.admin_id = auth.uid()
      and a.approval_status = 'approved'
      and a.is_active = true
  ) or public.is_super_admin()
$$;

drop policy if exists rooms_admin_insert on public.rooms;
create policy rooms_admin_insert on public.rooms
for insert with check (
  admin_id = auth.uid()
  and exists (
    select 1
    from public.agencies a
    where a.admin_id = auth.uid()
      and a.approval_status = 'approved'
      and a.is_active = true
  )
);

drop policy if exists bookings_user_select on public.bookings;
create policy bookings_user_select on public.bookings
for select using (
  user_id = auth.uid()
  or public.can_manage_room(room_id)
);

drop policy if exists bookings_staff_admin_update on public.bookings;
create policy bookings_staff_admin_update on public.bookings
for update using (
  public.can_manage_room(room_id)
) with check (
  public.can_manage_room(room_id)
);

drop policy if exists bookings_user_update_cancel on public.bookings;
create policy bookings_user_update_cancel on public.bookings
for update using (
  user_id = auth.uid()
  and status in ('draft','pending_approval','pending_payment','confirmed','pending_checkin')
) with check (
  user_id = auth.uid()
);

drop policy if exists bookings_user_insert on public.bookings;
create policy bookings_user_insert on public.bookings
for insert with check (
  user_id = auth.uid()
);

drop policy if exists facilities_admin_insert on public.facilities;
create policy facilities_admin_insert on public.facilities
for insert with check (
  admin_id = auth.uid()
  or public.is_super_admin()
);

