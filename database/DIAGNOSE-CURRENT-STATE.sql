-- ============================================================================
-- 🔍 DIAGNOSE CURRENT STATE - Find out why fighters aren't showing
-- ============================================================================
-- 
-- Run this FIRST to see what's wrong
-- Copy ALL of this file and run in Supabase SQL Editor
--
-- ============================================================================

-- Check 1: How many fighters exist in the table?
SELECT 
  'CHECK 1: Total fighters in database' as check_name,
  COUNT(*) as total_fighters,
  COUNT(*) FILTER (WHERE user_id IS NOT NULL) as fighters_with_user_id,
  COUNT(*) FILTER (WHERE user_id IS NULL) as fighters_without_user_id
FROM public.fighter_profiles;

-- Check 2: Is RLS enabled?
SELECT 
  'CHECK 2: RLS Status' as check_name,
  schemaname,
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename IN ('fighter_profiles', 'profiles');

-- Check 3: What SELECT policies exist?
SELECT 
  'CHECK 3: Current SELECT Policies' as check_name,
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
  AND (cmd = 'SELECT' OR cmd = 'ALL')
ORDER BY tablename, policyname;

-- Check 4: What permissions exist?
SELECT 
  'CHECK 4: Table Permissions' as check_name,
  grantee as role_name,
  table_schema,
  table_name,
  privilege_type
FROM information_schema.table_privileges
WHERE table_schema = 'public'
  AND table_name IN ('fighter_profiles', 'profiles')
  AND grantee IN ('anon', 'authenticated', 'public')
ORDER BY table_name, grantee, privilege_type;

-- Check 5: Test query as authenticated user (simulates your app)
-- This should return fighters if RLS is working correctly
SELECT 
  'CHECK 5: Test Query (as authenticated)' as check_name,
  COUNT(*) as visible_fighters,
  CASE 
    WHEN COUNT(*) = 0 THEN '❌ FAIL - No fighters visible (RLS blocking)'
    WHEN COUNT(*) > 0 THEN '✅ SUCCESS - ' || COUNT(*) || ' fighters visible'
    ELSE '⚠️ Unknown'
  END as result
FROM public.fighter_profiles
WHERE user_id IS NOT NULL;

-- Check 6: Test query as anonymous user
SELECT 
  'CHECK 6: Test Query (as anonymous)' as check_name,
  COUNT(*) as visible_fighters,
  CASE 
    WHEN COUNT(*) = 0 THEN '❌ FAIL - No fighters visible (RLS blocking)'
    WHEN COUNT(*) > 0 THEN '✅ SUCCESS - ' || COUNT(*) || ' fighters visible'
    ELSE '⚠️ Unknown'
  END as result
FROM public.fighter_profiles
WHERE user_id IS NOT NULL;

-- Check 7: Test EXACT app query (user_id IS NOT NULL, ORDER BY points DESC, LIMIT 30)
SELECT 
  'CHECK 7: App Query Simulation' as check_name,
  COUNT(*) as visible_fighters,
  CASE 
    WHEN COUNT(*) = 0 THEN '❌ FAIL - App will see 0 fighters!'
    WHEN COUNT(*) > 0 THEN '✅ SUCCESS - App will see ' || COUNT(*) || ' fighters'
    ELSE '⚠️ Unknown'
  END as result
FROM (
  SELECT id, user_id, name, points
  FROM public.fighter_profiles
  WHERE user_id IS NOT NULL
  ORDER BY points DESC
  LIMIT 30
) sub;

-- Check 8: List all policies (including non-SELECT ones that might interfere)
SELECT 
  'CHECK 8: ALL Policies (including INSERT/UPDATE/DELETE)' as check_name,
  tablename,
  policyname,
  cmd as command,
  permissive,
  roles
FROM pg_policies 
WHERE schemaname = 'public' 
  AND tablename IN ('fighter_profiles', 'profiles')
ORDER BY tablename, cmd, policyname;

-- ============================================================================
-- SUMMARY
-- ============================================================================
-- 
-- Look at the results above:
-- 
-- ✅ If CHECK 1 shows fighters but CHECK 5/6/7 show 0 → RLS is blocking
-- ✅ If CHECK 3 shows no policies → Need to create policies
-- ✅ If CHECK 4 shows no permissions → Need to grant permissions
-- ✅ If CHECK 7 shows 0 → Your app will see 0 fighters (run the fix script!)
--
-- NEXT STEP: Run database/🚨-FIX-FIGHTERS-NOW-FINAL.sql
--
-- ============================================================================

