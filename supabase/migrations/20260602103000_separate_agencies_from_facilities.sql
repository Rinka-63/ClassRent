-- Agency approval now uses a dedicated agencies table.
-- Facilities remain room/facility records only.

create table if not exists public.agencies (
  id uuid primary key default gen_random_uuid(),
  admin_id uuid not null references public.users(id) on delete cascade,
  name text not null,
  slug text not null unique,
  email text,
  phone text,
  address text,
  city text,
  description text,
  approval_status text not null default 'pending'
    check (approval_status in ('pending','approved','rejected')),
  is_active boolean not null default false,
  approved_at timestamptz,
  rejected_at timestamptz,
  reviewed_by uuid references public.users(id),
  rejection_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists idx_agencies_admin_id
  on public.agencies(admin_id);

create index if not exists idx_agencies_status
  on public.agencies(approval_status, is_active);

drop trigger if exists agencies_set_updated_at on public.agencies;
create trigger agencies_set_updated_at
before update on public.agencies
for each row execute function public.set_updated_at();

create table if not exists public.agency_staff (
  agency_id uuid not null references public.agencies(id) on delete cascade,
  staff_id uuid not null references public.users(id) on delete cascade,
  assigned_by uuid references public.users(id),
  created_at timestamptz not null default now(),
  primary key (agency_id, staff_id)
);

create index if not exists idx_agency_staff_staff_id
  on public.agency_staff(staff_id);

alter table public.agencies enable row level security;
alter table public.agency_staff enable row level security;

create or replace function public.current_user_agency_id()
returns uuid language sql stable security definer set search_path = public as $$
  select coalesce(
    (select a.id from public.agencies a where a.admin_id = auth.uid() limit 1),
    (select ast.agency_id from public.agency_staff ast where ast.staff_id = auth.uid() limit 1)
  )
$$;

create or replace function public.owns_agency(target_agency_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1
    from public.agencies a
    where a.id = target_agency_id
      and a.admin_id = auth.uid()
      and a.approval_status = 'approved'
      and a.is_active = true
  ) or public.is_super_admin()
$$;

create or replace function public.works_for_agency(target_agency_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1
    from public.agency_staff ast
    join public.agencies a on a.id = ast.agency_id
    where ast.agency_id = target_agency_id
      and ast.staff_id = auth.uid()
      and a.approval_status = 'approved'
      and a.is_active = true
  ) or public.is_super_admin()
$$;

create or replace function public.owns_facility(target_facility_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1
    from public.facilities f
    join public.agencies a on a.admin_id = f.admin_id
    where f.id = target_facility_id
      and f.admin_id = auth.uid()
      and a.approval_status = 'approved'
      and a.is_active = true
  ) or public.is_super_admin()
$$;

create or replace function public.can_manage_room(target_room_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1
    from public.rooms r
    where r.id = target_room_id
      and public.owns_facility(r.facility_id)
  ) or exists (
    select 1
    from public.rooms r
    join public.facilities f on f.id = r.facility_id
    join public.agency_staff ast on ast.agency_id = public.current_user_agency_id()
    join public.agencies a on a.id = ast.agency_id
    where r.id = target_room_id
      and ast.staff_id = auth.uid()
      and f.admin_id = a.admin_id
      and a.approval_status = 'approved'
      and a.is_active = true
  ) or public.is_super_admin()
$$;

create or replace function public.register_agency_admin_profile(
  p_full_name text,
  p_agency_name text
)
returns uuid language plpgsql security definer set search_path = public as $$
declare
  current_user_id uuid := auth.uid();
  current_email text;
  normalized_full_name text := nullif(trim(coalesce(p_full_name, '')), '');
  normalized_agency_name text := nullif(trim(coalesce(p_agency_name, '')), '');
  agency_id uuid;
  base_slug text;
  agency_slug text;
begin
  if current_user_id is null then
    raise exception 'Not authenticated';
  end if;

  select email into current_email
  from auth.users
  where id = current_user_id;

  normalized_full_name := coalesce(normalized_full_name, current_email, 'Agency Admin');
  normalized_agency_name := coalesce(normalized_agency_name, normalized_full_name || ' Agency');
  base_slug := public.slugify(normalized_agency_name);
  agency_slug := base_slug || '-' || left(current_user_id::text, 8);

  insert into public.users (id, email, full_name, role)
  values (
    current_user_id,
    coalesce(current_email, ''),
    normalized_full_name,
    'admin'
  )
  on conflict (id) do update
    set email = excluded.email,
        full_name = excluded.full_name,
        role = 'admin',
        updated_at = now()
  where public.users.role in ('user','admin');

  insert into public.agencies (admin_id, name, slug, approval_status, is_active)
  values (current_user_id, normalized_agency_name, agency_slug, 'pending', false)
  on conflict (admin_id) do update
    set name = excluded.name,
        slug = excluded.slug,
        updated_at = now()
    where public.agencies.approval_status = 'pending'
  returning id into agency_id;

  if agency_id is null then
    select id into agency_id
    from public.agencies
    where admin_id = current_user_id
    limit 1;
  end if;

  perform public.sync_auth_user_metadata(current_user_id);

  return agency_id;
end;
$$;

grant execute on function public.register_agency_admin_profile(text, text)
to authenticated;

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  registration_type text := new.raw_user_meta_data->>'registration_type';
  requested_role text := new.raw_app_meta_data->>'role';
  resolved_role text;
  full_name text := coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1), 'ClassRent User');
  agency_name text := nullif(trim(coalesce(new.raw_user_meta_data->>'agency_name', '')), '');
