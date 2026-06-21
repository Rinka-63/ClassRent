-- Add agency details handling on registration

do $$
begin
  revoke execute on function public.register_agency_admin_profile(text, text) from authenticated;
exception
  when undefined_function then null;
end
$$;

drop function if exists public.register_agency_admin_profile(text, text);

create or replace function public.register_agency_admin_profile(
  p_full_name text,
  p_agency_name text,
  p_agency_email text default null,
  p_agency_phone text default null,
  p_agency_address text default null,
  p_agency_city text default null,
  p_agency_description text default null
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
    'ADMIN'
  )
  on conflict (id) do update
    set email = excluded.email,
        full_name = excluded.full_name,
        role = 'ADMIN',
        updated_at = now()
  where public.users.role in ('USER','ADMIN');

  insert into public.agencies (admin_id, name, slug, email, phone, address, city, description, approval_status, is_active)
  values (current_user_id, normalized_agency_name, agency_slug, p_agency_email, p_agency_phone, p_agency_address, p_agency_city, p_agency_description, 'pending', false)
  on conflict (admin_id) do update
    set name = excluded.name,
        slug = excluded.slug,
        email = coalesce(excluded.email, public.agencies.email),
        phone = coalesce(excluded.phone, public.agencies.phone),
        address = coalesce(excluded.address, public.agencies.address),
        city = coalesce(excluded.city, public.agencies.city),
        description = coalesce(excluded.description, public.agencies.description),
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

grant execute on function public.register_agency_admin_profile(text, text, text, text, text, text, text)
to authenticated;

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  registration_type text := new.raw_user_meta_data->>'registration_type';
  requested_role text := new.raw_app_meta_data->>'role';
  resolved_role text;
  full_name text := coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1), 'ClassRent User');
  agency_name text := nullif(trim(coalesce(new.raw_user_meta_data->>'agency_name', '')), '');
  
  agency_email text := nullif(trim(coalesce(new.raw_user_meta_data->>'agency_email', '')), '');
  agency_phone text := nullif(trim(coalesce(new.raw_user_meta_data->>'agency_phone', '')), '');
  agency_address text := nullif(trim(coalesce(new.raw_user_meta_data->>'agency_address', '')), '');
  agency_city text := nullif(trim(coalesce(new.raw_user_meta_data->>'agency_city', '')), '');
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
    insert into public.agencies (admin_id, name, slug, email, phone, address, city, description, approval_status, is_active)
    values (
      new.id,
      coalesce(agency_name, full_name || ' Agency'),
      public.slugify(coalesce(agency_name, full_name || ' Agency')) || '-' || left(new.id::text, 8),
      agency_email,
      agency_phone,
      agency_address,
      agency_city,
      agency_description,
      'pending',
      false
    )
    on conflict (admin_id) do nothing;
  end if;

  return new;
end;
$$;
