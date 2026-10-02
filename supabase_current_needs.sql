-- ============================================================================
-- BALKALYANAM: CURRENT NEEDS MODULE BACKEND SCHEMA & RLS
-- Run this script in your Supabase SQL Editor.
-- ============================================================================

-- 1. Ensure required extensions
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. Create Current Needs table
CREATE TABLE IF NOT EXISTS public.current_needs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    category TEXT NOT NULL,
    description TEXT NOT NULL,
    required_quantity NUMERIC NOT NULL,
    received_quantity NUMERIC NOT NULL DEFAULT 0,
    unit TEXT NOT NULL DEFAULT 'items',
    priority TEXT NOT NULL DEFAULT 'MEDIUM', -- 'HIGH', 'MEDIUM', 'LOW'
    status TEXT NOT NULL DEFAULT 'ACTIVE', -- 'ACTIVE', 'FULFILLED', 'PAUSED', 'CLOSED'
    image_url TEXT,
    support_instructions TEXT,
    start_date DATE DEFAULT CURRENT_DATE,
    expected_completion_date DATE,
    notes TEXT,
    created_by UUID,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- 3. In case table already exists, verify all columns exist
ALTER TABLE public.current_needs ADD COLUMN IF NOT EXISTS title TEXT;
ALTER TABLE public.current_needs ADD COLUMN IF NOT EXISTS category TEXT;
ALTER TABLE public.current_needs ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE public.current_needs ADD COLUMN IF NOT EXISTS required_quantity NUMERIC DEFAULT 100;
ALTER TABLE public.current_needs ADD COLUMN IF NOT EXISTS received_quantity NUMERIC DEFAULT 0;
ALTER TABLE public.current_needs ADD COLUMN IF NOT EXISTS unit TEXT DEFAULT 'items';
ALTER TABLE public.current_needs ADD COLUMN IF NOT EXISTS priority TEXT DEFAULT 'MEDIUM';
ALTER TABLE public.current_needs ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'ACTIVE';
ALTER TABLE public.current_needs ADD COLUMN IF NOT EXISTS image_url TEXT;
ALTER TABLE public.current_needs ADD COLUMN IF NOT EXISTS support_instructions TEXT;
ALTER TABLE public.current_needs ADD COLUMN IF NOT EXISTS start_date DATE DEFAULT CURRENT_DATE;
ALTER TABLE public.current_needs ADD COLUMN IF NOT EXISTS expected_completion_date DATE;
ALTER TABLE public.current_needs ADD COLUMN IF NOT EXISTS notes TEXT;
ALTER TABLE public.current_needs ADD COLUMN IF NOT EXISTS created_by UUID;
ALTER TABLE public.current_needs ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT now();
ALTER TABLE public.current_needs ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT now();

-- 4. Connect Current Needs with Donations & Item Donations
ALTER TABLE public.donations ADD COLUMN IF NOT EXISTS need_id UUID;
ALTER TABLE public.item_donations ADD COLUMN IF NOT EXISTS need_id UUID;

-- 5. Grant schema and table permissions to Supabase roles
GRANT ALL ON SCHEMA public TO postgres, anon, authenticated, service_role, supabase_admin, supabase_auth_admin, authenticator;
GRANT ALL ON TABLE public.current_needs TO postgres, anon, authenticated, service_role, supabase_admin, supabase_auth_admin, authenticator;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO postgres, anon, authenticated, service_role, supabase_admin, supabase_auth_admin, authenticator;

-- 6. Enable Row Level Security (RLS)
ALTER TABLE public.current_needs ENABLE ROW LEVEL SECURITY;

-- 7. RLS Policies: Allow public read and permissive write for admin management
DROP POLICY IF EXISTS "allow_all_current_needs" ON public.current_needs;
CREATE POLICY "allow_all_current_needs" ON public.current_needs 
FOR ALL TO public 
USING (true) 
WITH CHECK (true);

-- 8. Seed Initial Current Requirements for Sada Shanti Balgruh (Amravati)
INSERT INTO public.current_needs (
    id, title, category, description, required_quantity, received_quantity, unit, priority, status, support_instructions, expected_completion_date
) VALUES 
    (
        'aaaaaaaa-1111-1111-1111-111111111111'::uuid,
        'School Stationery & Geometry Kits',
        'School Stationery',
        'Customized academic kits containing notebooks, pens, pencils, geometry instrument boxes, erasers, and drawing books for 65 school-going children.',
        100,
        65,
        'kits',
        'HIGH',
        'ACTIVE',
        'You can sponsor a kit via UPI (₹350/kit) or drop packaged stationery at our Amravati campus.',
        CURRENT_DATE + interval '20 days'
    ),
    (
        'bbbbbbbb-2222-2222-2222-222222222222'::uuid,
        'Winter Woolen Sweaters & Warm Blankets',
        'Clothing',
        'High-quality warm sweaters, wool caps, socks, and thermal innerwear for children aged 4 to 17 years ahead of winter season.',
        65,
        40,
        'sets',
        'HIGH',
        'ACTIVE',
        'New winter clothes of assorted sizes (ages 4-17) or voluntary contributions via direct UPI.',
        CURRENT_DATE + interval '30 days'
    ),
    (
        'cccccccc-3333-3333-3333-333333333333'::uuid,
        'Monthly Kitchen Ration: Rice & Toor Dal',
        'Groceries',
        'High-nutrition pantry staples: Kolam rice, protein-rich Toor dal, Moong dal, cooking oil, and turmeric for our central kitchen meals.',
        250,
        175,
        'kg',
        'MEDIUM',
        'ACTIVE',
        'Physical grain sacks can be delivered directly, or sponsor monthly grocery fund via UPI.',
        CURRENT_DATE + interval '15 days'
    ),
    (
        'dddddddd-4444-4444-4444-444444444444'::uuid,
        'Pediatric Health Wellness & Vitamin Kits',
        'Medicines/Healthcare Support',
        'Pediatric multi-vitamins, iron supplements, dental hygiene packs (brushes, paste), skin lotions, and first-aid kits recommended by our visiting doctor.',
        50,
        22,
        'kits',
        'HIGH',
        'ACTIVE',
        'Prescribed medical wellness supplies can be delivered or supported through monetary sponsorship.',
        CURRENT_DATE + interval '25 days'
    ),
    (
        'eeeeeeee-5555-5555-5555-555555555555'::uuid,
        'Sports Gear: Badminton & Cricket Sets',
        'Sports Items',
        'Badminton racquets, shuttlecock bundles, cricket bats, tennis balls, and carrom boards for evening physical activity and recreation.',
        15,
        15,
        'sets',
        'LOW',
        'FULFILLED',
        'Thank you to our wonderful community! This sports equipment requirement has been 100% fulfilled.',
        CURRENT_DATE - interval '5 days'
    )
ON CONFLICT (id) DO UPDATE SET
    required_quantity = EXCLUDED.required_quantity,
    received_quantity = EXCLUDED.received_quantity,
    priority = EXCLUDED.priority,
    status = EXCLUDED.status;

-- 9. Reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';
