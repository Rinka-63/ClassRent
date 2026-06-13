-- Prepare payments table for Midtrans Snap checkout and webhook callbacks.
-- This migration is intentionally database-only and keeps existing columns for compatibility.

create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid references public.bookings(id),
  user_id uuid references public.users(id),
  order_id text unique,
  transaction_id text,
  gross_amount numeric(12,2) not null default 0 check (gross_amount >= 0),
  payment_method text,
  payment_type text,
  transaction_status text not null default 'pending',
  snap_token text,
  snap_redirect_url text,
  midtrans_response jsonb,
  paid_at timestamp,
  expired_at timestamp,
  created_at timestamp not null default now(),
  updated_at timestamp not null default now()
);

alter table public.payments
  add column if not exists order_id text,
  add column if not exists transaction_id text,
  add column if not exists gross_amount numeric(12,2),
  add column if not exists payment_type text,
  add column if not exists transaction_status text,
  add column if not exists snap_redirect_url text,
  add column if not exists midtrans_response jsonb,
  add column if not exists paid_at timestamp,
  add column if not exists expired_at timestamp;

update public.payments
set
  order_id = coalesce(order_id, midtrans_order_id),
  transaction_id = coalesce(transaction_id, midtrans_transaction_id),
  gross_amount = coalesce(gross_amount, amount, 0),
  transaction_status = coalesce(transaction_status, status, 'pending'),
  midtrans_response = coalesce(midtrans_response, webhook_payload),
  expired_at = coalesce(expired_at, expires_at::timestamp)
where
  order_id is null
  or transaction_id is null
  or gross_amount is null
  or transaction_status is null
  or midtrans_response is null
  or expired_at is null;

alter table public.payments
  alter column gross_amount set default 0,
  alter column gross_amount set not null,
  alter column transaction_status set default 'pending',
  alter column transaction_status set not null;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'payments_order_id_key'
      and conrelid = 'public.payments'::regclass
  ) then
    alter table public.payments
      add constraint payments_order_id_key unique (order_id);
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'payments_booking_id_fkey'
      and conrelid = 'public.payments'::regclass
  ) then
    alter table public.payments
      add constraint payments_booking_id_fkey
      foreign key (booking_id) references public.bookings(id);
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'payments_user_id_fkey'
      and conrelid = 'public.payments'::regclass
  ) then
    alter table public.payments
      add constraint payments_user_id_fkey
      foreign key (user_id) references public.users(id);
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'payments_gross_amount_non_negative_check'
      and conrelid = 'public.payments'::regclass
  ) then
    alter table public.payments
      add constraint payments_gross_amount_non_negative_check
      check (gross_amount >= 0);
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'payments_transaction_status_check'
      and conrelid = 'public.payments'::regclass
  ) then
    alter table public.payments
      add constraint payments_transaction_status_check
      check (
        transaction_status in (
          'pending',
          'capture',
          'settlement',
          'deny',
          'cancel',
          'expire',
          'failure',
          'refund'
        )
      );
  end if;
end $$;

create index if not exists idx_payments_order_id on public.payments(order_id);
create index if not exists idx_payments_booking_id on public.payments(booking_id);
create index if not exists idx_payments_transaction_status on public.payments(transaction_status);
create index if not exists idx_payments_user_id on public.payments(user_id);

alter table public.payments enable row level security;

drop policy if exists payments_user_read on public.payments;
drop policy if exists payments_admin_select on public.payments;
drop policy if exists payments_super_admin_select on public.payments;
drop policy if exists payments_select_scoped_midtrans on public.payments;

create policy payments_select_scoped_midtrans on public.payments
for select
using (
  user_id = auth.uid()
  or public.is_super_admin()
  or exists (
    select 1
    from public.bookings b
    join public.rooms r on r.id = b.room_id
    join public.agencies a on a.admin_id = r.admin_id
    where b.id = payments.booking_id
      and a.admin_id = auth.uid()
      and a.approval_status = 'approved'
      and a.is_active = true
  )
);

create or replace function public.audit_payments_midtrans_trigger()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  action_name text;
  room_name text;
  agency_id uuid;
  agency_name text;
  actor_id uuid;
begin
  select r.name, a.id, a.name
  into room_name, agency_id, agency_name
  from public.bookings b
  join public.rooms r on r.id = b.room_id
  left join public.agencies a on a.admin_id = r.admin_id
  where b.id = coalesce(new.booking_id, old.booking_id)
  limit 1;

  actor_id := coalesce(auth.uid(), new.user_id, old.user_id);

  if tg_op = 'INSERT' then
    action_name := 'payment_created';
    perform public.log_audit_event(
      actor_id,
      action_name,
      'payment',
      new.id,
      coalesce(new.order_id, new.id::text),
      agency_id,
      agency_name,
      'Payment created',
      null,
      to_jsonb(new)
    );
    return new;
  end if;

  if old.transaction_status is distinct from new.transaction_status then
    action_name := 'payment_status_changed';
    perform public.log_audit_event(
      actor_id,
      action_name,
      'payment',
      new.id,
      coalesce(new.order_id, new.id::text),
      agency_id,
      agency_name,
      'Payment status changed from '
        || coalesce(old.transaction_status, '-')
        || ' to '
        || coalesce(new.transaction_status, '-'),
      to_jsonb(old),
      to_jsonb(new)
    );
  end if;

  return new;
end;
$$;

drop trigger if exists trg_audit_payments_midtrans on public.payments;

create trigger trg_audit_payments_midtrans
after insert or update of transaction_status on public.payments
for each row
execute function public.audit_payments_midtrans_trigger();