begin
  resolved_role := case
    when requested_role = 'super_admin' then 'super_admin'
    when requested_role = 'staff' then 'staff'
    when registration_type = 'agency_admin' then 'admin'
    else 'user'
  end;

  insert into public.users (id, email, full_name, role)
  values (new.id, coalesce(new.email, ''), full_name, resolved_role)
  on conflict (id) do update
    set email = excluded.email,
        full_name = excluded.full_name,
        role = excluded.role,
        updated_at = now();

  if registration_type = 'agency_admin' then
    insert into public.agencies (admin_id, name, slug, approval_status, is_active)
    values (
      new.id,
      coalesce(agency_name, full_name || ' Agency'),
      public.slugify(coalesce(agency_name, full_name || ' Agency')) || '-' || left(new.id::text, 8),
      'pending',
      false
    )
    on conflict (admin_id) do nothing;
  end if;

  return new;
end;
$$;

create or replace function public.sync_auth_user_metadata(target_user_id uuid)
returns void language plpgsql security definer set search_path = public as $$
declare
  profile_role text;
  agency_id uuid;
  agency_status text;
  agency_is_active boolean;
begin
  select role into profile_role
  from public.users
  where id = target_user_id;

  if profile_role is null then
    return;
  end if;

  if profile_role = 'admin' then
    select id, approval_status, is_active
    into agency_id, agency_status, agency_is_active
    from public.agencies
    where admin_id = target_user_id
    limit 1;
  elsif profile_role = 'staff' then
    select a.id, a.approval_status, a.is_active
    into agency_id, agency_status, agency_is_active
    from public.agency_staff ast
    join public.agencies a on a.id = ast.agency_id
    where ast.staff_id = target_user_id
    limit 1;
  end if;

  update auth.users
  set raw_app_meta_data = coalesce(raw_app_meta_data, '{}'::jsonb)
    || jsonb_build_object(
      'role', profile_role,
      'agency_id', agency_id,
      'agency_status', agency_status,
      'agency_is_active', agency_is_active
    )
  where id = target_user_id;
end;
$$;

create or replace function public.sync_auth_user_metadata_trigger()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'DELETE' then
    perform public.sync_auth_user_metadata(old.id);
    return old;
  end if;

  perform public.sync_auth_user_metadata(new.id);
  return new;
