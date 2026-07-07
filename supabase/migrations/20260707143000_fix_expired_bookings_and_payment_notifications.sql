-- Keep past bookings and payment success notifications consistent.

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

create or replace function public.notify_payment_success()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  target_user_id uuid;
begin
  if new.status in ('settlement', 'capture')
     and (tg_op = 'INSERT' or old.status is distinct from new.status) then
    select b.user_id into target_user_id
    from public.bookings b
    where b.id = new.booking_id;

    if target_user_id is not null and not exists (
      select 1
      from public.notifications n
      where n.receiver_id = target_user_id
        and n.type = 'payment_success'
        and n.reference_id = new.booking_id
    ) then
      perform public.create_notification(
        target_user_id,
        null,
        'Pembayaran berhasil',
        'Pembayaran berhasil. Booking kamu sudah dikonfirmasi.',
        'payment_success',
        new.booking_id
      );
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists notify_payment_success_insert_trigger on public.payments;
create trigger notify_payment_success_insert_trigger
after insert on public.payments
for each row execute function public.notify_payment_success();

drop trigger if exists notify_payment_success_update_trigger on public.payments;
create trigger notify_payment_success_update_trigger
after update of status on public.payments
for each row execute function public.notify_payment_success();

notify pgrst, 'reload schema';
