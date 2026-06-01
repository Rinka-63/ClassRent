-- ClassRent Final Blueprint v2.0 - core schema

create extension if not exists "pgcrypto";
create extension if not exists "btree_gist";
create extension if not exists "pg_trgm";

create table if not exists public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  email text unique not null,
  full_name text not null,
  phone text,
  avatar_url text,
  role text not null default 'user' check (role in ('user','staff','admin','super_admin')),
  is_verified boolean not null default false,
  fcm_token text,
  deleted_at timestamptz,
  deletion_reason text,
  anonymized_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.facilities (
  id uuid primary key default gen_random_uuid(),
  admin_id uuid not null references public.users(id),
  name text not null,
  slug text unique not null,
  address text,
  city text,
  lat decimal(10,8),
  lng decimal(11,8),
  logo_url text,
  description text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.rooms (
  id uuid primary key default gen_random_uuid(),
  facility_id uuid references public.facilities(id),
  admin_id uuid not null references public.users(id),
  name text not null,
  description text,
  room_type text check (room_type in ('classroom','meeting_room','studio','hall')),
  capacity int not null check (capacity > 0),
  area_sqm numeric(6,2),
  hourly_rate numeric(12,2) not null check (hourly_rate >= 0),
  daily_rate numeric(12,2),
  dp_percentage int not null default 30 check (dp_percentage between 0 and 100),
  minimum_hours int not null default 1 check (minimum_hours > 0),
  buffer_minutes int not null default 15 check (buffer_minutes >= 0),
  requires_approval boolean not null default false,
  approval_note text,
  avg_rating decimal(3,2) not null default 0,
  review_count integer not null default 0,
  is_active boolean not null default true,
  search_vector tsvector,
  city text not null,
  address text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists public.room_facilities (
  room_id uuid not null references public.rooms(id) on delete cascade,
  facility_tag text not null,
  primary key (room_id, facility_tag)
);

create table if not exists public.room_images (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.rooms(id) on delete cascade,
  original_url text not null,
  compressed_url text,
  thumbnail_url text,
  display_order int not null default 0,
  is_primary boolean not null default false,
  file_size_kb int,
  width_px int,
  height_px int,
  created_at timestamptz not null default now()
);

create table if not exists public.pricing_rules (
  id uuid primary key default gen_random_uuid(),
  room_id uuid references public.rooms(id) on delete cascade,
  facility_id uuid references public.facilities(id) on delete cascade,
  rule_type text not null check (rule_type in ('peak_hour','weekend','holiday','seasonal','event')),
  name text not null,
  multiplier numeric(4,2) not null check (multiplier > 0),
  start_time time,
  end_time time,
  days_of_week int[],
  start_date date,
  end_date date,
  is_active boolean not null default true,
  priority int not null default 0,
  created_by uuid references public.users(id),
  created_at timestamptz not null default now(),
  check (room_id is not null or facility_id is not null)
);

create table if not exists public.coupons (
  id uuid primary key default gen_random_uuid(),
  facility_id uuid references public.facilities(id),
  code text unique not null,
  name text not null,
  description text,
  discount_type text not null check (discount_type in ('percentage','fixed_amount','free_hours')),
  discount_value numeric(10,2) not null check (discount_value >= 0),
  max_discount_amount numeric(12,2),
  min_booking_amount numeric(12,2) not null default 0,
  usage_limit int,
  usage_count int not null default 0,
  per_user_limit int not null default 1,
  valid_from timestamptz not null,
  valid_until timestamptz,
  applicable_rooms uuid[],
  applicable_days int[],
  is_active boolean not null default true,
  created_by uuid references public.users(id),
  created_at timestamptz not null default now(),
  check (valid_until is null or valid_until > valid_from)
);

create table if not exists public.bookings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id),
  room_id uuid not null references public.rooms(id),
  facility_id uuid references public.facilities(id),
  booking_date date not null,
  start_time time not null,
  end_time time not null,
  total_hours numeric(5,2) generated always as (extract(epoch from (end_time - start_time)) / 3600) stored,
  base_price numeric(12,2) not null,
  pricing_multiplier numeric(4,2) not null default 1.00,
  dynamic_price numeric(12,2),
  coupon_id uuid references public.coupons(id),
  discount_amount numeric(12,2) not null default 0,
  final_price numeric(12,2) not null,
  dp_amount numeric(12,2) not null default 0,
  remaining_amount numeric(12,2) not null default 0,
  status text not null default 'pending_payment' check (status in ('draft','pending_approval','pending_payment','pending_checkin','confirmed','checked_in','checked_out','completed','cancelled','rejected','no_show','expired','refunded')),
  rejection_reason text,
  qr_token text unique,
  qr_used_at timestamptz,
  expires_at timestamptz not null default now() + interval '15 minutes',
  checked_in_at timestamptz,
  checked_out_at timestamptz,
  verified_by uuid references public.users(id),
  notes text,
  version int not null default 1,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  check (end_time > start_time),
  constraint no_overlap exclude using gist (
    room_id with =,
    tsrange(booking_date + start_time, booking_date + end_time) with &&
  ) where (status not in ('cancelled','refunded','rejected','expired','draft') and deleted_at is null)
);

