-- Allow approved agency admins to read their own rooms.
-- UI queries still decide whether to show active or archived rooms.

drop policy if exists rooms_admin_select_own on public.rooms;
create policy rooms_admin_select_own on public.rooms
for select using (
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
