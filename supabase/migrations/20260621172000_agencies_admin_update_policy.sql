-- Allow agency admins to update their own agency profile
drop policy if exists agencies_admin_update on public.agencies;
create policy agencies_admin_update on public.agencies
for update using (admin_id = auth.uid());

-- Prevent agency admins from modifying sensitive fields
create or replace function public.protect_agency_sensitive_fields()
returns trigger language plpgsql security definer as $$
begin
  if not public.is_super_admin() then
    -- Revert any unauthorized changes to sensitive fields back to their old values
    new.approval_status := old.approval_status;
    new.is_active := old.is_active;
    new.admin_id := old.admin_id;
    new.slug := old.slug;
    new.approved_at := old.approved_at;
    new.rejected_at := old.rejected_at;
    new.reviewed_by := old.reviewed_by;
    new.rejection_reason := old.rejection_reason;
  end if;
  return new;
end;
$$;

drop trigger if exists protect_agency_sensitive_fields_trigger on public.agencies;
create trigger protect_agency_sensitive_fields_trigger
before update on public.agencies
for each row execute function public.protect_agency_sensitive_fields();
