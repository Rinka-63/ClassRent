-- Final role model: SUPER_ADMIN, ADMIN, USER.
-- This migration replaces staff-era functions and removes staff tables when present.

update public.users
set role = case
  when role = 'staff' then 'USER'
  when role = 'admin' then 'ADMIN'
  when role = 'super_admin' then 'SUPER_ADMIN'
  when role = 'user' then 'USER'
  else role
end
where role in ('staff', 'admin', 'super_admin', 'user');

do $$
begin
  alter table public.users drop constraint if exists users_role_check;
exception
  when undefined_object then null;
end
$$;

alter table public.users
  add constraint users_role_check
  check (role in ('SUPER_ADMIN', 'ADMIN', 'USER'));

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
    when requested_role in ('SUPER_ADMIN', 'super_admin') then 'SUPER_ADMIN'
    when registration_type = 'agency_admin' then 'ADMIN'
    else 'USER'
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

  if profile_role = 'ADMIN' then
    select id, approval_status, is_active
    into agency_id, agency_status, agency_is_active
    from public.agencies
    where admin_id = target_user_id
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

drop function if exists public.current_user_agency_id();
drop function if exists public.works_for_agency(uuid);
drop function if exists public.sync_auth_user_metadata_from_agency_staff();

drop policy if exists agency_staff_select_scoped on public.agency_staff;
drop policy if exists agency_staff_manage_admin on public.agency_staff;
drop policy if exists agencies_select_scoped on public.agencies;
drop policy if exists users_select_own_or_admin on public.users;

do $$
begin
  if exists (
    select 1 from pg_trigger where tgname = 'agency_staff_sync_auth_metadata'
  ) then
    drop trigger agency_staff_sync_auth_metadata on public.agency_staff;
  end if;
exception
  when undefined_table then null;
end
$$;

drop table if exists public.agency_staff;
drop table if exists public.staff_agency_assignments;
drop table if exists public.staff_room_assignments;

do $$
begin
  revoke execute on function public.register_agency_admin_profile(text, text) from authenticated;
exception
  when undefined_function then null;
end
$$;

grant execute on function public.register_agency_admin_profile(text, text)
to authenticated;

drop policy if exists agencies_select_scoped on public.agencies;
create policy agencies_select_scoped on public.agencies
for select using (
  public.is_super_admin()
  or admin_id = auth.uid()
);

drop policy if exists users_select_own_or_admin on public.users;
create policy users_select_own_or_admin on public.users
for select using (
  id = auth.uid()
  or public.is_super_admin()
);
