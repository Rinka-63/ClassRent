-- Ensure agency admins can soft-delete their own rooms via update.

drop policy if exists rooms_admin_soft_delete_update on public.rooms;
create policy rooms_admin_soft_delete_update on public.rooms
for update using (
  admin_id = auth.uid()
  or public.is_super_admin()
) with check (
  admin_id = auth.uid()
  or public.is_super_admin()
);
