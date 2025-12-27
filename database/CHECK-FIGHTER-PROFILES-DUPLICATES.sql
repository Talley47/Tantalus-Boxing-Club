-- ============================================================================
-- DIAGNOSTIC: Check for duplicate SELECT policies on fighter_profiles
-- ============================================================================
-- Run this FIRST to see what policies currently exist
-- ============================================================================

-- Show all SELECT policies for fighter_profiles
SELECT 
  'Current Policies' as check_type,
  policyname,
  roles,
  cmd as command,
  qual as using_clause,
  with_check as with_check_clause
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'fighter_profiles'
  AND cmd = 'SELECT'
ORDER BY policyname;

-- Check for duplicate anon policies specifically
SELECT 
  'Duplicate Check' as check_type,
  COUNT(*) as anon_policy_count,
  array_agg(policyname ORDER BY policyname) as policy_names,
  CASE 
    WHEN COUNT(*) = 0 THEN '❌ ERROR: No anon policy exists!'
    WHEN COUNT(*) = 1 THEN '✅ Perfect: Exactly one anon policy'
    WHEN COUNT(*) > 1 THEN '❌ DUPLICATES: Multiple anon policies exist - need to consolidate'
  END as status
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'fighter_profiles'
  AND cmd = 'SELECT'
  AND ('anon' = ANY(roles) OR roles IS NULL OR roles = '{}');

-- Show which policies are assigned to anon role
SELECT 
  'Anon Role Policies' as check_type,
  policyname,
  roles,
  CASE 
    WHEN 'anon' = ANY(roles) THEN '✅ Assigned to anon'
    WHEN roles IS NULL THEN '⚠️ NULL roles (may apply to anon)'
    WHEN roles = '{}' THEN '⚠️ Empty roles array'
    ELSE '❌ Not assigned to anon'
  END as anon_assignment
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'fighter_profiles'
  AND cmd = 'SELECT'
ORDER BY policyname;

