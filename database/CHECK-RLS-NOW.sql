-- ============================================================================
-- CHECK CURRENT RLS STATE
-- ============================================================================
-- Run this FIRST to see what's wrong
-- ============================================================================

-- Check 1: Is RLS enabled?
SELECT 
  'RLS Status' as check_name,
  tablename,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM pg_tables t
      JOIN pg_class c ON t.tablename = c.relname
      WHERE t.schemaname = 'public' 
        AND t.tablename = tablename
        AND c.relrowsecurity = true
    ) THEN 'ENABLED'
    ELSE 'DISABLED'
  END as rls_status
FROM (VALUES ('fighter_profiles'), ('profiles')) AS t(tablename);

-- Check 2: What policies exist?
SELECT 
  'Current Policies' as check_name,
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN ('fighter_profiles', 'profiles')
ORDER BY tablename, policyname;

-- Check 3: Can we see fighters directly (bypassing RLS)?
SELECT 
  'Direct Query (Bypass RLS)' as check_name,
  COUNT(*) as total_fighters,
  COUNT(*) FILTER (WHERE user_id IS NOT NULL) as fighters_with_user_id
FROM public.fighter_profiles;

-- Check 4: Test as anon role (what your app uses)
SET ROLE anon;
SELECT 
  'Test as ANON role' as check_name,
  COUNT(*) as visible_fighters,
  COUNT(*) FILTER (WHERE user_id IS NOT NULL) as fighters_with_user_id_visible
FROM public.fighter_profiles
WHERE user_id IS NOT NULL;
RESET ROLE;

-- Check 5: Test as authenticated role
SET ROLE authenticated;
SELECT 
  'Test as AUTHENTICATED role' as check_name,
  COUNT(*) as visible_fighters,
  COUNT(*) FILTER (WHERE user_id IS NOT NULL) as fighters_with_user_id_visible
FROM public.fighter_profiles
WHERE user_id IS NOT NULL;
RESET ROLE;

