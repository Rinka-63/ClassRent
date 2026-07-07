-- Create triggers for automatic notification creation
-- These triggers will create notifications based on booking and payment events

-- Function to create notification for new booking
create or replace function notify_new_booking()
returns trigger as $$
begin
  insert into public.notifications (user_id, type, title, body, data)
  values (
    new.user_id,
    'booking_created',
    'Booking Baru Dibuat',
    'Booking untuk ' || (select name from public.rooms where id = new.room_id) || ' berhasil dibuat.',
    jsonb_build_object(
      'booking_id', new.id,
      'room_id', new.room_id,
      'booking_date', new.booking_date,
      'start_time', new.start_time,
      'end_time', new.end_time
    )
  );
  return new;
end;
$$ language plpgsql;

-- Trigger for new bookings
drop trigger if exists on_booking_created on public.bookings;
create trigger on_booking_created
after insert on public.bookings
for each row
execute function notify_new_booking();

-- Function to create notification for booking status changes
create or replace function notify_booking_status_change()
returns trigger as $$
begin
  if old.status != new.status then
    insert into public.notifications (user_id, type, title, body, data)
    values (
      new.user_id,
      'booking_status_changed',
      'Status Booking Diperbarui',
      'Status booking Anda berubah menjadi ' || new.status,
      jsonb_build_object(
        'booking_id', new.id,
        'old_status', old.status,
        'new_status', new.status
      )
    );
  end if;
  return new;
end;
$$ language plpgsql;

-- Trigger for booking status changes
drop trigger if exists on_booking_status_changed on public.bookings;
create trigger on_booking_status_changed
after update of status on public.bookings
for each row
execute function notify_booking_status_change();

-- Function to create notification for payment status changes
create or replace function notify_payment_status_change()
returns trigger as $$
declare
  user_id uuid;
begin
  -- Get user_id from booking
  select user_id into user_id from public.bookings where id = new.booking_id;
  
  if user_id is not null and old.status != new.status then
    insert into public.notifications (user_id, type, title, body, data)
    values (
      user_id,
      'payment_status_changed',
      'Status Pembayaran Diperbarui',
      'Status pembayaran Anda: ' || new.status,
      jsonb_build_object(
        'payment_id', new.id,
        'booking_id', new.booking_id,
        'old_status', old.status,
        'new_status', new.status
      )
    );
  end if;
  return new;
end;
$$ language plpgsql;

-- Trigger for payment status changes
drop trigger if exists on_payment_status_changed on public.payments;
create trigger on_payment_status_changed
after update of status on public.payments
for each row
execute function notify_payment_status_change();
