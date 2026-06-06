-- ClassRent Final Blueprint v2.0 - RLS policies

create or replace function public.current_user_role()
returns text language sql stable security definer set search_path = public as $$
  select role from public.users where id = auth.uid() and deleted_at is null
$$;

create or replace function public.is_super_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select coalesce(public.current_user_role() = 'super_admin', false)
$$;

create or replace function public.is_admin_or_super_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select coalesce(public.current_user_role() in ('admin','super_admin'), false)
$$;

create or replace function public.owns_facility(target_facility_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.facilities f
    where f.id = target_facility_id and f.admin_id = auth.uid()
  ) or public.is_super_admin()
$$;

create or replace function public.can_manage_room(target_room_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.rooms r
    where r.id = target_room_id and (r.admin_id = auth.uid() or public.owns_facility(r.facility_id))
  ) or public.is_super_admin()
$$;

create or replace function public.is_assigned_staff_for_room(target_room_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.staff_room_assignments s
    join public.users u on u.id = s.staff_id
    where s.room_id = target_room_id and s.staff_id = auth.uid() and u.role = 'staff'
  ) or public.can_manage_room(target_room_id)
$$;

alter table public.users enable row level security;
alter table public.facilities enable row level security;
alter table public.rooms enable row level security;
alter table public.room_facilities enable row level security;
alter table public.room_images enable row level security;
alter table public.pricing_rules enable row level security;
alter table public.coupons enable row level security;
alter table public.bookings enable row level security;
alter table public.payments enable row level security;
alter table public.payment_logs enable row level security;
alter table public.payment_refunds enable row level security;
alter table public.coupon_redemptions enable row level security;
alter table public.room_schedules enable row level security;
alter table public.blackout_dates enable row level security;
alter table public.maintenance_schedules enable row level security;
alter table public.reviews enable row level security;
alter table public.notifications enable row level security;
alter table public.audit_logs enable row level security;
alter table public.system_settings enable row level security;
alter table public.user_favorites enable row level security;
alter table public.waitlist enable row level security;
alter table public.user_sessions enable row level security;
alter table public.user_consents enable row level security;
alter table public.staff_room_assignments enable row level security;
alter table public.support_tickets enable row level security;
alter table public.ticket_messages enable row level security;

create policy users_select_own_or_admin on public.users for select using (id = auth.uid() or public.is_admin_or_super_admin());
create policy users_update_own_basic on public.users for update using (id = auth.uid()) with check (id = auth.uid() and role = (select role from public.users where id = auth.uid()));
create policy users_admin_update on public.users for update using (public.is_super_admin()) with check (public.is_super_admin());

create policy facilities_public_read_active on public.facilities for select using (is_active = true or public.owns_facility(id));
create policy facilities_admin_insert on public.facilities for insert with check (admin_id = auth.uid() or public.is_super_admin());
create policy facilities_admin_update on public.facilities for update using (public.owns_facility(id)) with check (public.owns_facility(id));
create policy facilities_admin_delete on public.facilities for delete using (public.is_super_admin());

create policy rooms_public_read on public.rooms for select using (is_active = true and deleted_at is null);
create policy rooms_admin_insert on public.rooms for insert with check (admin_id = auth.uid() and public.owns_facility(facility_id));
create policy rooms_admin_update on public.rooms for update using (public.can_manage_room(id)) with check (public.can_manage_room(id));
create policy rooms_admin_delete on public.rooms for delete using (public.can_manage_room(id));

create policy room_facilities_public_read on public.room_facilities for select using (exists (select 1 from public.rooms r where r.id = room_id and r.is_active and r.deleted_at is null));
create policy room_facilities_admin_write on public.room_facilities for all using (public.can_manage_room(room_id)) with check (public.can_manage_room(room_id));

create policy room_images_public_read on public.room_images for select using (exists (select 1 from public.rooms r where r.id = room_id and r.is_active and r.deleted_at is null));
create policy room_images_admin_write on public.room_images for all using (public.can_manage_room(room_id)) with check (public.can_manage_room(room_id));

create policy pricing_public_read_active on public.pricing_rules for select using (is_active = true);
create policy pricing_admin_manage on public.pricing_rules for all using (public.owns_facility(facility_id) or public.can_manage_room(room_id)) with check (public.owns_facility(facility_id) or public.can_manage_room(room_id));

create policy coupons_user_read_active on public.coupons for select using (is_active = true and now() >= valid_from and (valid_until is null or now() <= valid_until));
create policy coupons_admin_manage on public.coupons for all using (facility_id is null and public.is_super_admin() or public.owns_facility(facility_id)) with check (facility_id is null and public.is_super_admin() or public.owns_facility(facility_id));

create policy bookings_user_select on public.bookings for select using (user_id = auth.uid() or public.owns_facility(facility_id) or public.is_assigned_staff_for_room(room_id));
create policy bookings_user_insert on public.bookings for insert with check (user_id = auth.uid());
create policy bookings_user_update_cancel on public.bookings for update using (user_id = auth.uid() and status in ('draft','pending_approval','pending_payment','confirmed','pending_checkin')) with check (user_id = auth.uid());
create policy bookings_staff_admin_update on public.bookings for update using (public.owns_facility(facility_id) or public.is_assigned_staff_for_room(room_id)) with check (public.owns_facility(facility_id) or public.is_assigned_staff_for_room(room_id));

