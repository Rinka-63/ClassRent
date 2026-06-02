-- Keep Supabase Authentication Users metadata in sync with public table-editor data.
-- This makes role/agency visible in Authentication > Users while public.users remains
-- the source of truth for RLS and app authorization.

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  registration_type text := coalesce(new.raw_user_meta_data->>'registration_type', 'user');
  auth_role text := new.raw_app_meta_data->>'role';
  profile_role text := case
    when auth_role in ('user','staff','admin','super_admin') then auth_role
    when registration_type = 'agency_admin' then 'admin'
    else 'user'
  end;
  profile_name text := coalesce(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name', new.email);
  agency_name text := coalesce(new.raw_user_meta_data->>'agency_name', profile_name || ' Agency');
  agency_slug text;
begin
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
        role = case
          when public.users.role = excluded.role then public.users.role
          when excluded.role in ('staff','admin','super_admin') then excluded.role
          else public.users.role
        end;

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

create or replace function public.user_agency_metadata(target_user_id uuid)
returns jsonb language sql stable security definer set search_path = public as $$
  with profile as (
    select id, role
    from public.users
    where id = target_user_id
  ),
  admin_facility as (
    select f.id, f.approval_status, f.is_active
    from public.facilities f
    where f.admin_id = target_user_id
    order by f.created_at asc
    limit 1
  ),
  staff_facility as (
    select f.id, f.approval_status, f.is_active
    from public.staff_agency_assignments sa
    join public.facilities f on f.id = sa.facility_id
    where sa.staff_id = target_user_id
    order by sa.created_at asc
    limit 1
  ),
  resolved as (
    select
      p.role,
      coalesce(af.id, sf.id) as agency_id,
      coalesce(af.approval_status, sf.approval_status) as agency_status,
      coalesce(af.is_active, sf.is_active) as agency_is_active
    from profile p
    left join admin_facility af on true
    left join staff_facility sf on true
  )
  select jsonb_strip_nulls(
    jsonb_build_object(
      'role', role,
      'agency_id', agency_id,
      'agency_status', agency_status,
      'agency_is_active', agency_is_active
    )
  )
  from resolved
$$;

create or replace function public.sync_auth_user_metadata(target_user_id uuid)
returns void language plpgsql security definer set search_path = public as $$
declare
  metadata jsonb;
begin
  select public.user_agency_metadata(target_user_id) into metadata;

  if metadata is null then
    return;
  end if;

  update auth.users
  set raw_app_meta_data =
        coalesce(raw_app_meta_data, '{}'::jsonb)
        || metadata
        || jsonb_build_object('provider', coalesce(raw_app_meta_data->>'provider', 'email')),
      raw_user_meta_data =
        coalesce(raw_user_meta_data, '{}'::jsonb)
        || jsonb_strip_nulls(jsonb_build_object(
          'full_name', (select full_name from public.users where id = target_user_id)
        ))
  where id = target_user_id;
end;
$$;

create or replace function public.sync_auth_user_metadata_trigger()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  perform public.sync_auth_user_metadata(coalesce(new.id, old.id));
  return coalesce(new, old);
end;
$$;

create or replace function public.sync_facility_auth_metadata_trigger()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  staff_id_record record;
begin
  perform public.sync_auth_user_metadata(coalesce(new.admin_id, old.admin_id));

  for staff_id_record in
    select staff_id
    from public.staff_agency_assignments
    where facility_id = coalesce(new.id, old.id)
  loop
    perform public.sync_auth_user_metadata(staff_id_record.staff_id);
  end loop;

  return coalesce(new, old);
end;
$$;

create or replace function public.sync_staff_agency_auth_metadata_trigger()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  perform public.sync_auth_user_metadata(coalesce(new.staff_id, old.staff_id));
  return coalesce(new, old);
end;
$$;

drop trigger if exists users_sync_auth_metadata on public.users;
create trigger users_sync_auth_metadata
after insert or update of email, full_name, avatar_url, role on public.users
for each row execute function public.sync_auth_user_metadata_trigger();

drop trigger if exists facilities_sync_auth_metadata on public.facilities;
create trigger facilities_sync_auth_metadata
after insert or update of admin_id, approval_status, is_active on public.facilities
for each row execute function public.sync_facility_auth_metadata_trigger();

drop trigger if exists staff_agency_sync_auth_metadata on public.staff_agency_assignments;
create trigger staff_agency_sync_auth_metadata
after insert or update or delete on public.staff_agency_assignments
for each row execute function public.sync_staff_agency_auth_metadata_trigger();

-- Backfill existing Authentication Users metadata from current Table Editor data.
do $$
declare
  profile_record record;
begin
  for profile_record in select id from public.users loop
    perform public.sync_auth_user_metadata(profile_record.id);
  end loop;
end;
$$;
