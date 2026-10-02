-- BalKalyanam: Feedback Table Schema & RLS Policies

CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Create table
CREATE TABLE IF NOT EXISTS public.feedback (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID,
    name TEXT NOT NULL,
    email TEXT,
    rating INTEGER NOT NULL DEFAULT 5,
    message TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'new',
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Verify columns
ALTER TABLE public.feedback ADD COLUMN IF NOT EXISTS user_id UUID;
ALTER TABLE public.feedback ADD COLUMN IF NOT EXISTS name TEXT;
ALTER TABLE public.feedback ADD COLUMN IF NOT EXISTS email TEXT;
ALTER TABLE public.feedback ADD COLUMN IF NOT EXISTS rating INTEGER DEFAULT 5;
ALTER TABLE public.feedback ADD COLUMN IF NOT EXISTS message TEXT;
ALTER TABLE public.feedback ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'new';
ALTER TABLE public.feedback ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT now();

-- 3. Permissions
GRANT ALL ON SCHEMA public TO postgres, anon, authenticated, service_role, supabase_admin, supabase_auth_admin, authenticator;
GRANT ALL ON TABLE public.feedback TO postgres, anon, authenticated, service_role, supabase_admin, supabase_auth_admin, authenticator;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO postgres, anon, authenticated, service_role, supabase_admin, supabase_auth_admin, authenticator;

-- 4. Row Level Security
ALTER TABLE public.feedback ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "allow_all_feedback" ON public.feedback;
CREATE POLICY "allow_all_feedback" ON public.feedback 
FOR ALL TO public 
USING (true) 
WITH CHECK (true);

-- 5. Seed sample records
INSERT INTO public.feedback (id, name, email, rating, message, status)
VALUES 
    (
        '55555555-5555-5555-5555-555555555551'::uuid,
        'Community Donor',
        'donor1@example.com',
        5,
        'Transparent and smooth donation process. Very happy to support.',
        'approved'
    ),
    (
        '55555555-5555-5555-5555-555555555552'::uuid,
        'Event Volunteer',
        'volunteer1@example.com',
        5,
        'Wonderful experience participating in the community drives.',
        'approved'
    )
ON CONFLICT (id) DO UPDATE SET
    rating = EXCLUDED.rating,
    message = EXCLUDED.message,
    status = EXCLUDED.status;

-- 6. Refresh API schema cache
NOTIFY pgrst, 'reload schema';
