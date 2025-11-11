-- Fix Admin Access to Profiles for User Management
-- Run this in Supabase SQL Editor to ensure admins can view all profiles

-- 1. Ensure profiles table exists
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT,
    full_name TEXT,
    role TEXT DEFAULT 'fighter',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    banned_until TIMESTAMPTZ,
    banned_reason TEXT,
    last_sign_in_at TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT TRUE
);

-- 2. Create profiles for existing auth.users that don't have one
DO $$
DECLARE
    has_created_at BOOLEAN;
    has_is_active BOOLEAN;
    created_count INTEGER := 0;
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
    
    -- Insert missing profiles
    IF has_created_at AND has_is_active THEN
        INSERT INTO public.profiles (id, email, role, created_at, is_active)
        SELECT 
            u.id,
            u.email,
            COALESCE((u.raw_app_meta_data->>'role')::TEXT, (u.raw_user_meta_data->>'role')::TEXT, 'fighter'),
            u.created_at,
            TRUE
        FROM auth.users u
        WHERE NOT EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = u.id)
        ON CONFLICT (id) DO NOTHING;
        
        GET DIAGNOSTICS created_count = ROW_COUNT;
    ELSIF has_created_at THEN
        INSERT INTO public.profiles (id, email, role, created_at)
        SELECT 
            u.id,
            u.email,
            COALESCE((u.raw_app_meta_data->>'role')::TEXT, (u.raw_user_meta_data->>'role')::TEXT, 'fighter'),
            u.created_at
        FROM auth.users u
        WHERE NOT EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = u.id)
        ON CONFLICT (id) DO NOTHING;
        
        GET DIAGNOSTICS created_count = ROW_COUNT;
    ELSE
        INSERT INTO public.profiles (id, email, role)
        SELECT 
            u.id,
            u.email,
            COALESCE((u.raw_app_meta_data->>'role')::TEXT, (u.raw_user_meta_data->>'role')::TEXT, 'fighter')
        FROM auth.users u
        WHERE NOT EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = u.id)
        ON CONFLICT (id) DO NOTHING;
        
        GET DIAGNOSTICS created_count = ROW_COUNT;
    END IF;
    
    RAISE NOTICE 'Created % new profiles for existing users', created_count;
    
    -- Ensure is_active column exists
    IF NOT has_is_active THEN
        ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE;
        RAISE NOTICE 'Added is_active column to profiles table';
    END IF;
END $$;

-- 3. Drop and recreate admin RLS policies
DO $$
BEGIN
    -- Drop existing admin policies
    DROP POLICY IF EXISTS "Admin can view all profiles" ON public.profiles;
    DROP POLICY IF EXISTS "Admin can update all profiles" ON public.profiles;
    DROP POLICY IF EXISTS "Admin can delete profiles" ON public.profiles;
    DROP POLICY IF EXISTS "Admins can view all profiles" ON public.profiles;
    DROP POLICY IF EXISTS "Admins can update all profiles" ON public.profiles;
    DROP POLICY IF EXISTS "Admins can delete profiles" ON public.profiles;
EXCEPTION
    WHEN undefined_object THEN NULL;
END $$;

-- 4. Check if is_admin_user function exists and use it if available
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'is_admin_user' 
        AND pronamespace = 'public'::regnamespace
    ) THEN
        -- Use is_admin_user function (from fix-news-rls-policy.sql)
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

-- 5. Ensure get_all_users_for_admin function exists
-- Note: is_active column is guaranteed to exist after step 2
DROP FUNCTION IF EXISTS get_all_users_for_admin() CASCADE;