create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings(id),
  user_id uuid not null references public.users(id),
  amount numeric(12,2) not null check (amount >= 0),
  payment_method text,
  midtrans_order_id text unique,
  midtrans_transaction_id text,
  snap_token text,
  status text not null default 'pending' check (status in ('pending','settlement','capture','deny','cancel','expire','refund')),
  is_dp boolean not null default false,
  webhook_payload jsonb,
  verified_by uuid references public.users(id),
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.payment_logs (
  id uuid primary key default gen_random_uuid(),
  payment_id uuid not null references public.payments(id),
  booking_id uuid references public.bookings(id),
  event_type text not null,
  from_status text,
  to_status text,
  midtrans_order_id text,
  gross_amount bigint,
  raw_payload jsonb,
  actor_id uuid references public.users(id),
  ip_address inet,
  created_at timestamptz not null default now()
);

create table if not exists public.payment_refunds (
  id uuid primary key default gen_random_uuid(),
  payment_id uuid not null references public.payments(id),
  amount numeric(12,2) not null check (amount >= 0),
  percentage numeric(5,2),
  status text not null default 'pending' check (status in ('pending','processing','processed','failed','cancelled')),
  reason text,
  processed_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.coupon_redemptions (
  id uuid primary key default gen_random_uuid(),
  coupon_id uuid not null references public.coupons(id),
  user_id uuid not null references public.users(id),
  booking_id uuid not null references public.bookings(id),
  discount_applied numeric(12,2) not null,
  redeemed_at timestamptz not null default now(),
  unique (coupon_id, booking_id)
);

create table if not exists public.room_schedules (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.rooms(id) on delete cascade,
  day_of_week int not null check (day_of_week between 0 and 6),
  open_time time not null,
  close_time time not null,
  is_closed boolean not null default false,
  unique (room_id, day_of_week),
  check (close_time > open_time)
);

create table if not exists public.blackout_dates (
  id uuid primary key default gen_random_uuid(),
  facility_id uuid references public.facilities(id),
  title text not null,
  start_date date not null,
  end_date date not null,
  is_recurring boolean not null default false,
  scope text not null default 'facility' check (scope in ('platform','facility')),
  created_by uuid references public.users(id),
  created_at timestamptz not null default now(),
  check (end_date >= start_date)
);

create table if not exists public.maintenance_schedules (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.rooms(id) on delete cascade,
  title text not null,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  is_recurring boolean not null default false,
  recur_rule text,
  created_by uuid references public.users(id),
  created_at timestamptz not null default now(),
  check (ends_at > starts_at)
);

create table if not exists public.reviews (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.rooms(id) on delete cascade,
  booking_id uuid not null references public.bookings(id),
  user_id uuid not null references public.users(id),
  rating int not null check (rating between 1 and 5),
  comment text,
  is_anonymous boolean not null default false,
  is_published boolean not null default true,
  admin_reply text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (booking_id)
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  type text not null,
  title text not null,
  body text not null,
  data jsonb not null default '{}'::jsonb,
  is_read boolean not null default false,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references public.users(id),
  action text not null,
  entity_type text not null,
  entity_id uuid,
  old jsonb,
  new jsonb,
  ip inet,
  created_at timestamptz not null default now()
);

create table if not exists public.system_settings (
  id uuid primary key default gen_random_uuid(),
  key text unique not null,
  value jsonb not null default '{}'::jsonb,
  description text,
  updated_by uuid references public.users(id),
  updated_at timestamptz not null default now()
);

create table if not exists public.user_favorites (
  user_id uuid not null references public.users(id) on delete cascade,
  room_id uuid not null references public.rooms(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, room_id)
);

create table if not exists public.waitlist (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.rooms(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  booking_date date not null,
  start_time time not null,
  end_time time not null,
  status text not null default 'waiting' check (status in ('waiting','notified','booked','expired','cancelled')),
  notified_at timestamptz,
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  check (end_time > start_time)
);

create table if not exists public.user_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  device_id text not null,
  device_name text,
  device_os text,
  fcm_token text,
  last_seen_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  unique (user_id, device_id)
);

create table if not exists public.user_consents (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  consent_type text not null,
  version text not null,
  accepted boolean not null default false,
  accepted_at timestamptz,
  ip_address inet,
  created_at timestamptz not null default now(),
  unique (user_id, consent_type, version)
);

create table if not exists public.staff_room_assignments (
  staff_id uuid not null references public.users(id) on delete cascade,
  room_id uuid not null references public.rooms(id) on delete cascade,
  facility_id uuid not null references public.facilities(id) on delete cascade,
  assigned_by uuid references public.users(id),
  created_at timestamptz not null default now(),
  primary key (staff_id, room_id)
);

create table if not exists public.support_tickets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id),
  facility_id uuid references public.facilities(id),
  booking_id uuid references public.bookings(id),
  subject text not null,
  category text not null check (category in ('payment','booking','facility','account','other')),
  status text not null default 'open' check (status in ('open','in_progress','resolved','closed')),
  priority text not null default 'normal' check (priority in ('low','normal','high','urgent')),
  assigned_to uuid references public.users(id),
  resolved_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.ticket_messages (
  id uuid primary key default gen_random_uuid(),
  ticket_id uuid not null references public.support_tickets(id) on delete cascade,
  sender_id uuid not null references public.users(id),
  body text not null,
  is_internal boolean not null default false,
  attachments jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now()
);

