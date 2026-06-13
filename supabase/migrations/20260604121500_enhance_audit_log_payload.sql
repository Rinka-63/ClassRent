-- Enrich audit log payload for professional timeline and detail views.

create or replace function public.log_audit_event(
  p_actor_id uuid,
  p_action text,
  p_entity_type text,
  p_entity_id uuid,
  p_entity_name text default null,
  p_agency_id uuid default null,
  p_agency_name text default null,
  p_description text default null,
  p_old jsonb default null,
  p_new jsonb default null
)
returns void language plpgsql security definer set search_path = public as $$
declare
  actor_name text;
  actor_role text;
begin
  select full_name, role into actor_name, actor_role
  from public.users
  where id = p_actor_id
  limit 1;

  insert into public.audit_logs (
    actor_id,
    actor_name,
    actor_role,
    agency_id,
    agency_name,
    action,
    entity_type,
    entity_id,
    entity_name,
    description,
    old,
    new,
    created_at
  )
  values (
    p_actor_id,
    actor_name,
    actor_role,
    p_agency_id,
    p_agency_name,
    p_action,
    p_entity_type,
    p_entity_id,
    p_entity_name,
    coalesce(p_description, p_action || ' ' || p_entity_type),
    p_old,
    p_new,
    now()
  );
end;
$$;

create or replace function public.audit_agencies_trigger()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  action_name text;
begin
  if tg_op = 'INSERT' then
    action_name := 'agency_created';
    perform public.log_audit_event(auth.uid(), action_name, 'agency', new.id, new.name, new.id, new.name, 'Agency created', null, to_jsonb(new));
    return new;
  elsif tg_op = 'UPDATE' then
    if old.approval_status is distinct from new.approval_status then
      action_name := case new.approval_status
        when 'approved' then 'agency_approved'
        when 'rejected' then 'agency_rejected'
        when 'suspended' then 'agency_suspended'
        else 'agency_status_updated'
      end;
    elsif old.is_active is distinct from new.is_active then
      action_name := case when new.is_active then 'agency_reactivated' else 'agency_suspended' end;
    else
      action_name := 'agency_updated';
    end if;

    perform public.log_audit_event(auth.uid(), action_name, 'agency', new.id, new.name, new.id, new.name, null, to_jsonb(old), to_jsonb(new));
    return new;
  else
    perform public.log_audit_event(auth.uid(), 'agency_deleted', 'agency', old.id, old.name, old.id, old.name, null, to_jsonb(old), null);
    return old;
  end if;
end;
$$;

create or replace function public.audit_users_trigger()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  action_name text;
  agency_id uuid;
  agency_name text;
begin
  select id, name into agency_id, agency_name
  from public.agencies
  where admin_id = coalesce(auth.uid(), new.id)
  limit 1;

  if tg_op = 'INSERT' then
    action_name := 'user_registered';
    perform public.log_audit_event(auth.uid(), action_name, 'user', new.id, new.full_name, agency_id, agency_name, 'User registered', null, to_jsonb(new));
    return new;
  elsif tg_op = 'UPDATE' then
    if old.deleted_at is distinct from new.deleted_at then
      action_name := case when new.deleted_at is null then 'user_activated' else 'user_suspended' end;
    else
      action_name := 'user_updated';
    end if;

    perform public.log_audit_event(auth.uid(), action_name, 'user', new.id, new.full_name, agency_id, agency_name, null, to_jsonb(old), to_jsonb(new));
    return new;
  else
    perform public.log_audit_event(auth.uid(), 'user_deleted', 'user', old.id, old.full_name, agency_id, agency_name, null, to_jsonb(old), null);
    return old;
  end if;
end;
$$;

create or replace function public.audit_rooms_trigger()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  agency_id uuid;
  agency_name text;
begin
  select a.id, a.name
  into agency_id, agency_name
  from public.agencies a
  join public.rooms r on r.admin_id = a.admin_id
  where r.id = coalesce(new.id, old.id)
  limit 1;

  if tg_op = 'INSERT' then
    perform public.log_audit_event(auth.uid(), 'room_created', 'room', new.id, new.name, agency_id, agency_name, 'Room created', null, to_jsonb(new));
    return new;
  elsif tg_op = 'UPDATE' then
    if old.deleted_at is distinct from new.deleted_at and new.deleted_at is null then
      perform public.log_audit_event(auth.uid(), 'room_restored', 'room', new.id, new.name, agency_id, agency_name, 'Room restored', to_jsonb(old), to_jsonb(new));
    elsif old.deleted_at is distinct from new.deleted_at and new.deleted_at is not null then
      perform public.log_audit_event(auth.uid(), 'room_deleted', 'room', new.id, new.name, agency_id, agency_name, 'Room deleted', to_jsonb(old), to_jsonb(new));
    else
      perform public.log_audit_event(auth.uid(), 'room_updated', 'room', new.id, new.name, agency_id, agency_name, 'Room updated', to_jsonb(old), to_jsonb(new));
    end if;
    return new;
  else
    perform public.log_audit_event(auth.uid(), 'room_deleted', 'room', old.id, old.name, agency_id, agency_name, 'Room deleted', to_jsonb(old), null);
    return old;
  end if;
end;
$$;

create or replace function public.audit_bookings_trigger()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  action_name text;
  room_name text;
  agency_id uuid;
  agency_name text;
begin
  select r.name, a.id, a.name
  into room_name, agency_id, agency_name
  from public.rooms r
  left join public.agencies a on a.admin_id = r.admin_id
  where r.id = coalesce(new.room_id, old.room_id)
  limit 1;

  if tg_op = 'INSERT' then
    action_name := 'booking_created';
    perform public.log_audit_event(auth.uid(), action_name, 'booking', new.id, room_name, agency_id, agency_name, 'Booking created', null, to_jsonb(new));
    return new;
  elsif tg_op = 'UPDATE' then
    if old.status is distinct from new.status then
      action_name := case new.status
        when 'confirmed' then 'booking_approved'
        when 'cancelled' then 'booking_cancelled'
        when 'completed' then 'booking_completed'
        when 'rejected' then 'booking_rejected'
        else 'booking_updated'
      end;
    else
      action_name := 'booking_updated';
    end if;
    perform public.log_audit_event(auth.uid(), action_name, 'booking', new.id, room_name, agency_id, agency_name, null, to_jsonb(old), to_jsonb(new));
    return new;
  else
    perform public.log_audit_event(auth.uid(), 'booking_deleted', 'booking', old.id, room_name, agency_id, agency_name, 'Booking deleted', to_jsonb(old), null);
    return old;
  end if;
end;
$$;

