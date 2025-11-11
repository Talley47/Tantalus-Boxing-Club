-- Verify Users Setup and Create Test Data
-- Run this in Supabase SQL Editor to verify and set up users for User Management
-- This will help diagnose why no users are found

-- 1. Check if profiles table exists and show structure
DO $$
DECLARE
    rec RECORD;
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'profiles') THEN
        RAISE NOTICE '✓ Profiles table exists';
        
        -- Show columns
        RAISE NOTICE 'Profiles table columns:';
        FOR rec IN 
            SELECT column_name, data_type 
            FROM information_schema.columns 
            WHERE table_schema = 'public' AND table_name = 'profiles'
            ORDER BY ordinal_position
        LOOP
            RAISE NOTICE '  - % (type: %)', rec.column_name, rec.data_type;
        END LOOP;
    ELSE
        RAISE NOTICE '✗ Profiles table does NOT exist - need to create it';
    END IF;
END $$;

-- 2. Check if fighter_profiles table exists
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'fighter_profiles') THEN
        RAISE NOTICE '✓ Fighter_profiles table exists';
    ELSE
        RAISE NOTICE '✗ Fighter_profiles table does NOT exist';
    END IF;
END $$;

-- 3. Count users in auth.users
DO $$
DECLARE
    user_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO user_count FROM auth.users;
    RAISE NOTICE 'Total users in auth.users: %', user_count;
END $$;

-- 4. Count profiles
DO $$
DECLARE
    profile_count INTEGER;
    rec RECORD;
    has_created_at BOOLEAN;
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'profiles') THEN
        SELECT COUNT(*) INTO profile_count FROM public.profiles;
        RAISE NOTICE 'Total profiles in profiles table: %', profile_count;
        
        -- Check if created_at column exists
        SELECT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'profiles' 
            AND column_name = 'created_at'
        ) INTO has_created_at;
        
        -- Show sample profiles
        RAISE NOTICE 'Sample profiles (first 5):';
        IF has_created_at THEN
            FOR rec IN 
                SELECT id, email, role, created_at 
                FROM public.profiles 
                LIMIT 5
            LOOP
                RAISE NOTICE '  - ID: %, Email: %, Role: %, Created: %', 
                    rec.id, COALESCE(rec.email, 'No email'), COALESCE(rec.role, 'N/A'), rec.created_at;
            END LOOP;
        ELSE
            FOR rec IN 
                SELECT id, email, role 
                FROM public.profiles 
                LIMIT 5
            LOOP
                RAISE NOTICE '  - ID: %, Email: %, Role: %', 
                    rec.id, COALESCE(rec.email, 'No email'), COALESCE(rec.role, 'N/A');
            END LOOP;
        END IF;
    ELSE
        RAISE NOTICE 'Cannot count profiles - table does not exist';
    END IF;
END $$;

-- 5. Count fighter_profiles
DO $$
DECLARE
    fighter_count INTEGER;
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'fighter_profiles') THEN
        SELECT COUNT(*) INTO fighter_count FROM public.fighter_profiles;
        RAISE NOTICE 'Total fighter profiles: %', fighter_count;
    ELSE
        RAISE NOTICE 'Cannot count fighter profiles - table does not exist';
    END IF;
END $$;

-- 6. Check if profiles exist for auth.users
DO $$
DECLARE
    users_without_profiles INTEGER;
    users_with_profiles INTEGER;
BEGIN
    SELECT COUNT(*) INTO users_without_profiles
    FROM auth.users u
    WHERE NOT EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = u.id);
    
    SELECT COUNT(*) INTO users_with_profiles
    FROM auth.users u
    WHERE EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = u.id);
    
    RAISE NOTICE 'Users with profiles: %', users_with_profiles;
    RAISE NOTICE 'Users WITHOUT profiles: %', users_without_profiles;
    
    IF users_without_profiles > 0 THEN
        RAISE NOTICE '⚠ Warning: Some users in auth.users do not have profiles';
        RAISE NOTICE 'Run auto-create-profiles-trigger.sql to backfill profiles';
    END IF;
END $$;