create policy payments_user_read on public.payments for select using (user_id = auth.uid() or exists (select 1 from public.bookings b where b.id = booking_id and (public.owns_facility(b.facility_id) or public.is_assigned_staff_for_room(b.room_id))));
create policy payments_service_insert_hint on public.payments for insert with check (user_id = auth.uid());
create policy payments_admin_read on public.payment_logs for select using (exists (select 1 from public.bookings b where b.id = booking_id and public.owns_facility(b.facility_id)) or public.is_super_admin());
create policy payment_refunds_admin_read on public.payment_refunds for select using (exists (select 1 from public.payments p join public.bookings b on b.id = p.booking_id where p.id = payment_id and public.owns_facility(b.facility_id)) or public.is_super_admin());

create policy redemptions_user_read on public.coupon_redemptions for select using (user_id = auth.uid() or exists (select 1 from public.bookings b where b.id = booking_id and public.owns_facility(b.facility_id)) or public.is_super_admin());

create policy schedules_public_read on public.room_schedules for select using (exists (select 1 from public.rooms r where r.id = room_id and r.is_active));
create policy schedules_admin_manage on public.room_schedules for all using (public.can_manage_room(room_id)) with check (public.can_manage_room(room_id));

create policy blackout_public_read on public.blackout_dates for select using (true);
create policy blackout_admin_manage on public.blackout_dates for all using ((facility_id is null and public.is_super_admin()) or public.owns_facility(facility_id)) with check ((facility_id is null and public.is_super_admin()) or public.owns_facility(facility_id));

create policy maintenance_public_read on public.maintenance_schedules for select using (true);
create policy maintenance_admin_manage on public.maintenance_schedules for all using (public.can_manage_room(room_id)) with check (public.can_manage_room(room_id));

create policy reviews_public_read_published on public.reviews for select using (is_published = true or user_id = auth.uid() or public.can_manage_room(room_id));
create policy reviews_user_insert on public.reviews for insert with check (user_id = auth.uid());
create policy reviews_user_update_own on public.reviews for update using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy reviews_admin_moderate on public.reviews for update using (public.can_manage_room(room_id)) with check (public.can_manage_room(room_id));

create policy notifications_user_read on public.notifications for select using (user_id = auth.uid());
create policy notifications_user_update_read on public.notifications for update using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy audit_admin_read on public.audit_logs for select using (public.is_admin_or_super_admin());
create policy settings_public_read_safe on public.system_settings for select using (key in ('maintenance_mode','app_version','terms_version','privacy_version'));
create policy settings_super_admin_manage on public.system_settings for all using (public.is_super_admin()) with check (public.is_super_admin());

create policy favorites_user_manage on public.user_favorites for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy waitlist_user_read on public.waitlist for select using (user_id = auth.uid() or public.can_manage_room(room_id));
create policy waitlist_user_insert on public.waitlist for insert with check (user_id = auth.uid());
create policy waitlist_user_update on public.waitlist for update using (user_id = auth.uid() or public.can_manage_room(room_id)) with check (user_id = auth.uid() or public.can_manage_room(room_id));

create policy sessions_user_manage on public.user_sessions for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy consents_user_manage on public.user_consents for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy staff_assignments_admin_read on public.staff_room_assignments for select using (staff_id = auth.uid() or public.owns_facility(facility_id));
create policy staff_assignments_admin_manage on public.staff_room_assignments for all using (public.owns_facility(facility_id)) with check (public.owns_facility(facility_id));

create policy tickets_user_read on public.support_tickets for select using (user_id = auth.uid() or public.owns_facility(facility_id) or assigned_to = auth.uid() or public.is_super_admin());
create policy tickets_user_insert on public.support_tickets for insert with check (user_id = auth.uid());
create policy tickets_participant_update on public.support_tickets for update using (user_id = auth.uid() or public.owns_facility(facility_id) or assigned_to = auth.uid() or public.is_super_admin()) with check (user_id = auth.uid() or public.owns_facility(facility_id) or assigned_to = auth.uid() or public.is_super_admin());

create policy messages_participant_read on public.ticket_messages for select using (
  exists (
    select 1 from public.support_tickets t
    where t.id = ticket_id
      and (t.user_id = auth.uid() or public.owns_facility(t.facility_id) or t.assigned_to = auth.uid() or public.is_super_admin())
      and (is_internal = false or public.owns_facility(t.facility_id) or t.assigned_to = auth.uid() or public.is_super_admin())
  )
);
create policy messages_participant_insert on public.ticket_messages for insert with check (
  sender_id = auth.uid() and exists (
    select 1 from public.support_tickets t
    where t.id = ticket_id
      and (t.user_id = auth.uid() or public.owns_facility(t.facility_id) or t.assigned_to = auth.uid() or public.is_super_admin())
      and (is_internal = false or public.owns_facility(t.facility_id) or t.assigned_to = auth.uid() or public.is_super_admin())
  )
);
