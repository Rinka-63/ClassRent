-- Fix rooms UPDATE RLS so agency admins can soft-delete their own rooms.
-- The policy is intentionally scoped to rooms.admin_id = auth.uid()
-- and requires the admin's agency to be approved and active.

drop policy if exists rooms_admin_update on public.rooms;
drop policy if exists rooms_admin_soft_delete_update on public.rooms;

create policy rooms_admin_update on public.rooms
for update
using (
  public.is_super_admin()
  or (
    admin_id = auth.uid()
    and exists (
      select 1
      from public.agencies a
      where a.admin_id = auth.uid()
        and a.approval_status = 'approved'
        and a.is_active = true
    )
  )
)
with check (
  public.is_super_admin()
  or (
    admin_id = auth.uid()
    and exists (
      select 1
      from public.agencies a
      where a.admin_id = auth.uid()
        and a.approval_status = 'approved'
        and a.is_active = true
    )
  )
);
