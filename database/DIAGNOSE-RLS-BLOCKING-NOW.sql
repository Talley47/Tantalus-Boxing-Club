-- ============================================================================
-- 🔍 COMPREHENSIVE DIAGNOSTIC: Why RLS is Blocking fighter_profiles
-- ============================================================================
-- Run this FIRST to understand what's wrong
-- Then run FIX-RLS-BLOCKING-DEFINITIVE.sql
-- ============================================================================

-- ============================================================================
-- CHECK 1: Does the table exist?
-- ============================================================================
SELECT 
  'CHECK_1_TABLE_EXISTS' as check_num,
  CASE WHEN EXISTS (
    SELECT 1 FROM pg_tables 
    WHERE schemaname = 'public' AND tablename = 'fighter_profiles'
  )
    THEN '✅ YES - Table exists'
    ELSE '❌ NO - Table does not exist!'
  END as result;

-- ============================================================================
-- CHECK 2: Is RLS enabled?
-- ============================================================================
SELECT 
  'CHECK_2_RLS_ENABLED' as check_num,
  tablename,
  rowsecurity as rls_enabled,
  CASE WHEN rowsecurity 
    THEN '✅ YES - RLS is enabled'
    ELSE '❌ NO - RLS is disabled'
  END as result
FROM pg_tables 
WHERE schemaname = 'public' AND tablename = 'fighter_profiles';

-- ============================================================================
-- CHECK 3: What policies exist?
-- ============================================================================
SELECT 
  'CHECK_3_POLICIES' as check_num,
  policyname,
  roles,
  cmd as command,
  qual as using_clause,
  with_check as with_check_clause
FROM pg_policies 
WHERE schemaname = 'public' AND tablename = 'fighter_profiles'
ORDER BY policyname;

-- ============================================================================
-- CHECK 4: Are GRANT permissions set? (CRITICAL - often missing!)
-- ============================================================================
SELECT 
  'CHECK_4_GRANTS' as check_num,
  grantee as role,
  privilege_type,
  CASE WHEN privilege_type = 'SELECT' 
    THEN '✅ YES - SELECT granted'
    ELSE '❌ NO - SELECT not granted'
  END as result
FROM information_schema.table_privileges
WHERE table_schema = 'public' 
  AND table_name = 'fighter_profiles'
  AND privilege_type = 'SELECT'
  AND grantee IN ('anon', 'authenticated')
ORDER BY grantee;

-- ============================================================================
-- CHECK 5: Does data exist? (as superuser - bypasses RLS)
-- ============================================================================
DO $$
DECLARE
  row_count INTEGER;
BEGIN
  SET ROLE postgres;
  SELECT COUNT(*) INTO row_count FROM public.fighter_profiles;
  RESET ROLE;
  
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE 'CHECK 5: Data exists?';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  
  IF row_count > 0 THEN
    RAISE NOTICE '✅ YES - % rows exist in table', row_count;
  ELSE
    RAISE WARNING '❌ NO - Table is empty (0 rows)';
    RAISE WARNING '   This might be why you see no fighters!';
  END IF;
END $$;

-- ============================================================================
-- CHECK 6: Can anon role see data? (simulates homepage before login)
-- ============================================================================
DO $$
DECLARE
  row_count INTEGER;
BEGIN
  SET ROLE anon;
  SELECT COUNT(*) INTO row_count FROM public.fighter_profiles;
  RESET ROLE;
  
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE 'CHECK 6: Can anon role see data?';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  
  IF row_count > 0 THEN
    RAISE NOTICE '✅ YES - anon can see % rows', row_count;
  ELSE
    RAISE WARNING '❌ NO - anon cannot see any rows (RLS blocking!)';
    RAISE WARNING '   This is why homepage shows no fighters!';
  END IF;
END $$;

-- ============================================================================
-- CHECK 7: Can authenticated role see data? (simulates logged-in user)
-- ============================================================================
DO $$
DECLARE
  row_count INTEGER;
BEGIN
  SET ROLE authenticated;
  SELECT COUNT(*) INTO row_count FROM public.fighter_profiles;
  RESET ROLE;
  
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE 'CHECK 7: Can authenticated role see data?';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  
  IF row_count > 0 THEN
    RAISE NOTICE '✅ YES - authenticated can see % rows', row_count;
  ELSE
    RAISE WARNING '❌ NO - authenticated cannot see any rows (RLS blocking!)';
  END IF;
END $$;

-- ============================================================================
-- CHECK 8: Schema usage permissions (CRITICAL - often missing!)
-- ============================================================================
SELECT 
  'CHECK_8_SCHEMA_USAGE' as check_num,
  grantee as role,
  privilege_type,
  CASE WHEN privilege_type = 'USAGE' 
    THEN '✅ YES - USAGE granted'
    ELSE '❌ NO - USAGE not granted'
  END as result
FROM information_schema.usage_privileges
WHERE object_schema = 'public' 
  AND grantee IN ('anon', 'authenticated')
ORDER BY grantee;

-- ============================================================================
-- SUMMARY
-- ============================================================================
DO $$
DECLARE
  rls_enabled BOOLEAN;
  policy_count INTEGER;
  grant_count INTEGER;
  schema_usage_count INTEGER;
  data_exists BOOLEAN;
  anon_can_see INTEGER;
  auth_can_see INTEGER;
  all_checks_pass BOOLEAN := true;