-- 7. Check RLS policies on profiles
DO $$
DECLARE
    policy_count INTEGER;
    rec RECORD;
BEGIN
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'profiles';
    
    RAISE NOTICE 'RLS policies on profiles table: %', policy_count;
    
    IF policy_count = 0 THEN
        RAISE NOTICE '⚠ Warning: No RLS policies found on profiles table';
    ELSE
        RAISE NOTICE 'Existing policies:';
        FOR rec IN 
            SELECT policyname, cmd 
            FROM pg_policies
            WHERE schemaname = 'public' AND tablename = 'profiles'
        LOOP
            RAISE NOTICE '  - % (command: %)', rec.policyname, rec.cmd;
        END LOOP;
    END IF;
END $$;

-- 8. Try to create a test profile for an existing auth user (if profiles table exists)
-- This will help verify the setup works
DO $$
DECLARE
    test_user_id UUID;
    test_email TEXT;
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'profiles') THEN
        -- Get first auth user that doesn't have a profile
        SELECT u.id, u.email INTO test_user_id, test_email
        FROM auth.users u
        WHERE NOT EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = u.id)
        LIMIT 1;
        
        IF test_user_id IS NOT NULL THEN
            -- Try to insert profile
            BEGIN
                INSERT INTO public.profiles (id, email, role)
                VALUES (test_user_id, test_email, 'fighter')
                ON CONFLICT (id) DO NOTHING;
                RAISE NOTICE '✓ Created test profile for user: %', test_email;
            EXCEPTION WHEN OTHERS THEN
                RAISE NOTICE '✗ Failed to create test profile: %', SQLERRM;
            END;
        ELSE
            RAISE NOTICE 'All auth users already have profiles';
        END IF;
    END IF;
END $$;

-- 9. Final summary query - show all users that should appear in User Management
-- Check what columns exist first, then build appropriate query
DO $$
DECLARE
    has_created_at BOOLEAN;
    has_last_sign_in BOOLEAN;
    has_banned_until BOOLEAN;
    query_text TEXT;
BEGIN
    -- Check which columns exist
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'created_at'
    ) INTO has_created_at;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'last_sign_in_at'
    ) INTO has_last_sign_in;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'banned_until'
    ) INTO has_banned_until;
    
    -- Build query based on available columns
    query_text := 'SELECT 
        COALESCE(p.id, fp.user_id, u.id) as user_id,
        COALESCE(p.email, u.email, ''No email'') as email,
        COALESCE(p.role, ''fighter'') as role';
    
    IF has_created_at THEN
        query_text := query_text || ', p.created_at';
    ELSE
        query_text := query_text || ', u.created_at';
    END IF;
    
    IF has_last_sign_in THEN
        query_text := query_text || ', p.last_sign_in_at';
    END IF;
    
    IF has_banned_until THEN
        query_text := query_text || ', p.banned_until';
    END IF;
    
    query_text := query_text || ',
        fp.name as fighter_name,
        fp.tier as fighter_tier,
        fp.points as fighter_points
    FROM auth.users u
    LEFT JOIN public.profiles p ON p.id = u.id
    LEFT JOIN public.fighter_profiles fp ON fp.user_id = u.id';
    
    IF has_created_at THEN
        query_text := query_text || ' ORDER BY COALESCE(p.created_at, u.created_at) DESC';
    ELSE
        query_text := query_text || ' ORDER BY u.created_at DESC';
    END IF;
    
    query_text := query_text || ' LIMIT 20';
    
    RAISE NOTICE 'Running final summary query...';
    RAISE NOTICE '%', query_text;
END $$;

-- Simplified final query (works regardless of columns)
SELECT 
    COALESCE(p.id, fp.user_id, u.id) as user_id,
    COALESCE(p.email, u.email, 'No email') as email,
    COALESCE(p.role, 'fighter') as role,
    u.created_at as user_created,
    fp.name as fighter_name,
    fp.tier as fighter_tier,
    fp.points as fighter_points
FROM auth.users u
LEFT JOIN public.profiles p ON p.id = u.id
LEFT JOIN public.fighter_profiles fp ON fp.user_id = u.id
ORDER BY u.created_at DESC
LIMIT 20;

