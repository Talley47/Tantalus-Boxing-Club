-- ============================================================================
-- 🔍 DIAGNOSTIC: Check Current RLS State
-- ============================================================================
-- This script checks:
-- 1. Current permissions on fighter_profiles and profiles
-- 2. Current RLS policies
-- 3. Whether RLS is enabled
-- 4. Tests a query that simulates the app's exact query pattern
-- ============================================================================

-- Check schema permissions
SELECT 
  'Schema Permissions' as check_type,
  nspname as schema_name,
  array_agg(privilege_type ORDER BY privilege_type) as privileges
FROM (
  SELECT 
    n.nspname,
    a.privilege_type
  FROM pg_namespace n
  CROSS JOIN LATERAL aclexplode(n.nspacl) a
  WHERE n.nspname = 'public'
    AND (a.grantee = (SELECT oid FROM pg_roles WHERE rolname = 'anon')
         OR a.grantee = (SELECT oid FROM pg_roles WHERE rolname = 'authenticated'))
) sub
GROUP BY nspname;

-- Check table permissions (simplified approach)
SELECT 
  'Table Permissions' as check_type,
  schemaname,
  tablename,
  CASE 
    WHEN has_table_privilege('anon', schemaname||'.'||tablename, 'SELECT') THEN 'anon: SELECT ✅'
    ELSE 'anon: NO SELECT ❌'
  END || ' | ' ||
  CASE 
    WHEN has_table_privilege('authenticated', schemaname||'.'||tablename, 'SELECT') THEN 'authenticated: SELECT ✅'
    ELSE 'authenticated: NO SELECT ❌'
  END as permissions
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('fighter_profiles', 'profiles')
ORDER BY tablename;

-- Check if RLS is enabled
SELECT 
  'RLS Status' as check_type,
  schemaname,
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('fighter_profiles', 'profiles')
ORDER BY tablename;

-- Check current policies
SELECT 
  'Current Policies' as check_type,
  schemaname,
  tablename,
  policyname,
  roles,
  cmd as command,
  qual as using_expression,
  with_check as with_check_expression
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN ('fighter_profiles', 'profiles')
ORDER BY tablename, cmd, policyname;

-- Check for views that might interfere
SELECT 
  'Views on fighter_profiles' as check_type,
  schemaname,
  viewname,
  definition
FROM pg_views
WHERE schemaname = 'public'
  AND (definition ILIKE '%fighter_profiles%' OR viewname ILIKE '%fighter%')
ORDER BY viewname;

-- Test query that simulates the app's exact query pattern
-- This will show if RLS is blocking
SELECT 
  'Test Query Result' as check_type,
  COUNT(*) as row_count,
  CASE 
    WHEN COUNT(*) = 0 THEN '❌ RLS IS BLOCKING - No rows returned'
    WHEN COUNT(*) > 0 THEN '✅ RLS ALLOWS ACCESS - Rows returned'
  END as status
FROM public.fighter_profiles
WHERE user_id IS NOT NULL;

-- Show sample rows (if any)
SELECT 
  'Sample Rows' as check_type,
  id,
  user_id,
  name,
  points
FROM public.fighter_profiles
WHERE user_id IS NOT NULL
ORDER BY points DESC
LIMIT 5;