BEGIN
  -- Get RLS status
  SELECT rowsecurity INTO rls_enabled
  FROM pg_tables 
  WHERE schemaname = 'public' AND tablename = 'fighter_profiles';
  
  -- Get policy count
  SELECT COUNT(*) INTO policy_count
  FROM pg_policies 
  WHERE schemaname = 'public' AND tablename = 'fighter_profiles';
  
  -- Get grant count
  SELECT COUNT(*) INTO grant_count
  FROM information_schema.table_privileges
  WHERE table_schema = 'public' 
    AND table_name = 'fighter_profiles'
    AND privilege_type = 'SELECT'
    AND grantee IN ('anon', 'authenticated');
  
  -- Get schema usage count
  SELECT COUNT(*) INTO schema_usage_count
  FROM information_schema.usage_privileges
  WHERE object_schema = 'public' 
    AND grantee IN ('anon', 'authenticated');
  
  -- Check if data exists
  SET ROLE postgres;
  SELECT COUNT(*) > 0 INTO data_exists FROM public.fighter_profiles;
  RESET ROLE;
  
  -- Check anon access
  SET ROLE anon;
  SELECT COUNT(*) INTO anon_can_see FROM public.fighter_profiles;
  RESET ROLE;
  
  -- Check authenticated access
  SET ROLE authenticated;
  SELECT COUNT(*) INTO auth_can_see FROM public.fighter_profiles;
  RESET ROLE;
  
  RAISE NOTICE '';
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '                    DIAGNOSTIC SUMMARY';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '';
  RAISE NOTICE 'RLS Enabled: %', CASE WHEN rls_enabled THEN '✅ YES' ELSE '❌ NO' END;
  RAISE NOTICE 'Policies Count: %', policy_count;
  RAISE NOTICE 'SELECT Grants: % (need 2: anon + authenticated)', grant_count;
  RAISE NOTICE 'Schema USAGE Grants: % (need 2: anon + authenticated)', schema_usage_count;
  RAISE NOTICE 'Data Exists: %', CASE WHEN data_exists THEN '✅ YES' ELSE '❌ NO' END;
  RAISE NOTICE 'Anon Can See: % rows', anon_can_see;
  RAISE NOTICE 'Authenticated Can See: % rows', auth_can_see;
  RAISE NOTICE '';
  
  -- Determine issues
  IF NOT rls_enabled THEN
    RAISE WARNING '❌ ISSUE: RLS is disabled (security scanner will flag this)';
    all_checks_pass := false;
  END IF;
  
  IF policy_count < 2 THEN
    RAISE WARNING '❌ ISSUE: Need at least 2 policies (anon + authenticated)';
    RAISE WARNING '   Current: % policies', policy_count;
    all_checks_pass := false;
  END IF;
  
  IF grant_count < 2 THEN
    RAISE WARNING '❌ ISSUE: Missing SELECT grants (anon and/or authenticated)';
    RAISE WARNING '   Current: % grants (need 2)', grant_count;
    all_checks_pass := false;
  END IF;
  
  IF schema_usage_count < 2 THEN
    RAISE WARNING '❌ ISSUE: Missing schema USAGE grants (anon and/or authenticated)';
    RAISE WARNING '   Current: % grants (need 2)', schema_usage_count;
    all_checks_pass := false;
  END IF;
  
  IF NOT data_exists THEN
    RAISE WARNING '❌ ISSUE: No data in table (might be empty database)';
    all_checks_pass := false;
  END IF;
  
  IF anon_can_see = 0 AND data_exists THEN
    RAISE WARNING '❌ ISSUE: anon role cannot see data (RLS blocking!)';
    RAISE WARNING '   This is why homepage shows no fighters!';
    all_checks_pass := false;
  END IF;
  
  IF auth_can_see = 0 AND data_exists THEN
    RAISE WARNING '❌ ISSUE: authenticated role cannot see data (RLS blocking!)';
    all_checks_pass := false;
  END IF;
  
  RAISE NOTICE '';
  IF all_checks_pass THEN
    RAISE NOTICE '✅ ✅ ✅ ALL CHECKS PASSED! ✅ ✅ ✅';
    RAISE NOTICE '';
    RAISE NOTICE 'Everything looks good! If you still see "NO FIGHTERS",';
    RAISE NOTICE 'try hard refreshing your browser (Ctrl+Shift+R).';
  ELSE
    RAISE WARNING '⚠️  ⚠️  ⚠️  ISSUES FOUND ⚠️  ⚠️  ⚠️';
    RAISE WARNING '';
    RAISE WARNING 'NEXT STEP: Run FIX-RLS-BLOCKING-DEFINITIVE.sql';
    RAISE WARNING 'This will fix all the issues identified above.';
  END IF;
  
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
END $$;

-- ============================================================================
-- ✅ DIAGNOSTIC COMPLETE
-- ============================================================================
-- Review the output above to see what's wrong
-- Then run: FIX-RLS-BLOCKING-DEFINITIVE.sql
-- ============================================================================

