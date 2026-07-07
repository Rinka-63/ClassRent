insert into storage.buckets (id, name, public)
values ('profile-images', 'profile-images', true)
on conflict (id) do update set public = true;

drop policy if exists "Profile images are publicly readable" on storage.objects;
create policy "Profile images are publicly readable"
on storage.objects for select
using (bucket_id = 'profile-images');

drop policy if exists "Authenticated users can upload profile images" on storage.objects;
create policy "Authenticated users can upload profile images"
on storage.objects for insert
to authenticated
with check (bucket_id = 'profile-images');

drop policy if exists "Authenticated users can update profile images" on storage.objects;
create policy "Authenticated users can update profile images"
on storage.objects for update
to authenticated
using (bucket_id = 'profile-images')
with check (bucket_id = 'profile-images');
