update public.users
set role = case
  when lower(role) = 'super_admin' then 'super_admin'
  when lower(role) = 'admin' then 'admin'
  when lower(role) = 'user' then 'user'
  else role
end
where role is not null;

do $$
begin
  alter table public.users drop constraint if exists users_role_check;
exception
  when undefined_object then null;
end
$$;

alter table public.users
  add constraint users_role_check
  check (role in ('user', 'admin', 'super_admin'));

create or replace function public.register_agency_admin_profile(
  p_full_name text,
  p_agency_name text,
  p_whatsapp_number text default null,
  p_agency_description text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
  current_role text;
  normalized_full_name text := nullif(trim(coalesce(p_full_name, '')), '');
  normalized_agency_name text := nullif(trim(coalesce(p_agency_name, '')), '');
  normalized_whatsapp text := nullif(trim(coalesce(p_whatsapp_number, '')), '');
  normalized_description text := nullif(trim(coalesce(p_agency_description, '')), '');
  agency_slug text;
  agency_id uuid;
begin
  if current_user_id is null then
    raise exception 'Not authenticated';
  end if;

  select lower(role) into current_role
  from public.users
  where id = current_user_id;

  if current_role = 'super_admin' then
    raise exception 'Super admin cannot register an agency';
  end if;

  normalized_agency_name := coalesce(normalized_agency_name, normalized_full_name || ' Agency');
  agency_slug := public.slugify(normalized_agency_name);

  insert into public.agencies (
    admin_id,
    name,
    slug,
    approval_status,
    is_active,
    whatsapp_number,
    description
  )
  values (
    current_user_id,
    normalized_agency_name,
    agency_slug,
    'pending',
    false,
    normalized_whatsapp,
    normalized_description
  )
  on conflict (admin_id) do update
    set name = excluded.name,
        slug = excluded.slug,
        approval_status = 'pending',
        is_active = false,
        whatsapp_number = coalesce(excluded.whatsapp_number, public.agencies.whatsapp_number),
        description = coalesce(excluded.description, public.agencies.description),
        updated_at = now()
  returning id into agency_id;

  if agency_id is null then
    select id into agency_id
    from public.agencies
    where admin_id = current_user_id
    limit 1;
  end if;

  update public.users
  set full_name = coalesce(normalized_full_name, full_name),
      updated_at = now()
  where id = current_user_id
    and lower(coalesce(role, '')) <> 'super_admin';

  return agency_id;
end;
$$;

grant execute on function public.register_agency_admin_profile(text, text, text, text) to authenticated;

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  registration_type text := new.raw_user_meta_data->>'registration_type';
  requested_role text := coalesce(new.raw_app_meta_data->>'role', new.raw_user_meta_data->>'role');
  resolved_role text;
  full_name text := coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1), 'ClassRent User');
  agency_name text := nullif(trim(coalesce(new.raw_user_meta_data->>'agency_name', '')), '');
  agency_whatsapp text := nullif(trim(coalesce(new.raw_user_meta_data->>'agency_whatsapp', '')), '');
  agency_description text := nullif(trim(coalesce(new.raw_user_meta_data->>'agency_description', '')), '');
begin
  resolved_role := case
    when lower(requested_role) = 'super_admin' then 'super_admin'
    when registration_type = 'agency_admin' then 'admin'
    else 'user'
  end;

  insert into public.users (id, email, full_name, role)
  values (new.id, coalesce(new.email, ''), full_name, resolved_role)
  on conflict (id) do update
    set email = excluded.email,
        full_name = excluded.full_name,
        role = case
          when lower(public.users.role) = 'super_admin' then 'super_admin'
          else excluded.role
        end,
        updated_at = now();

  if registration_type = 'agency_admin' then
    insert into public.agencies (
      admin_id,
      name,
      slug,
      approval_status,
      is_active,
      whatsapp_number,
      description
    )
    values (
      new.id,
      coalesce(agency_name, full_name || ' Agency'),
      public.slugify(coalesce(agency_name, full_name || ' Agency')) || '-' || left(new.id::text, 8),
      'pending',
      false,
      agency_whatsapp,
      agency_description
    )
    on conflict (admin_id) do update
      set name = excluded.name,
          slug = excluded.slug,
          approval_status = 'pending',
          is_active = false,
          whatsapp_number = coalesce(excluded.whatsapp_number, public.agencies.whatsapp_number),
          description = coalesce(excluded.description, public.agencies.description),
          updated_at = now();
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
  select lower(role) into profile_role
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

