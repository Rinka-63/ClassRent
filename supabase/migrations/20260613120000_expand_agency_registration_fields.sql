alter table public.agencies
  add column if not exists whatsapp_number text,
  add column if not exists description text;

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
  set role = 'admin',
      full_name = coalesce(normalized_full_name, full_name),
      updated_at = now()
  where id = current_user_id;

  return agency_id;
end;
$$;

grant execute on function public.register_agency_admin_profile(text, text, text, text) to authenticated;

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  registration_type text := new.raw_user_meta_data->>'registration_type';
  requested_role text := new.raw_app_meta_data->>'role';
  resolved_role text;
  full_name text := coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1), 'ClassRent User');
  agency_name text := nullif(trim(coalesce(new.raw_user_meta_data->>'agency_name', '')), '');
  agency_whatsapp text := nullif(trim(coalesce(new.raw_user_meta_data->>'agency_whatsapp', '')), '');
  agency_description text := nullif(trim(coalesce(new.raw_user_meta_data->>'agency_description', '')), '');
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