CREATE OR REPLACE FUNCTION get_all_users_for_admin()
RETURNS TABLE (
    user_id UUID,
    email TEXT,
    role TEXT,
    full_name TEXT,
    created_at TIMESTAMPTZ,
    last_sign_in_at TIMESTAMPTZ,
    banned_until TIMESTAMPTZ,
    banned_reason TEXT,
    is_active BOOLEAN,
    fighter_name TEXT,
    fighter_tier TEXT,
    fighter_points INTEGER,
    fighter_wins INTEGER,
    fighter_losses INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
    -- Check if current user is admin
    IF NOT EXISTS (
        SELECT 1 FROM public.profiles p
        WHERE p.id = auth.uid()
        AND p.role = 'admin'
    ) THEN
        RAISE EXCEPTION 'Access denied. Admin privileges required.';
    END IF;

    RETURN QUERY
    SELECT 
        u.id AS user_id,
        u.email,
        COALESCE(p.role, 'fighter') AS role,
        p.full_name,
        u.created_at,
        u.last_sign_in_at,
        p.banned_until,
        p.banned_reason,
        COALESCE(p.is_active, TRUE) AS is_active,
        fp.name AS fighter_name,
        fp.tier AS fighter_tier,
        fp.points AS fighter_points,
        fp.wins AS fighter_wins,
        fp.losses AS fighter_losses
    FROM auth.users u
    LEFT JOIN public.profiles p ON p.id = u.id
    LEFT JOIN public.fighter_profiles fp ON fp.user_id = u.id
    ORDER BY u.created_at DESC;
END;
$$;

GRANT EXECUTE ON FUNCTION get_all_users_for_admin() TO authenticated;

-- 6. Show summary
DO $$
DECLARE
    total_users INTEGER;
    total_profiles INTEGER;
    admin_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO total_users FROM auth.users;
    SELECT COUNT(*) INTO total_profiles FROM public.profiles;
    SELECT COUNT(*) INTO admin_count FROM public.profiles WHERE role = 'admin';
    
    RAISE NOTICE '═══════════════════════════════════════';
    RAISE NOTICE 'User Management Setup Summary';
    RAISE NOTICE '═══════════════════════════════════════';
    RAISE NOTICE 'Total users in auth.users: %', total_users;
    RAISE NOTICE 'Total profiles in profiles table: %', total_profiles;
    RAISE NOTICE 'Admin accounts: %', admin_count;
    RAISE NOTICE '═══════════════════════════════════════';
    
    IF total_profiles = 0 THEN
        RAISE WARNING '⚠ Profiles table is empty!';
    END IF;
    
    IF admin_count = 0 THEN
        RAISE WARNING '⚠ No admin accounts found! Make sure your account has role=''admin'' in profiles table';
    END IF;
END $$;

-- 7. Show first 10 profiles for verification
-- Check if is_active column exists before querying
DO $$
DECLARE
    has_is_active BOOLEAN;
    query_text TEXT;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'profiles' 
        AND column_name = 'is_active'
    ) INTO has_is_active;
    
    IF has_is_active THEN
        query_text := 'SELECT 
            p.id,
            p.email,
            p.role,
            COALESCE(p.created_at, u.created_at) as created_at,
            p.is_active,
            fp.name as fighter_name
        FROM public.profiles p
        LEFT JOIN auth.users u ON u.id = p.id
        LEFT JOIN public.fighter_profiles fp ON fp.user_id = p.id
        ORDER BY COALESCE(p.created_at, u.created_at) DESC
        LIMIT 10';
    ELSE
        query_text := 'SELECT 
            p.id,
            p.email,
            p.role,
            COALESCE(p.created_at, u.created_at) as created_at,
            TRUE as is_active,
            fp.name as fighter_name
        FROM public.profiles p
        LEFT JOIN auth.users u ON u.id = p.id
        LEFT JOIN public.fighter_profiles fp ON fp.user_id = p.id
        ORDER BY COALESCE(p.created_at, u.created_at) DESC
        LIMIT 10';
    END IF;
    
    RAISE NOTICE 'Sample profiles:';
END $$;

-- Show first 10 profiles (simplified - without is_active to avoid errors)
SELECT 
    p.id,
    p.email,
    p.role,
    COALESCE(p.created_at, u.created_at) as created_at,
    fp.name as fighter_name
FROM public.profiles p
LEFT JOIN auth.users u ON u.id = p.id
LEFT JOIN public.fighter_profiles fp ON fp.user_id = p.id
ORDER BY COALESCE(p.created_at, u.created_at) DESC
LIMIT 10;