create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace function public.update_rooms_search_vector()
returns trigger language plpgsql as $$
begin
  new.search_vector :=
    setweight(to_tsvector('simple', coalesce(new.name,'')), 'A') ||
    setweight(to_tsvector('simple', coalesce(new.description,'')), 'B') ||
    setweight(to_tsvector('simple', coalesce(new.city,'')), 'C');
  return new;
end;
$$;

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.users (id, email, full_name, avatar_url)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name', new.email),
    new.raw_user_meta_data->>'avatar_url'
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

create or replace function public.update_room_rating()
returns trigger language plpgsql as $$
begin
  update public.rooms r
  set avg_rating = coalesce((select round(avg(rating)::numeric, 2) from public.reviews where room_id = coalesce(new.room_id, old.room_id) and is_published), 0),
      review_count = (select count(*) from public.reviews where room_id = coalesce(new.room_id, old.room_id) and is_published),
      updated_at = now()
  where r.id = coalesce(new.room_id, old.room_id);
  return coalesce(new, old);
end;
$$;

create or replace function public.anonymize_user(target_user_id uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  update public.users
  set email = 'deleted-' || target_user_id || '@classrent.local',
      full_name = 'Deleted User',
      phone = null,
      avatar_url = null,
      fcm_token = null,
      anonymized_at = now(),
      updated_at = now()
  where id = target_user_id and anonymized_at is null;
end;
$$;

create trigger users_set_updated_at before update on public.users for each row execute function public.set_updated_at();
create trigger facilities_set_updated_at before update on public.facilities for each row execute function public.set_updated_at();
create trigger rooms_set_updated_at before update on public.rooms for each row execute function public.set_updated_at();
create trigger bookings_set_updated_at before update on public.bookings for each row execute function public.set_updated_at();
create trigger payments_set_updated_at before update on public.payments for each row execute function public.set_updated_at();
create trigger reviews_set_updated_at before update on public.reviews for each row execute function public.set_updated_at();
create trigger support_tickets_set_updated_at before update on public.support_tickets for each row execute function public.set_updated_at();
create trigger rooms_search_update before insert or update on public.rooms for each row execute function public.update_rooms_search_vector();
create trigger reviews_update_room_rating after insert or update or delete on public.reviews for each row execute function public.update_room_rating();

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute function public.handle_new_user();

create index if not exists idx_rooms_search on public.rooms using gin(search_vector);
create index if not exists idx_rooms_active on public.rooms(is_active) where deleted_at is null;
create index if not exists idx_rooms_facility on public.rooms(facility_id);
create index if not exists idx_rooms_admin on public.rooms(admin_id);
create index if not exists idx_rooms_city_trgm on public.rooms using gin(city gin_trgm_ops);
create index if not exists idx_room_images_room on public.room_images(room_id, display_order);
create index if not exists idx_pricing_rules_room on public.pricing_rules(room_id, is_active);
create index if not exists idx_pricing_rules_facility on public.pricing_rules(facility_id, is_active);
create index if not exists idx_coupons_code on public.coupons(code) where is_active = true;
create index if not exists idx_coupons_facility on public.coupons(facility_id, is_active);
create index if not exists idx_redemptions_user on public.coupon_redemptions(user_id, coupon_id);
create index if not exists idx_bookings_room_date on public.bookings(room_id, booking_date);
create index if not exists idx_bookings_user on public.bookings(user_id);
create index if not exists idx_bookings_status on public.bookings(status);
create index if not exists idx_bookings_facility on public.bookings(facility_id);
create index if not exists idx_bookings_active_expiry on public.bookings(expires_at) where status = 'pending_payment';
create index if not exists idx_payments_booking on public.payments(booking_id);
create index if not exists idx_payments_user on public.payments(user_id);
create index if not exists idx_payments_status on public.payments(status);
create index if not exists idx_payment_logs_payment on public.payment_logs(payment_id, created_at);
create index if not exists idx_tickets_user on public.support_tickets(user_id, status);
create index if not exists idx_tickets_facility on public.support_tickets(facility_id, status);
create index if not exists idx_ticket_messages_ticket on public.ticket_messages(ticket_id, created_at);
create index if not exists idx_blackout_dates_range on public.blackout_dates(start_date, end_date);
create index if not exists idx_maintenance_room_range on public.maintenance_schedules(room_id, starts_at, ends_at);
create index if not exists idx_reviews_room on public.reviews(room_id, is_published);
create index if not exists idx_notifications_user_unread on public.notifications(user_id, is_read, created_at desc);
create index if not exists idx_waitlist_room_slot on public.waitlist(room_id, booking_date, start_time, end_time, status);
create index if not exists idx_user_sessions_user on public.user_sessions(user_id, last_seen_at desc);
create index if not exists idx_staff_assignments_facility on public.staff_room_assignments(facility_id, staff_id);

create materialized view if not exists public.room_analytics as
select
  r.id as room_id,
  r.name,
  r.facility_id,
  count(distinct b.id) as total_bookings,
  r.avg_rating,
  r.review_count,
  count(distinct uf.user_id) as favorites_count,
  count(distinct w.id) as waitlist_count,
  (count(distinct b.id) * 0.5 + r.avg_rating * 10 + count(distinct uf.user_id) * 0.3) as popularity_score
from public.rooms r
left join public.bookings b on b.room_id = r.id and b.status not in ('expired','rejected','cancelled')
left join public.user_favorites uf on uf.room_id = r.id
left join public.waitlist w on w.room_id = r.id and w.status = 'waiting'
group by r.id;

create unique index if not exists idx_room_analytics_room_id on public.room_analytics(room_id);
