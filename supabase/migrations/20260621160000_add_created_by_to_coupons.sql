-- Add created_by column to coupons
ALTER TABLE public.coupons ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES public.users(id) ON DELETE CASCADE;

-- Update RLS Policy for Admins
DROP POLICY IF EXISTS "Super admins can manage coupons" ON public.coupons;

-- Policy for Super Admin and the Creator of the Coupon
CREATE POLICY "Admins can manage their own coupons and Super admins can manage all" ON public.coupons
    FOR ALL USING (
        created_by = auth.uid() OR
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE users.id = auth.uid() 
            AND users.role = 'SUPER_ADMIN'
        )
    );
