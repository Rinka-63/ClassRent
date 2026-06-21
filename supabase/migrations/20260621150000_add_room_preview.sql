-- Add preview_url to rooms
alter table public.rooms add column if not exists preview_url text;
