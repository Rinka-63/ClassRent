-- Create storage bucket for room images
-- This bucket will store all room-related images

-- Insert the storage bucket
insert into storage.buckets (id, name, public)
values ('room-images', 'room-images', true)
on conflict (id) do update set public = true;

-- Create RLS policies for the bucket
-- Allow public read access
drop policy if exists "Public read access for room images" on storage.objects;
create policy "Public read access for room images"
on storage.objects for select
to public
using (bucket_id = 'room-images');

-- Allow authenticated users to upload
drop policy if exists "Authenticated users can upload room images" on storage.objects;
create policy "Authenticated users can upload room images"
on storage.objects for insert
to authenticated
with check (bucket_id = 'room-images');

-- Allow room owners to update/delete their images
drop policy if exists "Room owners can update their images" on storage.objects;
create policy "Room owners can update their images"
on storage.objects for update
to authenticated
using (
  bucket_id = 'room-images' and
  (
    public.is_super_admin()
    or exists (
      select 1
      from public.rooms r
      where r.id::text = split_part(storage.filename(name), '_', 1)
        and r.admin_id = auth.uid()
    )
  )
)
with check (
  bucket_id = 'room-images' and
  (
    public.is_super_admin()
    or exists (
      select 1
      from public.rooms r
      where r.id::text = split_part(storage.filename(name), '_', 1)
        and r.admin_id = auth.uid()
    )
  )
);

drop policy if exists "Room owners can delete their images" on storage.objects;
create policy "Room owners can delete their images"
on storage.objects for delete
to authenticated
using (
  bucket_id = 'room-images' and
  (
    public.is_super_admin()
    or exists (
      select 1
      from public.rooms r
      where r.id::text = split_part(storage.filename(name), '_', 1)
        and r.admin_id = auth.uid()
    )
  )
);
