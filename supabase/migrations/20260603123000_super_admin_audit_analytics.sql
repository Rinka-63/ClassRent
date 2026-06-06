-- Super admin audit log and access hardening.

create or replace function public.log_audit_event(
  p_actor_id uuid,
  p_action text,
  p_entity_type text,
  p_entity_id uuid,
  p_old jsonb,
  p_new jsonb
)
returns void language plpgsql security definer set search_path = public as $$
begin
  insert into public.audit_logs (actor_id, action, entity_type, entity_id, old, new)
  values (p_actor_id, p_action, p_entity_type, p_entity_id, p_old, p_new);
end;
$$;

create or replace function public.audit_agencies_trigger()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  action_name text;
begin
  if tg_op = 'INSERT' then
    action_name := 'agency_created';
    perform public.log_audit_event(auth.uid(), action_name, 'agency', new.id, null, to_jsonb(new));
    return new;
  elsif tg_op = 'UPDATE' then
    if old.approval_status is distinct from new.approval_status then
      action_name := case new.approval_status
        when 'approved' then 'agency_approved'
        when 'rejected' then 'agency_rejected'
        when 'pending' then 'agency_pending'
        when 'suspended' then 'agency_suspended'
        else 'agency_status_updated'
      end;
    elsif old.is_active is distinct from new.is_active then
      action_name := case
        when new.is_active then 'agency_reactivated'
        else 'agency_suspended'
      end;
    else
      action_name := 'agency_updated';
    end if;

    perform public.log_audit_event(auth.uid(), action_name, 'agency', new.id, to_jsonb(old), to_jsonb(new));
    return new;
  else
    perform public.log_audit_event(auth.uid(), 'agency_deleted', 'agency', old.id, to_jsonb(old), null);
    return old;
  end if;
end;
$$;

create or replace function public.audit_users_trigger()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  action_name text;
begin
  if tg_op = 'INSERT' then
    action_name := 'user_created';
    perform public.log_audit_event(auth.uid(), action_name, 'user', new.id, null, to_jsonb(new));
    return new;
  elsif tg_op = 'UPDATE' then
    if old.deleted_at is distinct from new.deleted_at then
      action_name := case
        when new.deleted_at is null then 'user_reactivated'
        else 'user_suspended'
      end;
    elsif old.role is distinct from new.role then
      action_name := 'user_role_updated';
    else
      action_name := 'user_updated';
    end if;

    perform public.log_audit_event(auth.uid(), action_name, 'user', new.id, to_jsonb(old), to_jsonb(new));
    return new;
  else
    perform public.log_audit_event(auth.uid(), 'user_deleted', 'user', old.id, to_jsonb(old), null);
    return old;
  end if;
end;
$$;

create or replace function public.audit_rooms_trigger()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'INSERT' then
    perform public.log_audit_event(auth.uid(), 'room_created', 'room', new.id, null, to_jsonb(new));
    return new;
  elsif tg_op = 'UPDATE' then
    perform public.log_audit_event(auth.uid(), 'room_updated', 'room', new.id, to_jsonb(old), to_jsonb(new));
    return new;
  else
    perform public.log_audit_event(auth.uid(), 'room_deleted', 'room', old.id, to_jsonb(old), null);
    return old;
  end if;
end;
$$;

create or replace function public.audit_bookings_trigger()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  action_name text;
begin
  if tg_op = 'INSERT' then
    action_name := 'booking_created';
    perform public.log_audit_event(auth.uid(), action_name, 'booking', new.id, null, to_jsonb(new));
    return new;
  elsif tg_op = 'UPDATE' then
    if old.status is distinct from new.status then
      action_name := case new.status
        when 'confirmed' then 'booking_approved'
        when 'cancelled' then 'booking_cancelled'
        else 'booking_status_updated'
      end;
    else
      action_name := 'booking_updated';
    end if;
    perform public.log_audit_event(auth.uid(), action_name, 'booking', new.id, to_jsonb(old), to_jsonb(new));
    return new;
  else
    perform public.log_audit_event(auth.uid(), 'booking_deleted', 'booking', old.id, to_jsonb(old), null);
    return old;
  end if;
end;
$$;

drop trigger if exists trg_audit_agencies on public.agencies;
create trigger trg_audit_agencies
after insert or update or delete on public.agencies
for each row execute function public.audit_agencies_trigger();

drop trigger if exists trg_audit_users on public.users;
create trigger trg_audit_users
after insert or update or delete on public.users
for each row execute function public.audit_users_trigger();

drop trigger if exists trg_audit_rooms on public.rooms;
create trigger trg_audit_rooms
after insert or update or delete on public.rooms
for each row execute function public.audit_rooms_trigger();

drop trigger if exists trg_audit_bookings on public.bookings;
create trigger trg_audit_bookings
after insert or update or delete on public.bookings
for each row execute function public.audit_bookings_trigger();

alter table public.audit_logs enable row level security;

drop policy if exists audit_admin_read on public.audit_logs;
create policy audit_super_admin_read on public.audit_logs
for select using (public.is_super_admin());

drop policy if exists audit_super_admin_manage on public.audit_logs;
create policy audit_super_admin_manage on public.audit_logs
for all using (public.is_super_admin()) with check (public.is_super_admin());

create index if not exists idx_audit_logs_created_at on public.audit_logs(created_at desc);
create index if not exists idx_audit_logs_entity on public.audit_logs(entity_type, entity_id);
create index if not exists idx_audit_logs_actor on public.audit_logs(actor_id);

