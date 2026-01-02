-- ============================================================================
-- DIAGNOSTIC: Check Current Database State
-- Run this FIRST to see what's wrong
-- ============================================================================

-- 1. Check if RLS is enabled
SELECT 
  schemaname,
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename IN ('fighter_profiles', 'profiles')
ORDER BY tablename;

-- 2. List ALL existing policies
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd as command,
  qual as using_expression,
  with_check as with_check_expression
FROM pg_policies 
WHERE schemaname = 'public' 
  AND tablename IN ('fighter_profiles', 'profiles')
ORDER BY tablename, policyname;

-- 3. Check table permissions (grants)
SELECT 
  grantee,
  table_schema,
  table_name,
  privilege_type
FROM information_schema.table_privileges
WHERE table_schema = 'public'
  AND table_name IN ('fighter_profiles', 'profiles')
  AND grantee IN ('anon', 'authenticated', 'public')
ORDER BY table_name, grantee, privilege_type;

-- 4. Check schema permissions (check if roles can use public schema)
SELECT 
  has_schema_privilege('anon', 'public', 'USAGE') as anon_can_use_schema,
  has_schema_privilege('authenticated', 'public', 'USAGE') as authenticated_can_use_schema,
  has_schema_privilege('public', 'public', 'USAGE') as public_role_can_use_schema;

-- 5. Count rows in fighter_profiles (as service_role - bypasses RLS)
SELECT 
  COUNT(*) as total_rows,
  COUNT(*) FILTER (WHERE user_id IS NOT NULL) as rows_with_user_id,
  COUNT(*) FILTER (WHERE user_id IS NULL) as rows_without_user_id
FROM public.fighter_profiles;

-- 6. Show sample rows (as service_role)
SELECT 
  id,
  user_id,
  name,
  handle,
  tier,
  points
FROM public.fighter_profiles
LIMIT 5;

