-- ============================================================================
-- 🔍 VERIFY ALL RLS POLICIES
-- ============================================================================
-- This script checks RLS policies for all critical tables
-- Run this in Supabase Dashboard → SQL Editor to see what's missing
-- ============================================================================

-- Critical tables that need RLS policies
WITH critical_tables AS (
  SELECT unnest(ARRAY[
    'fighter_profiles',
    'news_announcements',
    'news_reactions',
    'fighter_direct_messages',
    'scheduled_fights',
    'callout_requests',
    'training_camp_invitations',
    'notifications',
    'fight_records',
    'championship_belts',
    'profiles',
    'chat_messages'
  ]) AS tablename
),
required_operations AS (
  SELECT unnest(ARRAY['SELECT', 'INSERT', 'UPDATE', 'DELETE']) AS operation
)

-- Check 1: RLS Status for all tables
SELECT 
  'RLS Status' as check_type,
  t.tablename,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM pg_tables pt 
      WHERE pt.schemaname = 'public' 
      AND pt.tablename = t.tablename
      AND pt.rowsecurity = true
    ) THEN '✅ Enabled'
    ELSE '❌ Disabled'
  END as rls_status,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM information_schema.tables 
      WHERE table_schema = 'public' 
      AND table_name = t.tablename
    ) THEN '✅ Exists'
    ELSE '❌ Missing'
  END as table_exists
FROM critical_tables t
ORDER BY t.tablename;

-- Check 2: Policies by table and operation
SELECT 
  'Policy Coverage' as check_type,
  t.tablename,
  o.operation,
  CASE 
    WHEN COUNT(p.policyname) > 0 THEN '✅ Has Policy'
    ELSE '❌ Missing Policy'
  END as status,
  COUNT(p.policyname) as policy_count,
  STRING_AGG(p.policyname, ', ') FILTER (WHERE p.policyname IS NOT NULL) as policy_names,
  STRING_AGG(DISTINCT p.roles::text, ', ') FILTER (WHERE p.roles IS NOT NULL) as roles_covered
FROM critical_tables t
CROSS JOIN required_operations o
LEFT JOIN pg_policies p ON 
  p.schemaname = 'public' 
  AND p.tablename = t.tablename
  AND p.cmd = o.operation
WHERE EXISTS (
  SELECT 1 FROM information_schema.tables 
  WHERE table_schema = 'public' 
  AND table_name = t.tablename
)
GROUP BY t.tablename, o.operation
ORDER BY t.tablename, o.operation;

-- Check 3: Missing critical policies
SELECT 
  'Missing Policies' as check_type,
  t.tablename,
  o.operation,
  CASE o.operation
    WHEN 'SELECT' THEN 'Users cannot read data'
    WHEN 'INSERT' THEN 'Users cannot create data'
    WHEN 'UPDATE' THEN 'Users cannot update data'
    WHEN 'DELETE' THEN 'Users cannot delete data'
  END as impact
FROM critical_tables t
CROSS JOIN required_operations o
WHERE EXISTS (
  SELECT 1 FROM information_schema.tables 
  WHERE table_schema = 'public' 
  AND table_name = t.tablename
)
AND NOT EXISTS (
  SELECT 1 FROM pg_policies p
  WHERE p.schemaname = 'public'
  AND p.tablename = t.tablename
  AND p.cmd = o.operation
)
-- Filter out operations that may not be needed for all tables
AND (
  (o.operation = 'SELECT') OR
  (o.operation = 'INSERT' AND t.tablename IN (
    'fighter_profiles', 'news_announcements', 'news_reactions', 
    'fighter_direct_messages', 'scheduled_fights', 'callout_requests',
    'training_camp_invitations', 'notifications', 'fight_records', 'chat_messages'
  )) OR
  (o.operation = 'UPDATE' AND t.tablename IN (
    'fighter_profiles', 'news_announcements', 'news_reactions',
    'fighter_direct_messages', 'scheduled_fights', 'callout_requests',
    'training_camp_invitations', 'profiles', 'chat_messages'
  )) OR
  (o.operation = 'DELETE' AND t.tablename IN (
    'news_reactions', 'fighter_direct_messages', 'chat_messages'
  ))
)
ORDER BY t.tablename, o.operation;

-- Check 4: Role coverage (anon vs authenticated)
SELECT 
  'Role Coverage' as check_type,
  tablename,
  cmd as operation,
  CASE 
    WHEN 'anon' = ANY(roles) THEN '✅'
    ELSE '❌'
  END as anon_covered,
  CASE 
    WHEN 'authenticated' = ANY(roles) THEN '✅'
    ELSE '❌'
  END as authenticated_covered,
  policyname
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN (
    SELECT tablename FROM critical_tables
  )
ORDER BY tablename, cmd, policyname;

-- Check 5: Summary by table
SELECT 
  'Table Summary' as check_type,
  t.tablename,
  COUNT(DISTINCT p.cmd) as operations_covered,
  COUNT(DISTINCT p.policyname) as total_policies,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM pg_tables pt 
      WHERE pt.schemaname = 'public' 
      AND pt.tablename = t.tablename
      AND pt.rowsecurity = true
    ) THEN '✅'
    ELSE '❌'
  END as rls_enabled,
  CASE 
    WHEN COUNT(DISTINCT p.cmd) >= 2 THEN '✅ Good'
    WHEN COUNT(DISTINCT p.cmd) = 1 THEN '⚠️ Limited'
    ELSE '❌ None'
  END as coverage_status
FROM critical_tables t
LEFT JOIN pg_policies p ON 
  p.schemaname = 'public' 
  AND p.tablename = t.tablename
WHERE EXISTS (
  SELECT 1 FROM information_schema.tables 
  WHERE table_schema = 'public' 
  AND table_name = t.tablename
)
GROUP BY t.tablename
ORDER BY t.tablename;

-- ============================================================================
-- NEXT STEPS: If policies are missing, run:
-- database/🔧-COMPREHENSIVE-RLS-FIX-ALL-TABLES.sql
-- ============================================================================
