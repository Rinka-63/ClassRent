create or replace function get_agency_audit_logs(p_admin_id uuid)
returns table (
  id uuid,
  actor_id uuid,
  action text,
  entity_type text,
  entity_id uuid,
  old jsonb,
  new jsonb,
  created_at timestamptz,
  actor_name text
) as $$
begin
  return query
  select 
    a.id, 
    a.actor_id, 
    a.action, 
    a.entity_type, 
    a.entity_id, 
    a.old, 
    a.new, 
    a.created_at, 
    u.full_name as actor_name
  from audit_logs a
  left join users u on u.id = a.actor_id
  where a.actor_id = p_admin_id
     or (a.entity_type = 'agency' and a.entity_id = p_admin_id)
     or (a.entity_type = 'room' and a.entity_id in (select r.id from rooms r where r.admin_id = p_admin_id))
     or (a.entity_type = 'booking' and a.entity_id in (select b.id from bookings b join rooms r on r.id = b.room_id where r.admin_id = p_admin_id))
     or (a.entity_type = 'payment' and a.entity_id in (select p.id from payments p join bookings b on b.id = p.booking_id join rooms r on r.id = b.room_id where r.admin_id = p_admin_id))
  order by a.created_at desc;
end;
$$ language plpgsql security definer;
