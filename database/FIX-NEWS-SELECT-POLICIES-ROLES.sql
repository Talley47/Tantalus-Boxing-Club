-- ============================================================================
-- FIX: news_announcements SELECT Policies - Fix Role Assignments
-- ============================================================================
-- This fixes policies that are incorrectly assigned to authenticated role
-- "Public read published news" should ONLY be for anon role
-- Copy ALL of this into Supabase SQL Editor and run it
-- ============================================================================

-- Step 1: Check current SELECT policies and their roles
SELECT 
  'Current SELECT Policies' as status,
  policyname,
  cmd as command,
  roles,
  qual as using_clause
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'news_announcements'
  AND cmd = 'SELECT'
ORDER BY policyname;

-- Step 2: Drop ALL SELECT policies (we'll recreate them with correct roles)
DROP POLICY IF EXISTS "Admin read all news" ON public.news_announcements;
DROP POLICY IF EXISTS "Authenticated read all news" ON public.news_announcements;
DROP POLICY IF EXISTS "Authenticated users can view news" ON public.news_announcements;
DROP POLICY IF EXISTS "Authenticated and admins can read news" ON public.news_announcements;
DROP POLICY IF EXISTS "Public read published news" ON public.news_announcements;

-- Step 3: Create SELECT policy for authenticated role ONLY
CREATE POLICY "Authenticated read all news" 
ON public.news_announcements 
FOR SELECT 
TO authenticated 
USING (true);

-- Step 4: Create SELECT policy for anon role ONLY
CREATE POLICY "Public read published news" 
ON public.news_announcements 
FOR SELECT 
TO anon 
USING (is_published = TRUE);

-- Step 5: Verify the fix - check role assignments
SELECT 
  'After Fix - Role Verification' as status,
  policyname,
  cmd as command,
  roles,
  CASE 
    WHEN 'authenticated' = ANY(roles) AND 'anon' = ANY(roles) THEN '❌ ERROR - Policy has both roles'
    WHEN 'authenticated' = ANY(roles) AND policyname LIKE '%Public%' THEN '❌ ERROR - Public policy has authenticated role'
    WHEN 'anon' = ANY(roles) AND policyname LIKE '%Authenticated%' THEN '❌ ERROR - Authenticated policy has anon role'
    WHEN COUNT(*) OVER (PARTITION BY cmd, roles) = 1 THEN '✅ Correct role assignment'
    ELSE '⚠️ Check manually'
  END as role_status
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'news_announcements'
  AND cmd = 'SELECT'
ORDER BY roles, policyname;

-- Step 6: Check for duplicates by role
SELECT 
  'Duplicate Check by Role' as status,
  cmd as command,
  roles,
  COUNT(*) as policy_count,
  array_agg(policyname ORDER BY policyname) as policy_names,
  CASE 
    WHEN COUNT(*) > 1 THEN '❌ HAS DUPLICATES'
    ELSE '✅ No duplicates'
  END as duplicate_status
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'news_announcements'
  AND cmd = 'SELECT'
GROUP BY cmd, roles
ORDER BY cmd, roles;

-- Step 7: Summary
SELECT 
  'Summary' as status,
  COUNT(*) FILTER (WHERE cmd = 'SELECT' AND 'authenticated' = ANY(roles)) as authenticated_select_count,
  COUNT(*) FILTER (WHERE cmd = 'SELECT' AND 'anon' = ANY(roles)) as anon_select_count,
  CASE 
    WHEN COUNT(*) FILTER (WHERE cmd = 'SELECT' AND 'authenticated' = ANY(roles)) = 1 
      AND COUNT(*) FILTER (WHERE cmd = 'SELECT' AND 'anon' = ANY(roles)) = 1
    THEN '✅ FIXED - One policy per role'
    ELSE '❌ Still has issues - check output above'
  END as result
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'news_announcements';

