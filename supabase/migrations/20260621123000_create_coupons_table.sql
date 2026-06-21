-- Create coupons table
CREATE TABLE public.coupons (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    code TEXT NOT NULL UNIQUE,
    discount_percent INTEGER NOT NULL CHECK (discount_percent > 0 AND discount_percent <= 100),
    max_discount_amount DECIMAL(12,2),
    is_active BOOLEAN DEFAULT true,
    valid_until TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS
ALTER TABLE public.coupons ENABLE ROW LEVEL SECURITY;

-- Allow anyone to read active coupons
CREATE POLICY "Anyone can read active coupons" ON public.coupons
    FOR SELECT USING (is_active = true AND (valid_until IS NULL OR valid_until > now()));

-- Allow super_admin to manage coupons
CREATE POLICY "Super admins can manage coupons" ON public.coupons
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE users.id = auth.uid() 
            AND users.role = 'SUPER_ADMIN'
        )
    );

-- Insert dummy coupons for testing
INSERT INTO public.coupons (code, discount_percent, max_discount_amount) VALUES 
('DISC20', 20, 50000),
('WELCOME50', 50, 100000),
('FLAT10', 10, NULL);
