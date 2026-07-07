drop policy if exists users_agency_read_booking_customers on public.users;
create policy users_agency_read_booking_customers
on public.users
for select using (
  exists (
    select 1
    from public.bookings b
    where b.user_id = users.id
      and public.can_manage_room(b.room_id)
  )
);

notify pgrst, 'reload schema';
