-- Add account reactivation support and app update configuration.

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
  if normalized_status not in ('active', 'suspended', 'disabled') then
    raise exception 'Unsupported user status: %', p_status;
  end if;

  update public.users
  set
    account_status = normalized_status,
    deleted_at = case when normalized_status = 'disabled' then coalesce(deleted_at, now()) else null end,
    deletion_reason = case when normalized_status = 'disabled' then 'Diblokir oleh super admin' else null end,
    updated_at = now()
  where id = p_user_id;

  if not found then
    raise exception 'User not found';
  end if;

  audit_action := case
    when normalized_status = 'active' then 'user_reactivated'
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

insert into public.system_settings (key, value, description)
values (
  'app_version',
  jsonb_build_object(
    'latest_version_name', '0.1.0',
    'min_build_number', 1,
    'force_update', false,
    'android_store_url', 'https://play.google.com/store/apps/details?id=com.ti24a4.sewakelas',
    'message_id', 'Versi baru ClassRent tersedia. Perbarui aplikasi untuk melanjutkan.',
    'message_en', 'A new ClassRent version is available. Update the app to continue.'
  ),
  'Public app version gate used to force users to update before opening the app.'
)
on conflict (key) do update
set
  value = excluded.value,
  description = excluded.description,
  updated_at = now();

notify pgrst, 'reload schema';
