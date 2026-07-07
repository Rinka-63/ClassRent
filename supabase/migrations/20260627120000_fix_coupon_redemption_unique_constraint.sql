-- Fix coupon_redemptions to ensure one-time use per user per booking
-- Add unique constraint to prevent duplicate redemptions

-- Drop existing unique constraint if exists (from original schema)
alter table public.coupon_redemptions drop constraint if exists coupon_redemptions_coupon_id_booking_id_key;

-- Add new unique constraint: coupon_id + user_id (one coupon per user)
alter table public.coupon_redemptions 
add constraint coupon_redemptions_coupon_id_user_id_key 
unique (coupon_id, user_id);

-- Add index for performance
create index if not exists idx_coupon_redemptions_user_coupon 
on public.coupon_redemptions(coupon_id, user_id);
