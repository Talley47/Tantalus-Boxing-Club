-- ============================================================================
-- 🔍 DIAGNOSTIC: Check fighter_profiles RLS Status
-- ============================================================================
-- Run this to see the current state of RLS policies and permissions
-- ============================================================================

-- Check 1: Is RLS enabled?
SELECT 
  'RLS_STATUS' as check_type,
  tablename,
  rowsecurity as rls_enabled,
  CASE WHEN rowsecurity THEN '✅ ENABLED' ELSE '❌ DISABLED' END as status
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename = 'fighter_profiles';

-- Check 2: What permissions exist?
SELECT 
  'PERMISSIONS' as check_type,
  grantee as role_name,
  privilege_type,
  CASE WHEN privilege_type = 'SELECT' THEN '✅' ELSE '⚠️' END as has_select
FROM information_schema.role_table_grants
WHERE table_schema = 'public'
  AND table_name = 'fighter_profiles'
  AND grantee IN ('anon', 'authenticated')
ORDER BY grantee, privilege_type;

-- Check 3: What RLS policies exist?
SELECT 
  'POLICIES' as check_type,
  policyname,
  cmd as command_type,
  roles,
  qual as using_clause,
  CASE 
    WHEN cmd = 'SELECT' AND 'authenticated' = ANY(roles) THEN '✅ Authenticated SELECT'
    WHEN cmd = 'SELECT' AND 'anon' = ANY(roles) THEN '✅ Anonymous SELECT'
    ELSE '⚠️ Other'
  END as policy_type
FROM pg_policies
WHERE schemaname = 'public' 
  AND tablename = 'fighter_profiles'
ORDER BY cmd, policyname;

-- Check 4: How many rows exist? (as postgres superuser - bypasses RLS)
DO $$
DECLARE
  total_rows INTEGER;
  rows_with_user_id INTEGER;
BEGIN
  SET ROLE postgres;
  SELECT COUNT(*) INTO total_rows FROM public.fighter_profiles;
  SELECT COUNT(*) INTO rows_with_user_id FROM public.fighter_profiles WHERE user_id IS NOT NULL;
  RESET ROLE;
  
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '                    DATA COUNT (Bypassing RLS)';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '  Total rows in fighter_profiles: %', total_rows;
  RAISE NOTICE '  Rows with user_id: %', rows_with_user_id;
  RAISE NOTICE '  Rows without user_id: %', total_rows - rows_with_user_id;
  RAISE NOTICE '';
  
  IF total_rows = 0 THEN
    RAISE WARNING '  ⚠️  No data found in fighter_profiles table!';
  ELSIF rows_with_user_id = 0 THEN
    RAISE WARNING '  ⚠️  All rows have NULL user_id - this may cause issues!';
  ELSE
    RAISE NOTICE '  ✅ Data exists and looks good';
  END IF;
END $$;

-- Check 5: Summary and recommendations
DO $$
DECLARE
  rls_enabled BOOLEAN;
  has_anon_select BOOLEAN;
  has_auth_select BOOLEAN;
  anon_has_permission BOOLEAN;
  auth_has_permission BOOLEAN;
BEGIN
  -- Check RLS status
  SELECT rowsecurity INTO rls_enabled
  FROM pg_tables
  WHERE schemaname = 'public' AND tablename = 'fighter_profiles';
  
  -- Check policies
  SELECT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'fighter_profiles'
      AND cmd = 'SELECT'
      AND 'anon' = ANY(roles)
  ) INTO has_anon_select;
  
  SELECT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'fighter_profiles'
      AND cmd = 'SELECT'
      AND 'authenticated' = ANY(roles)
  ) INTO has_auth_select;
  
  -- Check permissions
  SELECT EXISTS (
    SELECT 1 FROM information_schema.role_table_grants
    WHERE table_schema = 'public'
      AND table_name = 'fighter_profiles'
      AND grantee = 'anon'
      AND privilege_type = 'SELECT'
  ) INTO anon_has_permission;
  
  SELECT EXISTS (
    SELECT 1 FROM information_schema.role_table_grants
    WHERE table_schema = 'public'
      AND table_name = 'fighter_profiles'
      AND grantee = 'authenticated'
      AND privilege_type = 'SELECT'
  ) INTO auth_has_permission;
  
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '                    SUMMARY & RECOMMENDATIONS';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '';
  RAISE NOTICE '  RLS Enabled: %', CASE WHEN rls_enabled THEN '✅ YES' ELSE '❌ NO' END;
  RAISE NOTICE '  Anonymous SELECT Policy: %', CASE WHEN has_anon_select THEN '✅ YES' ELSE '❌ NO' END;
  RAISE NOTICE '  Authenticated SELECT Policy: %', CASE WHEN has_auth_select THEN '✅ YES' ELSE '❌ NO' END;
  RAISE NOTICE '  Anonymous SELECT Permission: %', CASE WHEN anon_has_permission THEN '✅ YES' ELSE '❌ NO' END;
  RAISE NOTICE '  Authenticated SELECT Permission: %', CASE WHEN auth_has_permission THEN '✅ YES' ELSE '❌ NO' END;
  RAISE NOTICE '';
  
  IF NOT rls_enabled THEN
    RAISE WARNING '  ⚠️  RLS is DISABLED. Enable it for security.';
  END IF;
  
  IF NOT has_anon_select THEN
    RAISE WARNING '  ⚠️  Missing anonymous SELECT policy. Homepage may not work for logged-out users.';
  END IF;
  
  IF NOT has_auth_select THEN
    RAISE WARNING '  ⚠️  Missing authenticated SELECT policy. Logged-in users cannot see fighters.';
  END IF;
  
  IF NOT anon_has_permission THEN
    RAISE WARNING '  ⚠️  Anonymous role lacks SELECT permission. Grant it!';
  END IF;
  
  IF NOT auth_has_permission THEN
    RAISE WARNING '  ⚠️  Authenticated role lacks SELECT permission. Grant it!';
  END IF;
  
  IF rls_enabled AND has_anon_select AND has_auth_select AND anon_has_permission AND auth_has_permission THEN
    RAISE NOTICE '  ✅ ✅ ✅ ALL CHECKS PASSED! ✅ ✅ ✅';
    RAISE NOTICE '';
    RAISE NOTICE '  If fighters still don''t appear, check:';
    RAISE NOTICE '    1. Browser console for JavaScript errors';
    RAISE NOTICE '    2. Network tab for failed API requests';
    RAISE NOTICE '    3. Supabase logs for query errors';
  ELSE
    RAISE NOTICE '';
    RAISE NOTICE '  🔧 TO FIX: Run database/FIX-FIGHTER-PROFILES-RLS-IMMEDIATE.sql';
  END IF;
  
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
END $$;

