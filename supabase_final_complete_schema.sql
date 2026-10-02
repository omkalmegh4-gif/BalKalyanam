-- ============================================================================
-- BALKALYANAM (SADA SHANTI BALGRUH)
-- MASTER SUPABASE BACKEND SCHEMA, RLS POLICIES & SEED DATA
-- Copy and paste this entire script into your Supabase SQL Editor and click "Run".
-- ============================================================================

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. CLEAN UP ANY BLOCKING TRIGGERS ON auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users CASCADE;
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;

-- 3. GRANT COMPREHENSIVE SCHEMA PERMISSIONS TO ALL SUPABASE ROLES
GRANT ALL ON SCHEMA public TO postgres, anon, authenticated, service_role, supabase_admin, supabase_auth_admin, authenticator;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO postgres, anon, authenticated, service_role, supabase_admin, supabase_auth_admin, authenticator;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO postgres, anon, authenticated, service_role, supabase_admin, supabase_auth_admin, authenticator;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON ROUTINES TO postgres, anon, authenticated, service_role, supabase_admin, supabase_auth_admin, authenticator;

-- ============================================================================
-- 4. CREATE DATABASE TABLES
-- ============================================================================

-- Profiles Table (Users & Admins)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    phone TEXT,
    city TEXT DEFAULT 'Amravati',
    role TEXT NOT NULL DEFAULT 'user',
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Money Donations Table (Direct UPI QR with Reference Numbers)
CREATE TABLE IF NOT EXISTS public.donations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID,
    donor_name TEXT NOT NULL,
    donor_phone TEXT NOT NULL,
    donor_email TEXT NOT NULL,
    campaign TEXT NOT NULL DEFAULT 'General Welfare Fund',
    amount NUMERIC NOT NULL,
    upi_reference TEXT NOT NULL,
    donation_date DATE NOT NULL DEFAULT CURRENT_DATE,
    note TEXT,
    status TEXT NOT NULL DEFAULT 'pending',
    receipt_id TEXT,
    verified_at TIMESTAMPTZ,
    admin_notes TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Physical / In-Kind Donations Table (Clothes, Groceries, Books, Stationery, etc.)
CREATE TABLE IF NOT EXISTS public.item_donations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID,
    donor_name TEXT NOT NULL,
    donor_phone TEXT NOT NULL,
    donor_email TEXT,
    category TEXT NOT NULL,
    item_name TEXT NOT NULL,
    quantity TEXT,
    pickup_required BOOLEAN DEFAULT false,
    pickup_address TEXT,
    preferred_date DATE,
    note TEXT,
    status TEXT NOT NULL DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Events & Community Drives Table
CREATE TABLE IF NOT EXISTS public.events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    category TEXT NOT NULL,
    event_date TEXT NOT NULL,
    location TEXT NOT NULL,
    description TEXT NOT NULL,
    target TEXT,
    status TEXT NOT NULL DEFAULT 'active',
    attendees_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Event RSVPs & Attendance Table
