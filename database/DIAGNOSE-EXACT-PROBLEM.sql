-- ============================================================================
-- 🔍 COMPREHENSIVE DIAGNOSTIC: Why RLS is Still Blocking
-- ============================================================================
-- This script checks EVERYTHING that could cause RLS to block access
-- Run this FIRST to see what's wrong, then run the fix script
-- ============================================================================

-- Check 1: Schema permissions (CRITICAL - must be granted first)
SELECT 
  'Check 1: Schema Permissions' as check_type,
  nspname as schema_name,
  CASE 
    WHEN has_schema_privilege('anon', 'public', 'USAGE') THEN '✅ anon has USAGE'
    ELSE '❌ anon MISSING USAGE'
  END || ' | ' ||
  CASE 
    WHEN has_schema_privilege('authenticated', 'public', 'USAGE') THEN '✅ authenticated has USAGE'
    ELSE '❌ authenticated MISSING USAGE'
  END as schema_permissions
FROM pg_namespace
WHERE nspname = 'public';

-- Check 2: Table-level GRANT permissions (CRITICAL - separate from RLS!)
SELECT 
  'Check 2: Table GRANT Permissions' as check_type,
  'fighter_profiles' as table_name,
  CASE 
    WHEN has_table_privilege('anon', 'public.fighter_profiles', 'SELECT') THEN '✅ anon can SELECT'
    ELSE '❌ anon CANNOT SELECT'
  END || ' | ' ||
  CASE 
    WHEN has_table_privilege('authenticated', 'public.fighter_profiles', 'SELECT') THEN '✅ authenticated can SELECT'
    ELSE '❌ authenticated CANNOT SELECT'
  END as table_permissions;

-- Check 3: Is RLS enabled? (Should be YES for security)
SELECT 
  'Check 3: RLS Status' as check_type,
  tablename,
  rowsecurity as rls_enabled,
  CASE 
    WHEN rowsecurity THEN '✅ RLS is enabled (correct)'
    ELSE '⚠️ RLS is DISABLED (security risk, but would allow access)'
  END as status
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('fighter_profiles', 'profiles')
ORDER BY tablename;

-- Check 4: What policies exist? (Should show anon and authenticated policies)
SELECT 
  'Check 4: Existing Policies' as check_type,
  tablename,
  policyname,
  roles,
  cmd as command,
  qual as using_expression,
  CASE 
    WHEN 'anon' = ANY(roles) THEN '✅ anon role'
    WHEN 'authenticated' = ANY(roles) THEN '✅ authenticated role'
    ELSE '⚠️ Other role'
  END as role_status
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN ('fighter_profiles', 'profiles')
ORDER BY tablename, cmd, policyname;

-- Check 5: Are there any views that might interfere?
SELECT 
  'Check 5: Views on fighter_profiles' as check_type,
  schemaname,
  viewname,
  CASE 
    WHEN viewowner = 'postgres' THEN '⚠️ Owned by postgres (might bypass RLS)'
    WHEN viewowner = 'authenticated' THEN '✅ Owned by authenticated'
    WHEN viewowner = 'anon' THEN '✅ Owned by anon'
    ELSE '⚠️ Owned by: ' || viewowner
  END as ownership_status
FROM pg_views
WHERE schemaname = 'public'
  AND (definition ILIKE '%fighter_profiles%' OR viewname ILIKE '%fighter%')
ORDER BY viewname;

-- Check 6: Are there any SECURITY DEFINER functions that might interfere?
SELECT 
  'Check 6: SECURITY DEFINER Functions' as check_type,
  n.nspname as schema_name,
  p.proname as function_name,
  pg_get_functiondef(p.oid) as definition
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE p.prosecdef = true  -- SECURITY DEFINER
  AND n.nspname = 'public'
  AND (pg_get_functiondef(p.oid) ILIKE '%fighter_profiles%' 
       OR p.proname ILIKE '%fighter%')
ORDER BY p.proname;

-- Check 7: Test query as anon role (simulates browser access)
-- This will show if RLS is actually blocking
DO $$
DECLARE
  row_count INTEGER;
BEGIN
  -- Set role to anon (simulates browser with anon key)
  SET ROLE anon;
  
  SELECT COUNT(*) INTO row_count
  FROM public.fighter_profiles
  WHERE user_id IS NOT NULL;
  
  -- Reset role
  RESET ROLE;
  
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE 'Check 7: Test Query as anon Role';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  
  IF row_count = 0 THEN
    RAISE NOTICE '❌ RLS IS BLOCKING: anon role sees 0 rows';
    RAISE NOTICE '   This means policies are NOT working correctly.';
  ELSE
    RAISE NOTICE '✅ RLS ALLOWS ACCESS: anon role sees % rows', row_count;
    RAISE NOTICE '   Policies are working! If app still shows 0 rows, check app code.';
  END IF;
  
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
END $$;

-- Check 8: Test query as authenticated role
DO $$
DECLARE
  row_count INTEGER;
BEGIN
  -- Set role to authenticated (simulates logged-in user)
  SET ROLE authenticated;
  
  SELECT COUNT(*) INTO row_count
  FROM public.fighter_profiles
  WHERE user_id IS NOT NULL;
  
  -- Reset role
  RESET ROLE;
  
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE 'Check 8: Test Query as authenticated Role';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  
  IF row_count = 0 THEN
    RAISE NOTICE '❌ RLS IS BLOCKING: authenticated role sees 0 rows';
    RAISE NOTICE '   This means policies are NOT working correctly.';
  ELSE
    RAISE NOTICE '✅ RLS ALLOWS ACCESS: authenticated role sees % rows', row_count;
    RAISE NOTICE '   Policies are working! If app still shows 0 rows, check app code.';
  END IF;
  
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
END $$;

-- Check 9: Summary - What needs to be fixed?
SELECT 
  'Check 9: Summary' as check_type,
  CASE 
    WHEN NOT has_schema_privilege('anon', 'public', 'USAGE') THEN '❌ MISSING: anon schema USAGE'
    WHEN NOT has_table_privilege('anon', 'public.fighter_profiles', 'SELECT') THEN '❌ MISSING: anon table SELECT'
    WHEN NOT EXISTS (
      SELECT 1 FROM pg_policies 
      WHERE schemaname = 'public' 
        AND tablename = 'fighter_profiles' 
        AND cmd = 'SELECT' 
        AND 'anon' = ANY(roles)
    ) THEN '❌ MISSING: anon SELECT policy'
    ELSE '✅ All anon checks passed'
  END as anon_status,
  CASE 
    WHEN NOT has_schema_privilege('authenticated', 'public', 'USAGE') THEN '❌ MISSING: authenticated schema USAGE'
    WHEN NOT has_table_privilege('authenticated', 'public.fighter_profiles', 'SELECT') THEN '❌ MISSING: authenticated table SELECT'
    WHEN NOT EXISTS (
      SELECT 1 FROM pg_policies 
      WHERE schemaname = 'public' 
        AND tablename = 'fighter_profiles' 
        AND cmd = 'SELECT' 
        AND 'authenticated' = ANY(roles)
    ) THEN '❌ MISSING: authenticated SELECT policy'
    ELSE '✅ All authenticated checks passed'
  END as authenticated_status;

