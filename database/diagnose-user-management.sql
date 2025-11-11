-- Diagnose User Management Issues
-- Run this in Supabase SQL Editor to check why users aren't showing

-- 1. Check if profiles table exists and has data
DO $$
DECLARE
    profile_count INTEGER;
    auth_user_count INTEGER;
    profiles_without_auth INTEGER;
    auth_without_profiles INTEGER;
BEGIN
    -- Count profiles
    SELECT COUNT(*) INTO profile_count FROM public.profiles;
    
    -- Count auth.users
    SELECT COUNT(*) INTO auth_user_count FROM auth.users;
    
    -- Count profiles without corresponding auth.users
    SELECT COUNT(*) INTO profiles_without_auth
    FROM public.profiles p
    WHERE NOT EXISTS (SELECT 1 FROM auth.users u WHERE u.id = p.id);
    
    -- Count auth.users without profiles
    SELECT COUNT(*) INTO auth_without_profiles
    FROM auth.users u
    WHERE NOT EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = u.id);
    
    RAISE NOTICE '═══════════════════════════════════════';
    RAISE NOTICE 'User Management Diagnostic';
    RAISE NOTICE '═══════════════════════════════════════';
    RAISE NOTICE 'Total users in auth.users: %', auth_user_count;
    RAISE NOTICE 'Total profiles in profiles table: %', profile_count;
    RAISE NOTICE 'Profiles without auth.users: %', profiles_without_auth;
    RAISE NOTICE 'auth.users without profiles: %', auth_without_profiles;
    RAISE NOTICE '═══════════════════════════════════════';
    
    IF profile_count = 0 THEN
        RAISE NOTICE '⚠ WARNING: profiles table is empty!';
        RAISE NOTICE 'Run setup-profiles-for-existing-users.sql to create profiles';
    END IF;
    
    IF auth_without_profiles > 0 THEN
        RAISE NOTICE '⚠ WARNING: % users in auth.users do not have profiles', auth_without_profiles;
        RAISE NOTICE 'Run setup-profiles-for-existing-users.sql to backfill profiles';
    END IF;
END $$;

-- 2. Check admin account
DO $$
DECLARE
    admin_count INTEGER;
    admin_emails TEXT[];
BEGIN
    SELECT COUNT(*), ARRAY_AGG(email)
    INTO admin_count, admin_emails
    FROM public.profiles
    WHERE role = 'admin';
    
    RAISE NOTICE 'Admin accounts found: %', admin_count;
    IF admin_count > 0 THEN
        RAISE NOTICE 'Admin emails: %', array_to_string(admin_emails, ', ');
    ELSE
        RAISE NOTICE '⚠ WARNING: No admin accounts found!';
    END IF;
END $$;

-- 3. Check RLS policies on profiles table
DO $$
DECLARE
    policy_rec RECORD;
    policy_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'profiles';
    
    RAISE NOTICE 'RLS policies on profiles table: %', policy_count;
    
    IF policy_count = 0 THEN
        RAISE NOTICE '⚠ WARNING: No RLS policies found!';
    ELSE
        RAISE NOTICE 'Existing policies:';
        FOR policy_rec IN 
            SELECT policyname, cmd, qual
            FROM pg_policies
            WHERE schemaname = 'public' AND tablename = 'profiles'
        LOOP
            RAISE NOTICE '  - % (%): %', policy_rec.policyname, policy_rec.cmd, policy_rec.qual;
        END LOOP;
    END IF;
END $$;

-- 4. Check if get_all_users_for_admin function exists
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'get_all_users_for_admin' 
        AND pronamespace = 'public'::regnamespace
    ) THEN
        RAISE NOTICE '✓ get_all_users_for_admin() function exists';
    ELSE
        RAISE NOTICE '✗ get_all_users_for_admin() function does NOT exist';
        RAISE NOTICE 'Run admin-users-view.sql to create it';
    END IF;
END $$;

-- 5. Show sample profiles (first 5)
SELECT 
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
LIMIT 5;

-- 6. Test admin function (if logged in as admin)
-- This will fail if not admin, which is expected
DO $$
BEGIN
    BEGIN
        PERFORM get_all_users_for_admin();
        RAISE NOTICE '✓ Admin function works - returns data';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE '✗ Admin function error: %', SQLERRM;
            IF SQLERRM LIKE '%Admin privileges required%' THEN
                RAISE NOTICE 'This is expected if you are not logged in as admin';
            END IF;
    END;
END $$;