CREATE TABLE IF NOT EXISTS public.event_rsvps (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID,
    event_title TEXT NOT NULL,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    phone TEXT NOT NULL,
    role TEXT DEFAULT 'Volunteer Helper',
    attendees INTEGER DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Volunteers Applications Table
CREATE TABLE IF NOT EXISTS public.volunteers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    phone TEXT NOT NULL,
    area_of_interest TEXT NOT NULL,
    message TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Contact Inquiries & Messages Table
CREATE TABLE IF NOT EXISTS public.messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    subject TEXT NOT NULL,
    message TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'unread',
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Current Needs & Requirements Table
CREATE TABLE IF NOT EXISTS public.current_needs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    category TEXT NOT NULL,
    description TEXT NOT NULL,
    required_quantity NUMERIC NOT NULL,
    received_quantity NUMERIC NOT NULL DEFAULT 0,
    unit TEXT NOT NULL DEFAULT 'items',
    priority TEXT NOT NULL DEFAULT 'MEDIUM',
    status TEXT NOT NULL DEFAULT 'ACTIVE',
    image_url TEXT,
    support_instructions TEXT,
    start_date DATE DEFAULT CURRENT_DATE,
    expected_completion_date DATE,
    notes TEXT,
    created_by UUID,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.donations ADD COLUMN IF NOT EXISTS need_id UUID;
ALTER TABLE public.item_donations ADD COLUMN IF NOT EXISTS need_id UUID;

-- User Feedback & Star Reviews Table
CREATE TABLE IF NOT EXISTS public.feedback (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    rating INTEGER NOT NULL DEFAULT 5,
    message TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'new',
    created_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================================
-- 5. ROW LEVEL SECURITY (RLS) POLICIES
-- Enable RLS with permissive public access so website visitors, donors, 
-- and volunteers can submit records without 403 Forbidden errors.
-- ============================================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.donations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.item_donations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_rsvps ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.volunteers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.current_needs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "allow_all_current_needs" ON public.current_needs;
CREATE POLICY "allow_all_current_needs" ON public.current_needs FOR ALL TO public USING (true) WITH CHECK (true);

ALTER TABLE public.feedback ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "allow_all_profiles" ON public.profiles;
CREATE POLICY "allow_all_profiles" ON public.profiles FOR ALL TO public USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "allow_all_donations" ON public.donations;
CREATE POLICY "allow_all_donations" ON public.donations FOR ALL TO public USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "allow_all_item_donations" ON public.item_donations;
CREATE POLICY "allow_all_item_donations" ON public.item_donations FOR ALL TO public USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "allow_all_events" ON public.events;
CREATE POLICY "allow_all_events" ON public.events FOR ALL TO public USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "allow_all_event_rsvps" ON public.event_rsvps;
CREATE POLICY "allow_all_event_rsvps" ON public.event_rsvps FOR ALL TO public USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "allow_all_volunteers" ON public.volunteers;
CREATE POLICY "allow_all_volunteers" ON public.volunteers FOR ALL TO public USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "allow_all_messages" ON public.messages;
CREATE POLICY "allow_all_messages" ON public.messages FOR ALL TO public USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "allow_all_feedback" ON public.feedback;
CREATE POLICY "allow_all_feedback" ON public.feedback FOR ALL TO public USING (true) WITH CHECK (true);

-- ============================================================================
-- 6. AUTO-CONFIRM ALL USERS (ELIMINATES "INVALID LOGIN CREDENTIALS" ON UNVERIFIED EMAILS)
-- ============================================================================
UPDATE auth.users 
SET email_confirmed_at = now() 
WHERE email_confirmed_at IS NULL;

-- ============================================================================
-- 7. CLEANLY CONFIGURE ADMIN ACCOUNTS WITH PASSWORD 'admin123456'
-- ============================================================================

-- 7A. Configure admin@balkalyanam.org
DO $$
DECLARE
    v_admin_id uuid;
    v_enc_pass text := crypt('admin123456', gen_salt('bf', 10));
BEGIN
    SELECT id INTO v_admin_id FROM auth.users WHERE email = 'admin@balkalyanam.org';

    IF v_admin_id IS NULL THEN
        v_admin_id := 'bb98cefc-ffea-4b50-bb8a-450fdebf8f6d'::uuid;
        INSERT INTO auth.users (
            id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
            raw_app_meta_data, raw_user_meta_data, created_at, updated_at
        ) VALUES (
            v_admin_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
            'admin@balkalyanam.org', v_enc_pass, now(),
            '{"provider":"email","providers":["email"]}'::jsonb,
            '{"name":"BalKalyanam Administrator","phone":"9359642135"}'::jsonb,
            now(), now()
        );
    ELSE
        UPDATE auth.users
        SET encrypted_password = v_enc_pass, email_confirmed_at = now()
        WHERE id = v_admin_id;
    END IF;

    -- Ensure identity exists in auth.identities (provider_id text NOT NULL, id uuid NOT NULL)
    DELETE FROM auth.identities WHERE user_id = v_admin_id;
    INSERT INTO auth.identities (
        provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, id
    ) VALUES (
        v_admin_id::text,
        v_admin_id,
        format('{"sub":"%s","email":"%s","email_verified":true}', v_admin_id::text, 'admin@balkalyanam.org')::jsonb,
        'email',
        now(),
        now(),
        now(),
        v_admin_id
    );

    -- Ensure admin profile
    INSERT INTO public.profiles (id, name, email, phone, city, role)
    VALUES (v_admin_id, 'BalKalyanam Administrator', 'admin@balkalyanam.org', '9359642135', 'Amravati', 'admin')
    ON CONFLICT (id) DO UPDATE SET role = 'admin', name = 'BalKalyanam Administrator';
END $$;

-- 7B. Configure omkalmegh4@gmail.com with admin role
DO $$
DECLARE
    v_om_id uuid;
    v_enc_pass text := crypt('admin123456', gen_salt('bf', 10));
BEGIN
    SELECT id INTO v_om_id FROM auth.users WHERE email = 'omkalmegh4@gmail.com';

    IF v_om_id IS NOT NULL THEN
        UPDATE auth.users
        SET encrypted_password = v_enc_pass, email_confirmed_at = now()
        WHERE id = v_om_id;

        DELETE FROM auth.identities WHERE user_id = v_om_id;
        INSERT INTO auth.identities (
            provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, id
        ) VALUES (
            v_om_id::text,
            v_om_id,
            format('{"sub":"%s","email":"%s","email_verified":true}', v_om_id::text, 'omkalmegh4@gmail.com')::jsonb,
            'email',
            now(),
            now(),
            now(),
            v_om_id
        );

        INSERT INTO public.profiles (id, name, email, phone, city, role)
        VALUES (v_om_id, 'Om Kalmegh', 'omkalmegh4@gmail.com', '9359642135', 'Amravati', 'admin')
        ON CONFLICT (id) DO UPDATE SET role = 'admin';
    END IF;
END $$;

-- ============================================================================
-- 8. SEED INITIAL EVENTS
-- ============================================================================
INSERT INTO public.events (id, title, category, event_date, location, description, target, attendees_count, status)
VALUES 
    (
        '11111111-1111-1111-1111-111111111111'::uuid,
        'Mission Vidya: Book & Stationery Drive 2026',
        'education',
        'Saturday, Oct 12, 2026 • 10:00 AM',
        'Sada Shanti Balgruh, Amravati',
        'Collecting and packaging 1,000 customized school kits, notebook bundles, geometry sets, and backpacks for primary school children.',
        '1,000 Learning Kits',
        48,
        'active'
    ),
    (
        '22222222-2222-2222-2222-222222222222'::uuid,
        'Diwali Smiles & Grand Festive Feast',
        'food',
        'Sunday, Oct 26, 2026 • 12:30 PM',
        'BalKalyanam Main Campus, Amravati',
        'A grand festival celebration with a wholesome feast, sweet distribution, traditional new festive clothes, games, and cultural dance performances.',
        'Traditional Clothes & Sweets For All Children',
        35,
        'upcoming'
    ),
    (
        '33333333-3333-3333-3333-333333333333'::uuid,
        'Pediatric Dental & Vision Health Camp',
        'health',
        'Sunday, Nov 09, 2026 • 09:00 AM',
        'Sada Shanti Balgruh Health Wing',
        'Comprehensive pediatric checkups, oral hygiene & dental treatments, vision refraction, vitamin care, and distribution of medical wellness kits.',
        'Free Checkups & Medicines for 60+ Children',
        22,
        'upcoming'
    ),
    (
        '44444444-4444-4444-4444-444444444444'::uuid,
        'BalKalyanam Annual Sports & Art Utsav',
        'sports',
        'Sunday, Nov 22, 2026 • 08:30 AM',
        'District Community Ground, Amravati',
        'An inspiring full-day sports meet featuring sprint races, badminton, tug-of-war, painting exhibitions, and an evening cultural talent showcase.',
        'Trophies, Art Awards & Goodie Bags',
        64,
        'upcoming'
    )
ON CONFLICT (id) DO UPDATE SET 
    title = EXCLUDED.title,
    event_date = EXCLUDED.event_date,
    description = EXCLUDED.description;

-- ============================================================================

-- ============================================================================
-- 8B. SEED INITIAL CURRENT REQUIREMENTS
-- ============================================================================
INSERT INTO public.current_needs (
    id, title, category, description, required_quantity, received_quantity, unit, priority, status, support_instructions, expected_completion_date
) VALUES 
    ('aaaaaaaa-1111-1111-1111-111111111111'::uuid, 'School Stationery & Geometry Kits', 'School Stationery', 'Customized academic kits containing notebooks, pens, pencils, geometry instrument boxes, erasers, and drawing books for 65 school-going children.', 100, 65, 'kits', 'HIGH', 'ACTIVE', 'You can sponsor a kit via UPI (₹350/kit) or drop packaged stationery at our Amravati campus.', CURRENT_DATE + interval '20 days'),
    ('bbbbbbbb-2222-2222-2222-222222222222'::uuid, 'Winter Woolen Sweaters & Warm Blankets', 'Clothing', 'High-quality warm sweaters, wool caps, socks, and thermal innerwear for children aged 4 to 17 years ahead of winter season.', 65, 40, 'sets', 'HIGH', 'ACTIVE', 'New winter clothes of assorted sizes (ages 4-17) or voluntary contributions via direct UPI.', CURRENT_DATE + interval '30 days'),
    ('cccccccc-3333-3333-3333-333333333333'::uuid, 'Monthly Kitchen Ration: Rice & Toor Dal', 'Groceries', 'High-nutrition pantry staples: Kolam rice, protein-rich Toor dal, Moong dal, cooking oil, and turmeric for our central kitchen meals.', 250, 175, 'kg', 'MEDIUM', 'ACTIVE', 'Physical grain sacks can be delivered directly, or sponsor monthly grocery fund via UPI.', CURRENT_DATE + interval '15 days'),
    ('dddddddd-4444-4444-4444-444444444444'::uuid, 'Pediatric Health Wellness & Vitamin Kits', 'Medicines/Healthcare Support', 'Pediatric multi-vitamins, iron supplements, dental hygiene packs (brushes, paste), skin lotions, and first-aid kits recommended by our visiting doctor.', 50, 22, 'kits', 'HIGH', 'ACTIVE', 'Prescribed medical wellness supplies can be delivered or supported through monetary sponsorship.', CURRENT_DATE + interval '25 days'),
    ('eeeeeeee-5555-5555-5555-555555555555'::uuid, 'Sports Gear: Badminton & Cricket Sets', 'Sports Items', 'Badminton racquets, shuttlecock bundles, cricket bats, tennis balls, and carrom boards for evening physical activity and recreation.', 15, 15, 'sets', 'LOW', 'FULFILLED', 'Thank you to our wonderful community! This sports equipment requirement has been 100% fulfilled.', CURRENT_DATE - interval '5 days')
ON CONFLICT (id) DO UPDATE SET
    required_quantity = EXCLUDED.required_quantity,
    received_quantity = EXCLUDED.received_quantity,
    priority = EXCLUDED.priority,
    status = EXCLUDED.status;

-- 9. RELOAD SCHEMA NOTIFICATION
-- ============================================================================
NOTIFY pgrst, 'reload schema';
