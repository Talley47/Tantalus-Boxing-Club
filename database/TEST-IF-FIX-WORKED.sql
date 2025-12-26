-- ============================================================================
-- 🧪 TEST: Check if RLS fix worked
-- ============================================================================
-- Run this AFTER applying COPY-THIS-AND-RUN.sql
-- This will tell you if fighters are accessible
-- ============================================================================

-- Test 1: Check permissions
SELECT 
  'PERMISSIONS_CHECK' as test,
  grantee as role_name,
  privilege_type,
  CASE WHEN privilege_type = 'SELECT' THEN '✅ HAS SELECT' ELSE '❌ MISSING' END as status
FROM information_schema.role_table_grants
WHERE table_schema = 'public'
  AND table_name = 'fighter_profiles'
  AND grantee IN ('anon', 'authenticated')
ORDER BY grantee;

-- Test 2: Check RLS policies exist
SELECT 
  'POLICIES_CHECK' as test,
  policyname,
  cmd as command_type,
  roles,
  CASE 
    WHEN cmd = 'SELECT' AND 'anon' = ANY(roles) THEN '✅ Anonymous can read'
    WHEN cmd = 'SELECT' AND 'authenticated' = ANY(roles) THEN '✅ Authenticated can read'
    ELSE '⚠️ Other'
  END as status
FROM pg_policies
WHERE schemaname = 'public' 
  AND tablename = 'fighter_profiles'
ORDER BY cmd, policyname;

-- Test 3: Try to count rows (as authenticated role - simulates your app)
-- This should return a number > 0 if the fix worked
DO $$
DECLARE
  row_count INTEGER;
BEGIN
  -- Simulate authenticated user query
  SET ROLE authenticated;
  SELECT COUNT(*) INTO row_count FROM public.fighter_profiles;
  RESET ROLE;
  
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '                    TEST RESULTS';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '';
  RAISE NOTICE '  Rows accessible as authenticated user: %', row_count;
  RAISE NOTICE '';
  
  IF row_count > 0 THEN
    RAISE NOTICE '  ✅ ✅ ✅ FIX WORKED! ✅ ✅ ✅';
    RAISE NOTICE '  Fighters should appear in your app now.';
  ELSE
    RAISE WARNING '  ❌ ❌ ❌ FIX DID NOT WORK ❌ ❌ ❌';
    RAISE WARNING '  RLS is still blocking access.';
    RAISE WARNING '  Make sure you ran COPY-THIS-AND-RUN.sql completely.';
  END IF;
  
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
END $$;

-- Test 4: Try to count rows (as anonymous role - simulates logged-out users)
DO $$
DECLARE
  row_count INTEGER;
BEGIN
  -- Simulate anonymous user query
  SET ROLE anon;
  SELECT COUNT(*) INTO row_count FROM public.fighter_profiles;
  RESET ROLE;
  
  RAISE NOTICE '';
  RAISE NOTICE '  Rows accessible as anonymous user: %', row_count;
  
  IF row_count > 0 THEN
    RAISE NOTICE '  ✅ Anonymous users can also see fighters (good for homepage).';
  ELSE
    RAISE WARNING '  ⚠️  Anonymous users cannot see fighters (homepage may not work).';
  END IF;
  
  RAISE NOTICE '';
END $$;

