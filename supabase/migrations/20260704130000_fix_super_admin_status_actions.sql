-- Make super admin status actions safe and remove recursive user select policy paths.

drop policy if exists users_select_own_or_admin on public.users;
create policy users_select_own_or_admin on public.users
for select using (
  id = auth.uid()
  or public.is_super_admin()
);

create or replace function public.super_admin_set_user_account_status(
  p_user_id uuid,
  p_status text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  normalized_status text := lower(trim(coalesce(p_status, '')));
  audit_action text;
begin
  if normalized_status not in ('suspended', 'disabled') then
    raise exception 'Unsupported user status: %', p_status;
  end if;

  update public.users
  set
    account_status = normalized_status,
    deleted_at = case when normalized_status = 'disabled' then coalesce(deleted_at, now()) else null end,
    updated_at = now()
  where id = p_user_id;

  if not found then
    raise exception 'User not found';
  end if;

  audit_action := case
    when normalized_status = 'suspended' then 'user_suspended'
    else 'user_banned'
  end;

  insert into public.audit_logs (
    actor_id,
    action,
    entity_type,
    entity_id,
    old,
    new
  ) values (
    auth.uid(),
    audit_action,
    'user',
    p_user_id,
    null,
    jsonb_build_object(
      'account_status', normalized_status,
      'deleted_at', case when normalized_status = 'disabled' then now() else null end
    )
  );

  perform public.sync_auth_user_metadata(p_user_id);
end;
$$;

grant execute on function public.super_admin_set_user_account_status(uuid, text)
to authenticated;

create or replace function public.super_admin_set_agency_status(
  p_agency_id uuid,
  p_status text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  normalized_status text := lower(trim(coalesce(p_status, '')));
  audit_action text;
  agency_admin_id uuid;
begin
  if normalized_status not in ('suspended', 'banned') then
    raise exception 'Unsupported agency status: %', p_status;
  end if;

  select admin_id
  into agency_admin_id
  from public.agencies
  where id = p_agency_id;

  if agency_admin_id is null then
    raise exception 'Agency not found';
  end if;

  update public.agencies
  set
    approval_status = case
      when normalized_status = 'suspended' then 'suspended'
      else 'rejected'
    end,
    is_active = false,
    rejected_at = case
      when normalized_status = 'banned' then now()
      else rejected_at
    end,
    rejection_reason = case
      when normalized_status = 'banned' then 'Diblokir oleh super admin'
      else rejection_reason
    end,
    updated_at = now()
  where id = p_agency_id;

  audit_action := case
    when normalized_status = 'suspended' then 'agency_suspended'
    else 'agency_banned'
  end;

  insert into public.audit_logs (
    actor_id,
    action,
    entity_type,
    entity_id,
    old,
    new
  ) values (
    auth.uid(),
    audit_action,
    'agency',
    p_agency_id,
    null,
    jsonb_build_object(
      'approval_status', case
        when normalized_status = 'suspended' then 'suspended'
        else 'rejected'
      end,
      'is_active', false,
      'rejection_reason', case
        when normalized_status = 'banned' then 'Diblokir oleh super admin'
        else null
      end
    )
  );

  perform public.sync_auth_user_metadata(agency_admin_id);
end;
$$;

grant execute on function public.super_admin_set_agency_status(uuid, text)
to authenticated;

notify pgrst, 'reload schema';
