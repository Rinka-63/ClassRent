-- Allow suspended agencies without breaking existing rows.

alter table public.agencies
drop constraint if exists agencies_approval_status_check;

alter table public.agencies
add constraint agencies_approval_status_check
check (approval_status in ('pending','approved','rejected','suspended'));

