create or replace function public.current_user_role()
returns text language sql stable security definer set search_path = public as $$
  select role
  from public.users
  where id = auth.uid()
    and deleted_at is null
$$;

create or replace function public.is_super_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select coalesce(
    lower(public.current_user_role()) = 'super_admin'
    or upper(public.current_user_role()) = 'SUPER_ADMIN',
    false
  )
$$;

create or replace function public.is_admin_or_super_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select coalesce(
    lower(public.current_user_role()) in ('admin', 'super_admin')
    or upper(public.current_user_role()) in ('ADMIN', 'SUPER_ADMIN'),
    false
  )
$$;

