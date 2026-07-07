create or replace function public.update_own_profile(
  p_full_name text,
  p_phone text default null,
  p_avatar_url text default null
)
returns public.users
language plpgsql
security definer
set search_path = public
as $$
declare
  updated_user public.users;
  normalized_name text := nullif(trim(coalesce(p_full_name, '')), '');
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  if normalized_name is null then
    raise exception 'Name is required';
  end if;

  update public.users
  set
    full_name = normalized_name,
    phone = case
      when p_phone is null then phone
      else nullif(trim(p_phone), '')
    end,
    avatar_url = case
      when p_avatar_url is null then avatar_url
      else nullif(trim(p_avatar_url), '')
    end,
    updated_at = now()
  where
    id = auth.uid()
    and account_status in ('active', 'pending')
    and deleted_at is null
  returning * into updated_user;

  if updated_user.id is null then
    raise exception 'User profile cannot be updated';
  end if;

  update auth.users
  set raw_user_meta_data = coalesce(raw_user_meta_data, '{}'::jsonb)
    || jsonb_build_object(
      'full_name', updated_user.full_name,
      'avatar_url', updated_user.avatar_url
    )
  where id = updated_user.id;

  return updated_user;
end;
$$;

grant execute on function public.update_own_profile(text, text, text)
to authenticated;
