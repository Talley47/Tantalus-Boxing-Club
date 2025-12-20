-- =====================================================
-- COMPREHENSIVE DIAGNOSTIC: Find the exact problem
-- Run this to see EVERYTHING about fighter_profiles
-- =====================================================

-- 1) Does the table exist? Where?
SELECT 
    'TABLE_LOCATION' as check_type,
    schemaname,
    tablename,
    tableowner
FROM pg_tables 
WHERE tablename = 'fighter_profiles';

-- Expected: Should see schemaname = 'public'

-- 2) Is RLS enabled?
SELECT 
    'RLS_STATUS' as check_type,
    relname as table_name,
    relrowsecurity as rls_enabled,
    relforcerowsecurity as rls_enforced
FROM pg_class
WHERE relname = 'fighter_profiles';

-- Expected: rls_enabled = t (true)

-- 3) What policies exist?
SELECT 
    'POLICIES' as check_type,
    policyname,
    permissive,
    roles::text as who_can_access,
    cmd as command_type,
    qual as policy_condition
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'fighter_profiles'
ORDER BY policyname;

-- Expected: Should see 2 policies for SELECT
-- If 0 policies = THIS IS THE PROBLEM!

-- 4) What privileges exist?
SELECT 
    'PRIVILEGES' as check_type,
    grantee,
    privilege_type,
    table_name
FROM information_schema.role_table_grants
WHERE table_name = 'fighter_profiles'
  AND grantee IN ('anon', 'authenticated')
ORDER BY grantee, privilege_type;

-- Expected: Both 'anon' and 'authenticated' should have 'SELECT'

-- 5) Can anon role see data?
SET ROLE anon;
SELECT 
    'TEST_ANON' as check_type,
    COUNT(*) as visible_rows
FROM public.fighter_profiles;
RESET ROLE;

-- Expected: visible_rows > 0 if data exists and RLS allows it

-- 6) Can authenticated role see data?
SET ROLE authenticated;
SELECT 
    'TEST_AUTHENTICATED' as check_type,
    COUNT(*) as visible_rows
FROM public.fighter_profiles;
RESET ROLE;

-- Expected: visible_rows > 0 if data exists and RLS allows it

-- 7) How much data actually exists? (bypasses RLS)
SELECT 
    'TOTAL_DATA' as check_type,
    COUNT(*) as total_rows
FROM public.fighter_profiles;

-- Expected: total_rows > 0 if there's data in the table
-- If total_rows = 0, the table is empty (not an RLS issue)

-- 8) Sample data (bypasses RLS)
SELECT 
    'SAMPLE_DATA' as check_type,
    id,
    user_id,
    name,
    handle
FROM public.fighter_profiles
LIMIT 3;

-- Expected: Should show up to 3 fighter profiles if data exists

