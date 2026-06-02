-- Reliable agency registration RPC.
-- Public client registration can be blocked by RLS; this function lets an
-- authenticated user finalize agency-admin setup safely.

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
  agency_slug := public.slugify(normalized_agency_name) || '-' || left(current_user_id::text, 8);

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

  select id into agency_id
  from public.facilities
  where admin_id = current_user_id
  order by created_at asc
  limit 1;

  if agency_id is null then
    insert into public.facilities (
      admin_id,
      name,
      slug,
      approval_status,
      is_active
    )
    values (
      current_user_id,
      normalized_agency_name,
      agency_slug,
      'pending',
      false
    )
    returning id into agency_id;
  end if;

  perform public.sync_auth_user_metadata(current_user_id);

  return agency_id;
end;
$$;

grant execute on function public.register_agency_admin_profile(text, text)
to authenticated;
