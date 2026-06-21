do $$
begin
  alter table public.users drop constraint if exists users_role_check;
exception
  when undefined_object then null;
end
$$;

alter table public.users
  add constraint users_role_check
  check (role in ('SUPER_ADMIN', 'ADMIN', 'USER', 'super_admin', 'admin', 'user', 'staff'));
