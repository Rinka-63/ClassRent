-- Stable soft-delete endpoint for rooms.
-- This avoids client-side UPDATE being blocked by RLS while still enforcing
-- that an admin may only soft-delete rooms owned by their own approved agency.

create or replace function public.soft_delete_room(p_room_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor_id uuid := auth.uid();
  v_old_room jsonb;
  v_is_allowed boolean;
  v_deleted_at timestamptz := now();
begin
  if v_actor_id is null then
    raise exception 'Not authenticated';
  end if;

  select to_jsonb(r)
    into v_old_room
  from public.rooms r
  where r.id = p_room_id;

  if v_old_room is null then
    raise exception 'Room not found';
  end if;

  select
    public.is_super_admin()
    or exists (
      select 1
      from public.rooms r
      join public.agencies a on a.admin_id = r.admin_id
      where r.id = p_room_id
        and r.admin_id = v_actor_id
        and a.approval_status = 'approved'
        and a.is_active = true
    )
    into v_is_allowed;

  if coalesce(v_is_allowed, false) = false then
    raise exception 'Not allowed to delete this room';
  end if;

  update public.rooms
  set
    is_active = false,
    deleted_at = coalesce(deleted_at, v_deleted_at),
    updated_at = v_deleted_at
  where id = p_room_id;

  insert into public.audit_logs (
    actor_id,
    action,
    entity_type,
    entity_id,
    old,
    new
  ) values (
    v_actor_id,
    'delete_room',
    'room',
    p_room_id,
    v_old_room,
    (
      select to_jsonb(r)
      from public.rooms r
      where r.id = p_room_id
    )
  );
end;
$$;

grant execute on function public.soft_delete_room(uuid) to authenticated;
