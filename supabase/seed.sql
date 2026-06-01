-- ClassRent Final Blueprint v2.0 - MVP seed data
-- Demo password for all seeded users: ClassRent123!

insert into auth.users (
  id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_user_meta_data, created_at, updated_at
) values
  ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'superadmin@classrent.test', crypt('ClassRent123!', gen_salt('bf')), now(), '{"full_name":"ClassRent Super Admin"}', now(), now()),
  ('00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'admin@classrent.test', crypt('ClassRent123!', gen_salt('bf')), now(), '{"full_name":"Admin Gedung UNSRI"}', now(), now()),
  ('00000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'staff@classrent.test', crypt('ClassRent123!', gen_salt('bf')), now(), '{"full_name":"Staff Operasional"}', now(), now()),
  ('00000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'user@classrent.test', crypt('ClassRent123!', gen_salt('bf')), now(), '{"full_name":"Mahasiswa Demo"}', now(), now())
on conflict (id) do nothing;

insert into public.users (id, email, full_name, phone, role, is_verified) values
  ('00000000-0000-0000-0000-000000000001', 'superadmin@classrent.test', 'ClassRent Super Admin', '+628111111111', 'super_admin', true),
  ('00000000-0000-0000-0000-000000000002', 'admin@classrent.test', 'Admin Gedung UNSRI', '+628122222222', 'admin', true),
  ('00000000-0000-0000-0000-000000000003', 'staff@classrent.test', 'Staff Operasional', '+628133333333', 'staff', true),
  ('00000000-0000-0000-0000-000000000004', 'user@classrent.test', 'Mahasiswa Demo', '+628144444444', 'user', true)
on conflict (id) do update set role = excluded.role, full_name = excluded.full_name;

insert into public.facilities (id, admin_id, name, slug, address, city, lat, lng, description) values
  ('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002', 'Gedung A UNSRI', 'gedung-a-unsri', 'Jl. Palembang-Prabumulih KM 32, Indralaya', 'Indralaya', -3.22000000, 104.65000000, 'Fasilitas ruang kelas dan rapat untuk kebutuhan akademik.'),
  ('10000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000002', 'Gedung B UNSRI', 'gedung-b-unsri', 'Kampus Universitas Sriwijaya, Indralaya', 'Indralaya', -3.22100000, 104.65100000, 'Fasilitas aula, studio, dan ruang kegiatan mahasiswa.')
on conflict (id) do nothing;

insert into public.rooms (id, facility_id, admin_id, name, description, room_type, capacity, area_sqm, hourly_rate, daily_rate, dp_percentage, minimum_hours, buffer_minutes, requires_approval, approval_note, city, address) values
  ('20000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002', 'Ruang Kelas A101', 'Ruang kelas nyaman dengan proyektor, AC, whiteboard, dan Wi-Fi.', 'classroom', 40, 72.00, 75000, 450000, 30, 1, 15, false, null, 'Indralaya', 'Gedung A Lantai 1'),
  ('20000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002', 'Meeting Room A205', 'Ruang rapat kecil untuk diskusi tim dan seminar mini.', 'meeting_room', 16, 36.00, 60000, 350000, 30, 1, 15, false, null, 'Indralaya', 'Gedung A Lantai 2'),
  ('20000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000002', 'Aula Besar B', 'Aula untuk kegiatan besar, workshop, dan acara organisasi.', 'hall', 150, 220.00, 250000, 1500000, 50, 2, 30, true, 'Booking aula memerlukan persetujuan admin minimal H-1.', 'Indralaya', 'Gedung B Lantai 1')
on conflict (id) do nothing;

insert into public.room_facilities (room_id, facility_tag) values
  ('20000000-0000-0000-0000-000000000001', 'projector'),
  ('20000000-0000-0000-0000-000000000001', 'ac'),
  ('20000000-0000-0000-0000-000000000001', 'whiteboard'),
  ('20000000-0000-0000-0000-000000000001', 'wifi'),
  ('20000000-0000-0000-0000-000000000002', 'tv'),
  ('20000000-0000-0000-0000-000000000002', 'wifi'),
  ('20000000-0000-0000-0000-000000000003', 'sound_system'),
  ('20000000-0000-0000-0000-000000000003', 'stage')
on conflict do nothing;

insert into public.room_schedules (room_id, day_of_week, open_time, close_time, is_closed)
select room_id, day_of_week, '08:00'::time, '18:00'::time, false
from (values
  ('20000000-0000-0000-0000-000000000001'::uuid),
  ('20000000-0000-0000-0000-000000000002'::uuid),
  ('20000000-0000-0000-0000-000000000003'::uuid)
) r(room_id)
cross join generate_series(1, 6) day_of_week
on conflict (room_id, day_of_week) do nothing;

insert into public.pricing_rules (id, facility_id, room_id, rule_type, name, multiplier, start_time, end_time, days_of_week, is_active, priority, created_by) values
  ('30000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', null, 'peak_hour', 'Peak Hours', 1.50, '08:00', '10:00', null, true, 20, '00000000-0000-0000-0000-000000000002'),
  ('30000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000001', null, 'weekend', 'Weekend Rate', 1.30, null, null, array[0,6], true, 10, '00000000-0000-0000-0000-000000000002'),
  ('30000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-000000000003', 'peak_hour', 'Off-Peak Discount', 0.80, '12:00', '14:00', null, true, 5, '00000000-0000-0000-0000-000000000002')
on conflict (id) do nothing;

insert into public.coupons (id, facility_id, code, name, description, discount_type, discount_value, max_discount_amount, min_booking_amount, usage_limit, per_user_limit, valid_from, valid_until, created_by) values
  ('40000000-0000-0000-0000-000000000001', null, 'WELCOME20', 'Welcome 20%', 'Promo platform untuk pengguna baru.', 'percentage', 20, 50000, 100000, 100, 1, now() - interval '1 day', now() + interval '180 days', '00000000-0000-0000-0000-000000000001'),
  ('40000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000001', 'FLAT50K', 'Potongan Rp50.000', 'Diskon fasilitas Gedung A untuk booking minimal Rp150.000.', 'fixed_amount', 50000, null, 150000, 50, 1, now() - interval '1 day', now() + interval '90 days', '00000000-0000-0000-0000-000000000002'),
  ('40000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000001', 'FREE1HR', 'Gratis 1 Jam', 'Promo satu jam gratis untuk kelas dan meeting room.', 'free_hours', 1, null, 120000, 25, 1, now() - interval '1 day', now() + interval '60 days', '00000000-0000-0000-0000-000000000002')
on conflict (id) do nothing;

insert into public.staff_room_assignments (staff_id, room_id, facility_id, assigned_by) values
  ('00000000-0000-0000-0000-000000000003', '20000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002'),
  ('00000000-0000-0000-0000-000000000003', '20000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002')
on conflict do nothing;

insert into public.blackout_dates (id, facility_id, title, start_date, end_date, is_recurring, scope, created_by) values
  ('50000000-0000-0000-0000-000000000001', null, 'Libur Nasional Tahun Baru', '2026-01-01', '2026-01-01', true, 'platform', '00000000-0000-0000-0000-000000000001'),
  ('50000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000001', 'Maintenance Gedung A', '2026-06-15', '2026-06-15', false, 'facility', '00000000-0000-0000-0000-000000000002')
on conflict (id) do nothing;

insert into public.notifications (user_id, type, title, body, data) values
  ('00000000-0000-0000-0000-000000000004', 'booking_confirmed', 'Selamat datang di ClassRent', 'Akun demo siap digunakan untuk mencoba alur booking.', '{"route":"/home"}')
on conflict do nothing;

insert into public.system_settings (key, value, description, updated_by) values
  ('maintenance_mode', '{"enabled":false,"message":"ClassRent is operating normally."}', 'Global maintenance-mode flag for redirect guard.', '00000000-0000-0000-0000-000000000001'),
  ('terms_version', '{"current":"1.0.0","required":true}', 'Current Terms of Service version.', '00000000-0000-0000-0000-000000000001'),
  ('privacy_version', '{"current":"1.0.0","required":true}', 'Current Privacy Policy version.', '00000000-0000-0000-0000-000000000001'),
  ('default_dp_percentage', '{"value":30}', 'Default DP percentage for rooms when not overridden.', '00000000-0000-0000-0000-000000000001')
on conflict (key) do update set value = excluded.value, description = excluded.description, updated_by = excluded.updated_by, updated_at = now();

insert into public.user_consents (user_id, consent_type, version, accepted, accepted_at) values
  ('00000000-0000-0000-0000-000000000004', 'terms', '1.0.0', true, now()),
  ('00000000-0000-0000-0000-000000000004', 'privacy', '1.0.0', true, now())
on conflict (user_id, consent_type, version) do nothing;
