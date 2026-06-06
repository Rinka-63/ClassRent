-- Expand audit_logs for super admin reporting and detail view.

alter table public.audit_logs
add column if not exists actor_name text,
add column if not exists actor_role text,
add column if not exists agency_id uuid references public.agencies(id),
add column if not exists agency_name text,
add column if not exists entity_name text,
add column if not exists description text;

create index if not exists idx_audit_logs_actor_id on public.audit_logs(actor_id);
create index if not exists idx_audit_logs_agency_id on public.audit_logs(agency_id);
create index if not exists idx_audit_logs_entity_type on public.audit_logs(entity_type);
create index if not exists idx_audit_logs_created_at_desc on public.audit_logs(created_at desc);

