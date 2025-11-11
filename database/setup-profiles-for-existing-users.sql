-- Setup Profiles for Existing Users
-- This script ensures all auth.users have corresponding profiles
-- Run this in Supabase SQL Editor

-- 1. Ensure profiles table exists with all required columns
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT,
    full_name TEXT,
    role TEXT DEFAULT 'fighter'
);

-- Add missing columns if they don't exist
DO $$
BEGIN
    -- Add email column if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'email'
    ) THEN
        ALTER TABLE public.profiles ADD COLUMN email TEXT;
    END IF;
    
    -- Make email unique if not already
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'profiles_email_key'
    ) THEN
        ALTER TABLE public.profiles ADD CONSTRAINT profiles_email_key UNIQUE (email);
    END IF;
    
    -- Add other columns
    ALTER TABLE public.profiles
        ADD COLUMN IF NOT EXISTS full_name TEXT,
        ADD COLUMN IF NOT EXISTS role TEXT DEFAULT 'fighter',
        ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW(),
        ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW(),
        ADD COLUMN IF NOT EXISTS banned_until TIMESTAMPTZ,
        ADD COLUMN IF NOT EXISTS banned_reason TEXT,
        ADD COLUMN IF NOT EXISTS last_sign_in_at TIMESTAMPTZ,
        ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE;
END $$;

-- 2. Create profiles for all existing auth.users that don't have one
-- Use dynamic column selection based on what exists
DO $$
DECLARE
    has_created_at BOOLEAN;
    has_is_active BOOLEAN;
    insert_sql TEXT;
BEGIN
    -- Check which columns exist
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'created_at'
    ) INTO has_created_at;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'is_active'
    ) INTO has_is_active;
    
    -- Build and execute INSERT based on available columns
    IF has_created_at AND has_is_active THEN
        INSERT INTO public.profiles (id, email, role, created_at, is_active)
        SELECT 
            u.id,
            u.email,
            COALESCE((u.raw_app_meta_data->>'role')::TEXT, 'fighter'),
            u.created_at,
            TRUE
        FROM auth.users u
        WHERE NOT EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = u.id)
        ON CONFLICT (id) DO NOTHING;
    ELSIF has_created_at THEN
        INSERT INTO public.profiles (id, email, role, created_at)
        SELECT 
            u.id,
            u.email,
            COALESCE((u.raw_app_meta_data->>'role')::TEXT, 'fighter'),
            u.created_at
        FROM auth.users u
        WHERE NOT EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = u.id)
        ON CONFLICT (id) DO NOTHING;
    ELSE
        INSERT INTO public.profiles (id, email, role)
        SELECT 
            u.id,
            u.email,
            COALESCE((u.raw_app_meta_data->>'role')::TEXT, 'fighter')
        FROM auth.users u
        WHERE NOT EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = u.id)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

-- 3. Update existing profiles with email if missing
DO $$
DECLARE
    has_updated_at BOOLEAN;
BEGIN
    -- Check if updated_at exists
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'updated_at'
    ) INTO has_updated_at;
    
    IF has_updated_at THEN
        UPDATE public.profiles p
        SET email = u.email,
            updated_at = NOW()
        FROM auth.users u
        WHERE p.id = u.id 
          AND (p.email IS NULL OR p.email = '');
    ELSE
        UPDATE public.profiles p
        SET email = u.email
        FROM auth.users u
        WHERE p.id = u.id 
          AND (p.email IS NULL OR p.email = '');
    END IF;
END $$;

-- 4. Ensure admin can access all profiles
-- Drop existing admin policies
DO $$ 
BEGIN
    DROP POLICY IF EXISTS "Admin can view all profiles" ON public.profiles;
    DROP POLICY IF EXISTS "Admin can update all profiles" ON public.profiles;
    DROP POLICY IF EXISTS "Admin can delete profiles" ON public.profiles;
    DROP POLICY IF EXISTS "Admin manage profiles" ON public.profiles;
EXCEPTION
    WHEN undefined_object THEN NULL;
END $$;

-- Check if is_admin_user function exists
DO $$
BEGIN
    -- If is_admin_user exists, use it
    IF EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'is_admin_user' 
        AND pronamespace = 'public'::regnamespace
    ) THEN
        -- Use is_admin_user function
        CREATE POLICY "Admin can view all profiles" ON public.profiles
            FOR SELECT USING (is_admin_user() OR auth.uid() = id);
        
        CREATE POLICY "Admin can update all profiles" ON public.profiles
            FOR UPDATE USING (is_admin_user() OR auth.uid() = id);
        
        CREATE POLICY "Admin can delete profiles" ON public.profiles
            FOR DELETE USING (is_admin_user());
    ELSE
        -- Fallback: check profiles table for admin role
        CREATE POLICY "Admin can view all profiles" ON public.profiles
            FOR SELECT USING (
                EXISTS (
                    SELECT 1 FROM public.profiles 
                    WHERE id = auth.uid() 
                    AND role = 'admin'
                ) OR auth.uid() = id
            );
        
        CREATE POLICY "Admin can update all profiles" ON public.profiles
            FOR UPDATE USING (
                EXISTS (
                    SELECT 1 FROM public.profiles 
                    WHERE id = auth.uid() 
                    AND role = 'admin'
                ) OR auth.uid() = id
            );
        
        CREATE POLICY "Admin can delete profiles" ON public.profiles
            FOR DELETE USING (
                EXISTS (
                    SELECT 1 FROM public.profiles 
                    WHERE id = auth.uid() 
                    AND role = 'admin'
                )
            );
    END IF;
END $$;

-- 5. Show summary
DO $$
DECLARE
    total_users INTEGER;
    total_profiles INTEGER;
    users_without_profiles INTEGER;
BEGIN
    SELECT COUNT(*) INTO total_users FROM auth.users;
    SELECT COUNT(*) INTO total_profiles FROM public.profiles;
    SELECT COUNT(*) INTO users_without_profiles
    FROM auth.users u
    WHERE NOT EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = u.id);
    
    RAISE NOTICE '═══════════════════════════════════════';
    RAISE NOTICE 'Profiles Setup Summary';
    RAISE NOTICE '═══════════════════════════════════════';
    RAISE NOTICE 'Total users in auth.users: %', total_users;
    RAISE NOTICE 'Total profiles created: %', total_profiles;
    RAISE NOTICE 'Users without profiles: %', users_without_profiles;
    RAISE NOTICE '═══════════════════════════════════════';
    
    IF users_without_profiles > 0 THEN
        RAISE NOTICE '⚠ Warning: Some users still do not have profiles';
        RAISE NOTICE 'These users will not appear in User Management';
    ELSE
        RAISE NOTICE '✓ All users have profiles';
    END IF;
END $$;

-- 6. Show all profiles that should appear in User Management
SELECT 
    p.id,
    p.email,
    p.role,
    COALESCE(p.created_at, u.created_at) as created_at,
    p.last_sign_in_at,
    p.banned_until,
    p.is_active,
    fp.name as fighter_name,
    fp.tier as fighter_tier
FROM public.profiles p
LEFT JOIN auth.users u ON u.id = p.id
LEFT JOIN public.fighter_profiles fp ON fp.user_id = p.id
ORDER BY COALESCE(p.created_at, u.created_at) DESC NULLS LAST;

