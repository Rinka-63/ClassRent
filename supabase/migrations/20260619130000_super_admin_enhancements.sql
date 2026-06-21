-- Super Admin enhancements: approval states, account status, and audit support.

alter table public.agencies
  drop constraint if exists agencies_approval_status_check;

alter table public.agencies
  add constraint agencies_approval_status_check
  check (approval_status in ('pending','approved','rejected','suspended'));

alter table public.users
  add column if not exists account_status text not null default 'active'
    check (account_status in ('active','pending','suspended','disabled','deleted')),
  add column if not exists last_login_at timestamptz;

update public.users
set account_status = 'deleted'
where deleted_at is not null
  and account_status <> 'deleted';

create index if not exists idx_users_account_status
  on public.users(account_status, deleted_at);

create or replace function public.is_account_usable(target_user_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1
    from public.users u
    where u.id = target_user_id
      and u.deleted_at is null
      and u.account_status in ('active','pending')
  )
$$;

create or replace function public.current_user_role()
returns text language sql stable security definer set search_path = public as $$
  select role
  from public.users
  where id = auth.uid()
    and deleted_at is null
    and account_status in ('active','pending')
$$;

drop policy if exists agencies_super_admin_update on public.agencies;
create policy agencies_super_admin_update on public.agencies
for update using (public.is_super_admin())
with check (public.is_super_admin());

drop policy if exists users_update_own_basic on public.users;
create policy users_update_own_basic on public.users
for update using (
  id = auth.uid()
  and account_status in ('active','pending')
)
with check (
  id = auth.uid()
  and role = (select role from public.users where id = auth.uid())
  and account_status = (select account_status from public.users where id = auth.uid())
  and deleted_at is null
);

drop policy if exists users_admin_update on public.users;
create policy users_admin_update on public.users
for update using (
  public.is_super_admin()
  and id <> auth.uid()
)
with check (
  public.is_super_admin()
  and id <> auth.uid()
);

create or replace function public.audit_row_change()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  changed_action text;
  target_id uuid;
begin
  changed_action := lower(tg_table_name) || '_' || lower(tg_op);
  target_id := coalesce(new.id, old.id);

  if tg_table_name = 'bookings' then
    changed_action := 'booking_' || lower(tg_op);
  elsif tg_table_name = 'payments' then
    changed_action := 'payment_' || lower(tg_op);
  end if;

  insert into public.audit_logs (actor_id, action, entity_type, entity_id, old, new)
  values (
    auth.uid(),
    changed_action,
    tg_table_name,
    target_id,
    case when tg_op in ('UPDATE','DELETE') then to_jsonb(old) else null end,
    case when tg_op in ('INSERT','UPDATE') then to_jsonb(new) else null end
  );

  return coalesce(new, old);
end;
$$;

drop trigger if exists bookings_audit_row_change on public.bookings;
create trigger bookings_audit_row_change
after insert or update or delete on public.bookings
for each row execute function public.audit_row_change();

drop trigger if exists payments_audit_row_change on public.payments;
create trigger payments_audit_row_change
after insert or update or delete on public.payments
for each row execute function public.audit_row_change();