end;
$$;

create or replace function public.sync_auth_user_metadata_from_agency()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'DELETE' then
    perform public.sync_auth_user_metadata(old.admin_id);
    return old;
  end if;

  perform public.sync_auth_user_metadata(new.admin_id);
  return new;
end;
$$;

create or replace function public.sync_auth_user_metadata_from_agency_staff()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'DELETE' then
    perform public.sync_auth_user_metadata(old.staff_id);
    return old;
  end if;

  perform public.sync_auth_user_metadata(new.staff_id);
  return new;
end;
$$;

drop trigger if exists agencies_sync_auth_metadata on public.agencies;
create trigger agencies_sync_auth_metadata
after insert or update of admin_id, approval_status, is_active on public.agencies
for each row execute function public.sync_auth_user_metadata_from_agency();

drop trigger if exists agency_staff_sync_auth_metadata on public.agency_staff;
create trigger agency_staff_sync_auth_metadata
after insert or update or delete on public.agency_staff
for each row execute function public.sync_auth_user_metadata_from_agency_staff();

drop trigger if exists facilities_sync_auth_metadata on public.facilities;
drop trigger if exists staff_agency_sync_auth_metadata on public.staff_agency_assignments;

insert into public.agencies (admin_id, name, slug, approval_status, is_active)
select
  u.id,
  coalesce(
    nullif(trim(au.raw_user_meta_data->>'agency_name'), ''),
    u.full_name || ' Agency'
  ) as name,
  public.slugify(
    coalesce(
      nullif(trim(au.raw_user_meta_data->>'agency_name'), ''),
      u.full_name || ' Agency'
    )
  ) || '-' || left(u.id::text, 8) as slug,
  'pending',
  false
from public.users u
left join auth.users au on au.id = u.id
where u.role = 'admin'
  and not exists (
    select 1 from public.agencies a where a.admin_id = u.id
  );

do $$
declare
  profile_record record;
begin
  for profile_record in select id from public.users loop
    perform public.sync_auth_user_metadata(profile_record.id);
  end loop;
end;
$$;

drop policy if exists agencies_select_scoped on public.agencies;
create policy agencies_select_scoped on public.agencies
for select using (
  public.is_super_admin()
  or admin_id = auth.uid()
  or exists (
    select 1 from public.agency_staff ast
    where ast.agency_id = agencies.id and ast.staff_id = auth.uid()
  )
);

drop policy if exists agencies_super_admin_update on public.agencies;
create policy agencies_super_admin_update on public.agencies
for update using (public.is_super_admin())
with check (public.is_super_admin());

drop policy if exists agencies_super_admin_delete on public.agencies;
create policy agencies_super_admin_delete on public.agencies
for delete using (public.is_super_admin());

drop policy if exists agency_staff_select_scoped on public.agency_staff;
create policy agency_staff_select_scoped on public.agency_staff
for select using (
  public.is_super_admin()
  or staff_id = auth.uid()
  or public.owns_agency(agency_id)
);

drop policy if exists agency_staff_manage_admin on public.agency_staff;
create policy agency_staff_manage_admin on public.agency_staff
for all using (public.is_super_admin() or public.owns_agency(agency_id))
with check (public.is_super_admin() or public.owns_agency(agency_id));

drop policy if exists users_select_own_or_admin on public.users;
create policy users_select_own_or_admin on public.users
for select using (
  id = auth.uid()
  or public.is_super_admin()
  or exists (
    select 1
    from public.agencies a
    left join public.agency_staff ast on ast.agency_id = a.id
    where a.admin_id = auth.uid()
      and a.approval_status = 'approved'
      and a.is_active = true
      and (users.id = a.admin_id or users.id = ast.staff_id)
  )
);

drop policy if exists facilities_public_read_active on public.facilities;
create policy facilities_public_read_active on public.facilities
for select using (
  is_active = true
  or public.owns_facility(id)
  or public.is_super_admin()
);
