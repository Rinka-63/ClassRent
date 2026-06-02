-- ClassRent agency approval and role architecture revision.
-- Safe migration: only adds columns/functions/policies and replaces helper logic.

alter table public.facilities
  add column if not exists approval_status text not null default 'approved'
    check (approval_status in ('pending','approved','rejected')),
  add column if not exists approved_at timestamptz,
  add column if not exists rejected_at timestamptz,
  add column if not exists reviewed_by uuid references public.users(id),
  add column if not exists rejection_reason text;

create index if not exists idx_facilities_approval_status
  on public.facilities(approval_status, is_active);

create table if not exists public.staff_agency_assignments (
  staff_id uuid not null references public.users(id) on delete cascade,
  facility_id uuid not null references public.facilities(id) on delete cascade,
  assigned_by uuid references public.users(id),
  created_at timestamptz not null default now(),
  primary key (staff_id, facility_id)
);

alter table public.staff_agency_assignments enable row level security;

update public.facilities
set approval_status = 'approved',
    approved_at = coalesce(approved_at, created_at)
where approval_status is null;

create or replace function public.slugify(value text)
returns text language sql immutable as $$
  select trim(both '-' from regexp_replace(lower(coalesce(value, 'agency')), '[^a-z0-9]+', '-', 'g'))
$$;

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  registration_type text := coalesce(new.raw_user_meta_data->>'registration_type', 'user');
  profile_role text := case when registration_type = 'agency_admin' then 'admin' else 'user' end;
  profile_name text := coalesce(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name', new.email);
  agency_name text := coalesce(new.raw_user_meta_data->>'agency_name', profile_name || ' Agency');
  agency_slug text;
begin
  -- Staff and super_admin accounts are never created by public app registration.
  insert into public.users (id, email, full_name, avatar_url, role)
  values (
    new.id,
    new.email,
    profile_name,
    new.raw_user_meta_data->>'avatar_url',
    profile_role
  )
  on conflict (id) do update
    set email = excluded.email,
        full_name = excluded.full_name,
        avatar_url = excluded.avatar_url,
        role = public.users.role;

  if registration_type = 'agency_admin' then
    agency_slug := public.slugify(agency_name) || '-' || left(new.id::text, 8);

    insert into public.facilities (
      admin_id,
      name,
      slug,
      approval_status,
      is_active
    )
    values (
      new.id,
      agency_name,
      agency_slug,
      'pending',
      false
    )
    on conflict (slug) do nothing;
  end if;

  return new;
end;
$$;

create or replace function public.owns_any_facility(target_facility_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.facilities f
    where f.id = target_facility_id and f.admin_id = auth.uid()
  ) or public.is_super_admin()
$$;

create or replace function public.owns_facility(target_facility_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.facilities f
    where f.id = target_facility_id
      and f.admin_id = auth.uid()
      and f.approval_status = 'approved'
      and f.is_active = true
  ) or public.is_super_admin()
$$;

create or replace function public.current_user_facility_id()
returns uuid language sql stable security definer set search_path = public as $$
  select coalesce(
    (select f.id from public.facilities f where f.admin_id = auth.uid() limit 1),
    (select sa.facility_id from public.staff_agency_assignments sa where sa.staff_id = auth.uid() limit 1),
    (select s.facility_id from public.staff_room_assignments s where s.staff_id = auth.uid() limit 1)
  )
$$;

create or replace function public.is_staff_for_facility(target_facility_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1
    from public.staff_agency_assignments s
    join public.users u on u.id = s.staff_id
    join public.facilities f on f.id = s.facility_id
    where s.facility_id = target_facility_id
      and s.staff_id = auth.uid()
      and u.role = 'staff'
      and f.approval_status = 'approved'
      and f.is_active = true
  ) or public.owns_facility(target_facility_id)
$$;

create or replace function public.is_assigned_staff_for_room(target_room_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1
    from public.rooms r
    join public.staff_agency_assignments s on s.facility_id = r.facility_id
    join public.users u on u.id = s.staff_id
    join public.facilities f on f.id = s.facility_id
    where r.id = target_room_id
      and s.staff_id = auth.uid()
      and u.role = 'staff'
      and f.approval_status = 'approved'
      and f.is_active = true
  )
  or exists (
    select 1
    from public.staff_room_assignments s
    join public.users u on u.id = s.staff_id
    where s.room_id = target_room_id
      and s.staff_id = auth.uid()
      and u.role = 'staff'
  )
  or public.can_manage_room(target_room_id)
$$;

drop policy if exists facilities_public_read_active on public.facilities;
drop policy if exists facilities_admin_insert on public.facilities;
drop policy if exists facilities_admin_update on public.facilities;
drop policy if exists facilities_admin_delete on public.facilities;

create policy facilities_public_read_active on public.facilities
  for select using (
    public.is_super_admin()
    or admin_id = auth.uid()
    or (is_active = true and approval_status = 'approved')
  );

create policy facilities_admin_insert on public.facilities
  for insert with check (
    (admin_id = auth.uid() and public.current_user_role() = 'admin')
    or public.is_super_admin()
  );

create policy facilities_admin_update on public.facilities
  for update using (
    public.is_super_admin()
    or (admin_id = auth.uid() and approval_status = 'approved' and is_active = true)
  )
  with check (
    public.is_super_admin()
    or (admin_id = auth.uid() and approval_status = 'approved' and is_active = true)
  );

create policy facilities_admin_delete on public.facilities
  for delete using (public.is_super_admin());

drop policy if exists staff_assignments_admin_read on public.staff_room_assignments;
drop policy if exists staff_assignments_admin_manage on public.staff_room_assignments;

create policy staff_assignments_admin_read on public.staff_room_assignments
  for select using (
    staff_id = auth.uid()
    or public.owns_facility(facility_id)
    or public.is_super_admin()
  );

create policy staff_assignments_admin_manage on public.staff_room_assignments
  for all using (public.owns_facility(facility_id) or public.is_super_admin())
  with check (public.owns_facility(facility_id) or public.is_super_admin());

drop policy if exists staff_agency_assignments_read on public.staff_agency_assignments;
drop policy if exists staff_agency_assignments_manage on public.staff_agency_assignments;

create policy staff_agency_assignments_read on public.staff_agency_assignments
  for select using (
    staff_id = auth.uid()
    or public.owns_facility(facility_id)
    or public.is_super_admin()
  );

create policy staff_agency_assignments_manage on public.staff_agency_assignments
  for all using (public.owns_facility(facility_id) or public.is_super_admin())
  with check (public.owns_facility(facility_id) or public.is_super_admin());

create index if not exists idx_staff_agency_assignments_facility
  on public.staff_agency_assignments(facility_id, staff_id);

drop policy if exists users_select_own_or_admin on public.users;

create policy users_select_scoped on public.users
  for select using (
    id = auth.uid()
    or public.is_super_admin()
    or exists (
      select 1
      from public.staff_agency_assignments sa
      where sa.staff_id = public.users.id
        and public.owns_facility(sa.facility_id)
    )
  );

-- Service-role Edge Function contract for create-staff:
-- 1. Verify caller role is admin and owns approved active facility.
-- 2. Create auth user with email/password using service role.
-- 3. Insert users row role='staff'.
-- 4. Insert staff_agency_assignments row for the facility.
-- 5. Optionally insert staff_room_assignments rows for room-level scope.
