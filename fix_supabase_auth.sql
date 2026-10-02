-- ============================================================================
-- BALKALYANAM: SUPABASE AUTHENTICATION PERMANENT FIX
-- Paste this script into your Supabase SQL Editor and click "Run"
-- ============================================================================

-- 1. Enable pgcrypto extension for password encryption
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. Drop any conflicting triggers on auth.users that cause GoTrue schema crashes
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users CASCADE;
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;

-- 3. Confirm all existing registered users immediately (so nobody is blocked by email confirmation)
UPDATE auth.users 
SET email_confirmed_at = now() 
WHERE email_confirmed_at IS NULL;

-- 4. Cleanly reset/create admin@balkalyanam.org with password 'admin123456'
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
            v_admin_id,
            '00000000-0000-0000-0000-000000000000',
            'authenticated',
            'authenticated',
            'admin@balkalyanam.org',
            v_enc_pass,
            now(),
            '{"provider":"email","providers":["email"]}'::jsonb,
            '{"name":"BalKalyanam Administrator","phone":"9359642135"}'::jsonb,
            now(),
            now()
        );
    ELSE
        UPDATE auth.users
        SET encrypted_password = v_enc_pass,
            email_confirmed_at = now(),
            raw_app_meta_data = '{"provider":"email","providers":["email"]}'::jsonb,
            raw_user_meta_data = '{"name":"BalKalyanam Administrator","phone":"9359642135"}'::jsonb
        WHERE id = v_admin_id;
    END IF;

    -- Upsert corresponding identity in auth.identities (provider_id text NOT NULL, id uuid NOT NULL)
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

    -- Ensure profile exists in public.profiles with admin role
    INSERT INTO public.profiles (id, name, email, phone, city, role)
    VALUES (v_admin_id, 'BalKalyanam Administrator', 'admin@balkalyanam.org', '9359642135', 'Amravati', 'admin')
    ON CONFLICT (id) DO UPDATE SET role = 'admin', name = 'BalKalyanam Administrator';
END $$;

-- 5. Set omkalmegh4@gmail.com password to 'admin123456' and confirm email
DO $$
DECLARE
    v_om_id uuid;
    v_enc_pass text := crypt('admin123456', gen_salt('bf', 10));
BEGIN
    SELECT id INTO v_om_id FROM auth.users WHERE email = 'omkalmegh4@gmail.com';

    IF v_om_id IS NOT NULL THEN
        UPDATE auth.users
        SET encrypted_password = v_enc_pass,
            email_confirmed_at = now()
        WHERE id = v_om_id;

        -- Ensure identity exists
        IF NOT EXISTS (SELECT 1 FROM auth.identities WHERE user_id = v_om_id) THEN
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
        END IF;

        -- Ensure profile has admin role
        INSERT INTO public.profiles (id, name, email, phone, city, role)
        VALUES (v_om_id, 'Om Kalmegh', 'omkalmegh4@gmail.com', '9359642135', 'Amravati', 'admin')
        ON CONFLICT (id) DO UPDATE SET role = 'admin';
    END IF;
END $$;

-- 6. Grant full permissions to supabase auth admin
GRANT ALL ON SCHEMA public TO postgres, anon, authenticated, service_role, supabase_admin, supabase_auth_admin, authenticator;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO postgres, anon, authenticated, service_role, supabase_admin, supabase_auth_admin, authenticator;

-- 7. Notify PostgREST to reload schema
NOTIFY pgrst, 'reload schema';
