-- ============================================================================
-- 🚨 TEST EXACT APP QUERY PATTERN
-- ============================================================================
-- This script tests the EXACT query pattern your app uses
-- It will show you EXACTLY why RLS is blocking
-- ============================================================================

-- Test 1: Check if we can see ANY rows (diagnostic query from app)
SELECT 
  'Test 1: Diagnostic Query (App Pattern)' as test_name,
  COUNT(*) as row_count,
  CASE 
    WHEN COUNT(*) = 0 THEN '❌ BLOCKED - RLS is filtering all rows'
    WHEN COUNT(*) > 0 THEN '✅ SUCCESS - RLS allows access! Rows: ' || COUNT(*)::text
  END as result
FROM public.fighter_profiles
LIMIT 5;

-- Test 2: Check the exact query your app uses (main query)
SELECT 
  'Test 2: Main Query (App Pattern)' as test_name,
  COUNT(*) as row_count,
  CASE 
    WHEN COUNT(*) = 0 THEN '❌ BLOCKED - RLS is filtering all rows'
    WHEN COUNT(*) > 0 THEN '✅ SUCCESS - RLS allows access! Rows: ' || COUNT(*)::text
  END as result
FROM public.fighter_profiles
WHERE user_id IS NOT NULL;

-- Test 3: Check current role (what role is running these queries?)
SELECT 
  'Test 3: Current Role' as test_name,
  current_user as current_role,
  session_user as session_role,
  CASE 
    WHEN current_user = 'anon' THEN '⚠️ Running as anon (browser before login)'
    WHEN current_user = 'authenticated' THEN '✅ Running as authenticated (browser after login)'
    WHEN current_user = 'postgres' THEN '⚠️ Running as postgres (bypasses RLS - not realistic)'
    ELSE '⚠️ Running as ' || current_user
  END as role_info;

-- Test 4: Check if policies exist for current role
SELECT 
  'Test 4: Policies for Current Role' as test_name,
  policyname,
  roles,
  cmd,
  qual as using_clause,
  CASE 
    WHEN 'anon' = ANY(roles) THEN '✅ Has anon policy'
    WHEN 'authenticated' = ANY(roles) THEN '✅ Has authenticated policy'
    ELSE '❌ No policy for current role'
  END as policy_status
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'fighter_profiles'
  AND cmd = 'SELECT'
ORDER BY 
  CASE WHEN 'anon' = ANY(roles) THEN 1 ELSE 2 END,
  policyname;

-- Test 5: Check permissions (GRANT statements)
SELECT 
  'Test 5: Table Permissions' as test_name,
  CASE 
    WHEN has_table_privilege('anon', 'public.fighter_profiles', 'SELECT') THEN '✅ anon can SELECT'
    ELSE '❌ anon CANNOT SELECT'
  END || ' | ' ||
  CASE 
    WHEN has_table_privilege('authenticated', 'public.fighter_profiles', 'SELECT') THEN '✅ authenticated can SELECT'
    ELSE '❌ authenticated CANNOT SELECT'
  END as permissions;

-- Test 6: Check schema permissions
SELECT 
  'Test 6: Schema Permissions' as test_name,
  CASE 
    WHEN has_schema_privilege('anon', 'public', 'USAGE') THEN '✅ anon has USAGE on public schema'
    ELSE '❌ anon MISSING USAGE on public schema'
  END || ' | ' ||
  CASE 
    WHEN has_schema_privilege('authenticated', 'public', 'USAGE') THEN '✅ authenticated has USAGE on public schema'
    ELSE '❌ authenticated MISSING USAGE on public schema'
  END as schema_permissions;

-- Test 7: Simulate app query as anon role (browser before login)
DO $$
DECLARE
  row_count INTEGER;
BEGIN
  SET ROLE anon;
  SELECT COUNT(*) INTO row_count
  FROM public.fighter_profiles
  WHERE user_id IS NOT NULL;
  RESET ROLE;
  
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE 'Test 7: Simulating App Query as anon Role';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  
  IF row_count = 0 THEN
    RAISE WARNING '❌ FAILED: anon role sees 0 rows';
    RAISE WARNING '   This is why your app shows "NO FIGHTERS RETURNED FROM QUERY"';
    RAISE WARNING '   Your browser uses the anon key, which runs queries as the anon role';
    RAISE WARNING '   The anon role needs a SELECT policy on fighter_profiles';
  ELSE
    RAISE NOTICE '✅ SUCCESS: anon role sees % rows', row_count;
    RAISE NOTICE '   This means RLS is working correctly for anonymous users';
  END IF;
  
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
END $$;

-- Test 8: Simulate app query as authenticated role (browser after login)
DO $$
DECLARE
  row_count INTEGER;
BEGIN
  SET ROLE authenticated;
  SELECT COUNT(*) INTO row_count
  FROM public.fighter_profiles
  WHERE user_id IS NOT NULL;
  RESET ROLE;
  
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE 'Test 8: Simulating App Query as authenticated Role';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  
  IF row_count = 0 THEN
    RAISE WARNING '❌ FAILED: authenticated role sees 0 rows';
    RAISE WARNING '   This is why logged-in users also see "NO FIGHTERS RETURNED FROM QUERY"';
    RAISE WARNING '   The authenticated role needs a SELECT policy on fighter_profiles';
  ELSE
    RAISE NOTICE '✅ SUCCESS: authenticated role sees % rows', row_count;
    RAISE NOTICE '   This means RLS is working correctly for logged-in users';
  END IF;
  
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
END $$;

-- Test 9: Show actual data (as postgres - to confirm data exists)
SELECT 
  'Test 9: Actual Data (as postgres - confirms data exists)' as test_name,
  COUNT(*) as total_rows,
  COUNT(*) FILTER (WHERE user_id IS NOT NULL) as rows_with_user_id
FROM public.fighter_profiles;

-- Test 10: Show sample rows (as postgres)
SELECT 
  'Test 10: Sample Rows (as postgres)' as test_name,
  id,
  user_id,
  name,
  points,
  tier,
  weight_class
FROM public.fighter_profiles
WHERE user_id IS NOT NULL
ORDER BY points DESC
LIMIT 10;

