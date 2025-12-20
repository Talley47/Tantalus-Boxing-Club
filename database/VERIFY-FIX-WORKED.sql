-- =====================================================
-- VERIFICATION SCRIPT: Check if RLS fix worked
-- Run this AFTER running the fix script
-- =====================================================

-- 1) Check if policies exist (should show 2 policies)
SELECT 
    'POLICIES' as check_type,
    policyname,
    roles,
    cmd,
    permissive
FROM pg_policies 
WHERE schemaname = 'public' 
  AND tablename = 'fighter_profiles'
ORDER BY policyname;

-- Expected: Should see 2 rows:
--   - "Authenticated users can view fighter profiles" (roles: {authenticated})
--   - "Anonymous users can view fighter profiles" (roles: {anon})

-- 2) Check table privileges (should show SELECT for both roles)
SELECT 
    'PRIVILEGES' as check_type,
    grantee,
    privilege_type,
    table_name
FROM information_schema.role_table_grants
WHERE table_name = 'fighter_profiles'
  AND grantee IN ('anon', 'authenticated')
ORDER BY grantee, privilege_type;

-- Expected: Should see 2 rows:
--   - grantee: anon, privilege_type: SELECT
--   - grantee: authenticated, privilege_type: SELECT

-- 3) Check schema privileges (simplified - test actual access instead)
-- If the GRANT statements in the fix script ran successfully, this will work
-- The real test is whether roles can actually query the table (see steps 4-5)
SELECT 
    'SCHEMA_PRIVILEGES_CHECK' as check_type,
    has_schema_privilege('anon', 'public', 'USAGE') as anon_has_usage,
    has_schema_privilege('authenticated', 'public', 'USAGE') as authenticated_has_usage;

-- Expected: Both should be TRUE (t)
-- If FALSE (f), the GRANT USAGE statement didn't run successfully

-- 4) Test as anonymous role (simulates unauthenticated user)
SET ROLE anon;
SELECT 
    'TEST_AS_ANON' as check_type,
    COUNT(*) as visible_rows
FROM public.fighter_profiles;
RESET ROLE;

-- Expected: visible_rows should be > 0 if there's data in the table

-- 5) Test as authenticated role (simulates logged-in user)
SET ROLE authenticated;
SELECT 
    'TEST_AS_AUTHENTICATED' as check_type,
    COUNT(*) as visible_rows
FROM public.fighter_profiles;
RESET ROLE;

-- Expected: visible_rows should be > 0 if there's data in the table

-- 6) Check total rows (bypasses RLS - shows actual data count)
SELECT 
    'TOTAL_ROWS' as check_type,
    COUNT(*) as total_rows_in_table
FROM public.fighter_profiles;

-- Compare total_rows_in_table with visible_rows from steps 4 and 5
-- If total_rows > 0 but visible_rows = 0, RLS is still blocking

-- 7) Sample data (should show fighter profiles if fix worked)
SELECT 
    'SAMPLE_DATA' as check_type,
    user_id,
    name,
    handle,
    tier,
    points
FROM public.fighter_profiles
LIMIT 5;

-- Expected: Should show up to 5 fighter profiles

