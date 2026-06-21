-- Add logo_url to agencies table
alter table public.agencies add column if not exists logo_url text;
