-- Create user_coupons table for tracking claimed coupons
CREATE TABLE IF NOT EXISTS public.user_coupons (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    coupon_id UUID NOT NULL REFERENCES public.coupons(id) ON DELETE CASCADE,
    is_used BOOLEAN DEFAULT false,
    used_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(user_id, coupon_id)
);

-- Enable RLS for user_coupons
ALTER TABLE public.user_coupons ENABLE ROW LEVEL SECURITY;

-- Policy for user_coupons
CREATE POLICY "Users can view and manage their own coupons" ON public.user_coupons
    FOR ALL USING (user_id = auth.uid());

-- Create the WELCOME20 coupon if it doesn't exist
INSERT INTO public.coupons (code, name, discount_type, discount_value, max_discount_amount, is_active, valid_from)
VALUES ('WELCOME20', 'Diskon Pengguna Baru', 'percentage', 20, 50000, true, now())
ON CONFLICT (code) DO NOTHING;

-- Trigger function to assign WELCOME20 coupon to new users
CREATE OR REPLACE FUNCTION public.assign_welcome_coupon()
RETURNS TRIGGER AS $$
DECLARE
    v_coupon_id UUID;
BEGIN
    -- Get the WELCOME20 coupon ID
    SELECT id INTO v_coupon_id FROM public.coupons WHERE code = 'WELCOME20' LIMIT 1;
    
    IF v_coupon_id IS NOT NULL THEN
        INSERT INTO public.user_coupons (user_id, coupon_id)
        VALUES (NEW.id, v_coupon_id)
        ON CONFLICT DO NOTHING;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for new users
DROP TRIGGER IF EXISTS on_user_created_assign_coupon ON public.users;
CREATE TRIGGER on_user_created_assign_coupon
    AFTER INSERT ON public.users
    FOR EACH ROW EXECUTE FUNCTION public.assign_welcome_coupon();

-- Retroactively assign WELCOME20 to existing users who don't have it
DO $$
DECLARE
    v_coupon_id UUID;
BEGIN
    SELECT id INTO v_coupon_id FROM public.coupons WHERE code = 'WELCOME20' LIMIT 1;
    
    IF v_coupon_id IS NOT NULL THEN
        INSERT INTO public.user_coupons (user_id, coupon_id)
        SELECT id, v_coupon_id FROM public.users
        WHERE NOT EXISTS (
            SELECT 1 FROM public.user_coupons uc 
            WHERE uc.user_id = users.id AND uc.coupon_id = v_coupon_id
        )
        ON CONFLICT DO NOTHING;
    END IF;
END $$;
