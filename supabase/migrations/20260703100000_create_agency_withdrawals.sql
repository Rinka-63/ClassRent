create table if not exists public.agency_withdrawals (
  id uuid primary key default gen_random_uuid(),
  agency_id uuid not null references public.agencies(id) on delete cascade,
  requested_by uuid not null references public.users(id),
  amount numeric(12,2) not null check (amount > 0),
  bank_name text not null,
  account_name text not null,
  account_number text not null,
  status text not null default 'pending'
    check (status in ('pending','approved','rejected','paid')),
  reviewed_by uuid references public.users(id),
  reviewed_at timestamptz,
  rejection_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists agency_withdrawals_set_updated_at
  on public.agency_withdrawals;
create trigger agency_withdrawals_set_updated_at
before update on public.agency_withdrawals
for each row execute function public.set_updated_at();

create index if not exists idx_agency_withdrawals_agency_status
  on public.agency_withdrawals(agency_id, status, created_at desc);

alter table public.agency_withdrawals enable row level security;

drop policy if exists agency_withdrawals_select_scoped
  on public.agency_withdrawals;
create policy agency_withdrawals_select_scoped
on public.agency_withdrawals
for select using (
  public.is_super_admin()
  or exists (
    select 1
    from public.agencies a
    where a.id = agency_id
      and a.admin_id = auth.uid()
  )
);

drop policy if exists agency_withdrawals_insert_owner
  on public.agency_withdrawals;
create policy agency_withdrawals_insert_owner
on public.agency_withdrawals
for insert with check (
  requested_by = auth.uid()
  and exists (
    select 1
    from public.agencies a
    where a.id = agency_id
      and a.admin_id = auth.uid()
      and a.approval_status = 'approved'
      and a.is_active = true
  )
);

drop policy if exists agency_withdrawals_super_admin_update
  on public.agency_withdrawals;
create policy agency_withdrawals_super_admin_update
on public.agency_withdrawals
for update using (public.is_super_admin())
with check (public.is_super_admin());

notify pgrst, 'reload schema';
