-- Sync payment status with booking status
-- When payment is settled/captured, mark booking as confirmed
-- When payment is denied/cancelled/expired, mark booking as cancelled

-- Function to update booking status based on payment status
create or replace function handle_payment_status_update()
returns trigger as $$
begin
  -- Payment successful
  if new.status in ('settlement', 'capture') then
    update public.bookings
    set status = 'confirmed',
        updated_at = now()
    where id = new.booking_id
      and status = 'pending_payment';
  
  -- Payment failed
  elseif new.status in ('deny', 'cancel', 'expire', 'failure') then
    update public.bookings
    set status = 'cancelled',
        updated_at = now()
    where id = new.booking_id
      and status = 'pending_payment';
  end if;
  
  return new;
end;
$$ language plpgsql;

-- Trigger to call the function when payment status changes
drop trigger if exists on_payment_status_update on public.payments;
create trigger on_payment_status_update
after update of status on public.payments
for each row
execute function handle_payment_status_update();

-- Function to handle new payment creation
create or replace function handle_payment_insert()
returns trigger as $$
begin
  -- If payment is created with settlement/capture status (rare but possible)
  if new.status in ('settlement', 'capture') then
    update public.bookings
    set status = 'confirmed',
        updated_at = now()
    where id = new.booking_id
      and status = 'pending_payment';
  end if;
  
  return new;
end;
$$ language plpgsql;

-- Trigger to call the function when payment is created
drop trigger if exists on_payment_insert on public.payments;
create trigger on_payment_insert
after insert on public.payments
for each row
execute function handle_payment_insert();
