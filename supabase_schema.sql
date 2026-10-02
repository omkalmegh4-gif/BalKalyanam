-- =====================================================
-- BALKALYANAM - SADA SHANTI BALGRUH DATABASE SCHEMA
-- =====================================================

-- 1. Profiles Table (Extends Supabase Auth)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    phone TEXT,
    city TEXT,
    role TEXT DEFAULT 'user' CHECK (role IN ('user', 'admin')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public profiles are viewable by owner and admin"
ON public.profiles FOR SELECT
USING (auth.uid() = id OR EXISTS (
    SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'
));

CREATE POLICY "Users can update own profile"
ON public.profiles FOR UPDATE
USING (auth.uid() = id);

-- 2. Money Donations Table (Direct UPI QR)
CREATE TABLE IF NOT EXISTS public.donations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    donor_name TEXT NOT NULL,
    email TEXT NOT NULL,
    phone TEXT NOT NULL,
    amount NUMERIC NOT NULL CHECK (amount > 0),
    campaign TEXT NOT NULL DEFAULT 'General Welfare Fund',
    upi_ref TEXT NOT NULL,
    donation_date DATE NOT NULL,
    notes TEXT,
    status TEXT NOT NULL DEFAULT 'PENDING_VERIFICATION' CHECK (status IN ('PENDING_VERIFICATION', 'VERIFIED', 'REJECTED')),
    receipt_id TEXT UNIQUE,
    verified_at TIMESTAMPTZ,
    verified_by TEXT,
    admin_notes TEXT,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.donations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Donors can view their own donations"
ON public.donations FOR SELECT
USING (auth.uid() = user_id OR EXISTS (
    SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'
));

CREATE POLICY "Authenticated users can submit donations"
ON public.donations FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Only admins can update donation status"
ON public.donations FOR UPDATE
USING (EXISTS (
    SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'
));

-- 3. In-Kind / Physical Item Donations Table
CREATE TABLE IF NOT EXISTS public.item_donations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category TEXT NOT NULL CHECK (category IN (
        'clothes', 'food', 'groceries', 'books', 
        'stationery', 'study', 'toys', 'hygiene', 'other'
    )),
    campaign TEXT NOT NULL DEFAULT 'General Orphanage Support',
    description TEXT NOT NULL,
    donor_name TEXT NOT NULL,
    phone TEXT NOT NULL,
    email TEXT,
    delivery_method TEXT NOT NULL CHECK (delivery_method IN ('drop_off', 'request_collection')),
    preferred_date DATE NOT NULL,
    pickup_address TEXT,
    pickup_landmark TEXT,
    pickup_pincode TEXT,
    status TEXT NOT NULL DEFAULT 'PENDING' CHECK (status IN (
        'PENDING', 'REVIEWING', 'ACCEPTED', 
        'COLLECTION SCHEDULED', 'RECEIVED', 'COMPLETED', 'REJECTED'
    )),
    admin_notes TEXT,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.item_donations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Donors can view their own item donations"
ON public.item_donations FOR SELECT
USING (auth.uid() = user_id OR EXISTS (
    SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'
));

CREATE POLICY "Authenticated users can submit item donations"
ON public.item_donations FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Only admins can update item donation status"
ON public.item_donations FOR UPDATE
USING (EXISTS (
    SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'
));

-- 4. Volunteers Table
CREATE TABLE IF NOT EXISTS public.volunteers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    full_name TEXT NOT NULL,
    email TEXT NOT NULL,
    phone TEXT NOT NULL,
    help_area TEXT NOT NULL,
    message TEXT NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Contact Inquiries Table
CREATE TABLE IF NOT EXISTS public.contact_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    subject TEXT NOT NULL,
    message TEXT NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. Feedback Table
CREATE TABLE IF NOT EXISTS public.feedback (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    message TEXT NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
