-- Realtime notifications, FCM dispatch queue, reminders, and expired bookings.

alter table public.notifications
  add column if not exists receiver_id uuid references public.users(id) on delete cascade,
  add column if not exists sender_id uuid references public.users(id) on delete set null,
  add column if not exists reference_id uuid;

update public.notifications
set receiver_id = coalesce(receiver_id, user_id)
where receiver_id is null and user_id is not null;

alter table public.notifications alter column receiver_id set not null;

create index if not exists idx_notifications_receiver_unread
  on public.notifications(receiver_id, is_read, created_at desc);

drop policy if exists notifications_user_read on public.notifications;
drop policy if exists notifications_user_update_read on public.notifications;
drop policy if exists notifications_user_insert_own on public.notifications;

create policy notifications_receiver_read
on public.notifications for select
using (receiver_id = auth.uid() or public.is_super_admin());

create policy notifications_receiver_update_read
on public.notifications for update
using (receiver_id = auth.uid())
with check (receiver_id = auth.uid());

create policy notifications_service_insert
on public.notifications for insert
with check (receiver_id = auth.uid() or public.is_admin_or_super_admin());

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'notifications'
  ) then
    alter publication supabase_realtime add table public.notifications;
  end if;

  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'bookings'
  ) then
    alter publication supabase_realtime add table public.bookings;
  end if;
end $$;

create table if not exists public.notification_push_queue (
  id uuid primary key default gen_random_uuid(),
  notification_id uuid not null references public.notifications(id) on delete cascade,
  receiver_id uuid not null references public.users(id) on delete cascade,
  status text not null default 'pending' check (status in ('pending','sent','failed')),
  attempts int not null default 0,
  last_error text,
  created_at timestamptz not null default now(),
  sent_at timestamptz
);

create index if not exists idx_notification_push_queue_pending
  on public.notification_push_queue(status, created_at)
  where status = 'pending';

create or replace function public.enqueue_notification_push()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.notification_push_queue(notification_id, receiver_id)
  values (new.id, new.receiver_id);
  return new;
end;
$$;

drop trigger if exists enqueue_notification_push_trigger on public.notifications;
create trigger enqueue_notification_push_trigger
after insert on public.notifications
for each row execute function public.enqueue_notification_push();

create or replace function public.create_notification(
  p_receiver_id uuid,
  p_sender_id uuid,
  p_title text,
  p_body text,
  p_type text,
  p_reference_id uuid default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  notification_id uuid;
begin
  insert into public.notifications (
    receiver_id,
    sender_id,
    user_id,
    title,
    body,
    type,
    reference_id,
    data
  ) values (
    p_receiver_id,
    p_sender_id,
    p_receiver_id,
    p_title,
    p_body,
    p_type,
    p_reference_id,
    case when p_reference_id is null
      then '{}'::jsonb
      else jsonb_build_object('reference_id', p_reference_id)
    end
  )
  returning id into notification_id;

  return notification_id;
end;
$$;

grant execute on function public.create_notification(uuid, uuid, text, text, text, uuid)
to authenticated;

create or replace function public.notify_agency_registered()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  super_admin record;
begin
  if new.approval_status = 'pending' then
    for super_admin in
      select id from public.users where role = 'super_admin'
    loop
      perform public.create_notification(
        super_admin.id,
        new.admin_id,
        'Agency baru menunggu approval',
        coalesce(new.name, 'Agency baru') || ' baru saja mendaftar.',
        'agency_registered',
        new.id
      );
    end loop;
  end if;
  return new;
end;
$$;

drop trigger if exists notify_agency_registered_trigger on public.agencies;
create trigger notify_agency_registered_trigger
after insert on public.agencies
for each row execute function public.notify_agency_registered();

create or replace function public.notify_new_booking()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  room_name text;
  admin_id uuid;
begin
  select r.name, r.admin_id into room_name, admin_id
  from public.rooms r
  where r.id = new.room_id;

  if admin_id is not null then
    perform public.create_notification(
      admin_id,
      new.user_id,
      'Booking baru',
      'Booking untuk ' || coalesce(room_name, 'ruangan') || ' menunggu ditinjau.',
      'booking_created',
      new.id
    );
  end if;
  return new;
end;
$$;

drop trigger if exists on_booking_created on public.bookings;
create trigger on_booking_created
after insert on public.bookings
for each row execute function public.notify_new_booking();

create or replace function public.notify_booking_status_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if old.status is distinct from new.status then
    perform public.create_notification(
      new.user_id,
      coalesce(auth.uid(), new.verified_by),
      'Status booking diperbarui',
      'Status booking Anda berubah menjadi ' || new.status || '.',
      'booking_status_changed',
      new.id
    );
  end if;
  return new;
end;
$$;

drop trigger if exists on_booking_status_changed on public.bookings;
create trigger on_booking_status_changed
after update of status on public.bookings
for each row execute function public.notify_booking_status_change();

create or replace function public.process_booking_reminders()
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  item record;
  created_count int := 0;
begin
  for item in
    select b.id, b.user_id, b.room_id, b.booking_date, r.name as room_name, r.admin_id
    from public.bookings b
    join public.rooms r on r.id = b.room_id
    where b.booking_date = current_date + 1
      and b.status in ('pending_checkin','confirmed')
  loop
    if not exists (
      select 1 from public.notifications n
      where n.receiver_id = item.user_id
        and n.type = 'booking_reminder'
        and n.reference_id = item.id
    ) then
      perform public.create_notification(
        item.user_id,
        item.admin_id,
        'Reminder booking besok',
        'Booking ' || coalesce(item.room_name, 'ruangan') || ' dijadwalkan besok.',
        'booking_reminder',
        item.id
      );
      created_count := created_count + 1;
    end if;

    if not exists (
      select 1 from public.notifications n
      where n.receiver_id = item.admin_id
        and n.type = 'booking_reminder_admin'
        and n.reference_id = item.id
    ) then
      perform public.create_notification(
        item.admin_id,
        item.user_id,
        'Reminder booking besok',
        'Ada booking ' || coalesce(item.room_name, 'ruangan') || ' besok.',
        'booking_reminder_admin',
        item.id
      );
      created_count := created_count + 1;
    end if;
  end loop;
  return created_count;
end;
$$;

create or replace function public.expire_past_bookings()
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  updated_count int;
begin
  update public.bookings
  set status = 'expired',
      qr_token = null,
      updated_at = now()
  where status in ('pending_payment','pending_approval','pending_checkin','confirmed')
    and (booking_date + end_time) < now()
    and deleted_at is null;

  get diagnostics updated_count = row_count;
  return updated_count;
end;
$$;

grant execute on function public.process_booking_reminders() to authenticated;
grant execute on function public.expire_past_bookings() to authenticated;

insert into public.system_settings (key, value, description)
values (
  'app_version',
  jsonb_build_object(
    'latest_version_name', '0.1.0',
    'min_build_number', 3,
    'force_update', false,
    'android_store_url', 'https://play.google.com/store/apps/details?id=com.ti24a4.sewakelas'
  ),
  'Public app version gate used to force or suggest app updates.'
)
on conflict (key) do update
set value = public.system_settings.value || excluded.value,
    description = excluded.description,
    updated_at = now();

notify pgrst, 'reload schema';
