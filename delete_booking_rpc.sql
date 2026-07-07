-- SQL Script: delete_booking_rpc.sql
-- Create this function in your Supabase SQL Editor

CREATE OR REPLACE FUNCTION delete_booking_rpc(p_booking_id UUID)
RETURNS VOID AS $$
BEGIN
    DELETE FROM bookings WHERE id = p_booking_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
