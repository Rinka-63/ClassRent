-- SQL Script: create_booking_rpc.sql
-- Create this function in your Supabase SQL Editor

CREATE OR REPLACE FUNCTION create_booking_transaction(p_payload JSONB)
RETURNS JSONB AS $$
DECLARE
    v_user_id UUID;
    v_room_id UUID;
    v_booking_date DATE;
    v_start_time TIME;
    v_end_time TIME;
    v_base_price NUMERIC;
    v_final_price NUMERIC;
    v_status TEXT;
    v_coupon_id UUID;
    v_discount_amount NUMERIC;
    
    v_booking_id UUID;
    v_booking_row JSONB;
    v_existing_redemption UUID;
    v_user_coupon_used BOOLEAN;
BEGIN
    -- Extract values from JSON payload
    v_user_id := (p_payload->>'user_id')::UUID;
    v_room_id := (p_payload->>'room_id')::UUID;
    v_booking_date := (p_payload->>'booking_date')::DATE;
    v_start_time := (p_payload->>'start_time')::TIME;
    v_end_time := (p_payload->>'end_time')::TIME;
    v_base_price := (p_payload->>'base_price')::NUMERIC;
    v_final_price := (p_payload->>'final_price')::NUMERIC;
    v_status := p_payload->>'status';
    
    v_coupon_id := NULLIF(p_payload->>'coupon_id', '')::UUID;
    v_discount_amount := (p_payload->>'discount_amount')::NUMERIC;

    -- 1. VALIDASI VOUCHER JIKA ADA
    IF v_coupon_id IS NOT NULL THEN
        -- Cek apakah voucher sudah pernah digunakan (di tabel coupon_redemptions)
        SELECT id INTO v_existing_redemption
        FROM coupon_redemptions
        WHERE user_id = v_user_id AND coupon_id = v_coupon_id
        LIMIT 1;
        
        IF v_existing_redemption IS NOT NULL THEN
            RAISE EXCEPTION 'Gagal: Voucher diskon ini sudah pernah Anda gunakan.';
        END IF;

        -- Cek status is_used di tabel user_coupons
        SELECT is_used INTO v_user_coupon_used
        FROM user_coupons
        WHERE user_id = v_user_id AND coupon_id = v_coupon_id
        LIMIT 1;

        IF v_user_coupon_used = TRUE THEN
            RAISE EXCEPTION 'Gagal: Voucher diskon ini sudah pernah Anda gunakan.';
        END IF;
    END IF;

    -- 2. INSERT BOOKING
    -- Karena ada constraint "no_overlap" di level tabel, jika bentrok, 
    -- PostgreSQL akan otomatis melempar error dan me-rollback transaksi ini.
    INSERT INTO bookings (
        user_id, room_id, booking_date, start_time, end_time, 
        base_price, final_price, status
    ) VALUES (
        v_user_id, v_room_id, v_booking_date, v_start_time, v_end_time,
        v_base_price, v_final_price, v_status
    )
    RETURNING id INTO v_booking_id;

    -- 3. CATAT PENGGUNAAN VOUCHER (JIKA ADA)
    IF v_coupon_id IS NOT NULL THEN
        -- Insert ke coupon_redemptions
        INSERT INTO coupon_redemptions (
            coupon_id, user_id, booking_id, discount_applied
        ) VALUES (
            v_coupon_id, v_user_id, v_booking_id, v_discount_amount
        );

        -- Update tabel user_coupons
        UPDATE user_coupons
        SET is_used = TRUE, used_at = NOW()
        WHERE user_id = v_user_id AND coupon_id = v_coupon_id;
    END IF;

    -- 4. KEMBALIKAN DATA BOOKING
    SELECT to_jsonb(b.*) INTO v_booking_row
    FROM bookings b
    WHERE id = v_booking_id;

    RETURN v_booking_row;
END;
$$ LANGUAGE plpgsql;
