alter table public.agencies
  add column if not exists deleted_at timestamptz,
  add column if not exists deletion_reason text;

create index if not exists idx_agencies_deleted_at
  on public.agencies(deleted_at);
