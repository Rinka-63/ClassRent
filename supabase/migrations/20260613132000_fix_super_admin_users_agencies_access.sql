create or replace function public.current_user_role()
returns text language sql stable security definer set search_path = public as $$
  select coalesce(
    nullif(auth.jwt() -> 'app_metadata' ->> 'role', ''),
    nullif(auth.jwt() -> 'user_metadata' ->> 'role', ''),
    (select role from public.users where id = auth.uid() and deleted_at is null)
  )
$$;

create or replace function public.is_super_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select coalesce(lower(public.current_user_role()) = 'super_admin', false)
$$;

create or replace function public.is_admin_or_super_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select coalesce(lower(public.current_user_role()) in ('admin', 'super_admin'), false)
$$;

drop policy if exists users_select_own_or_admin on public.users;
drop policy if exists users_select_super_admin_all on public.users;
create policy users_select_super_admin_all on public.users
for select using (
  id = auth.uid()
  or public.is_super_admin()
);

drop policy if exists agencies_select_scoped on public.agencies;
drop policy if exists agencies_super_admin_select on public.agencies;
create policy agencies_super_admin_select on public.agencies
for select using (
  public.is_super_admin()
  or admin_id = auth.uid()
);

