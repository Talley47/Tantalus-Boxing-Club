-- ============================================================================
-- FIX: news_announcements Duplicate SELECT Policies
-- ============================================================================
-- Consolidates duplicate SELECT policies:
-- - "Admin read all news"
-- - "Authenticated read all news"
-- - "Authenticated users can view news"
-- - "Public read published news" (if it's for authenticated role)
-- Into a single consolidated policy
-- Copy ALL of this into Supabase SQL Editor and run it
-- ============================================================================

-- Step 1: Check current SELECT policies
SELECT 
  'Current SELECT Policies' as status,
  policyname,
  cmd as command,
  roles,
  qual as using_clause,
  with_check as with_check_clause
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'news_announcements'
  AND cmd = 'SELECT'
ORDER BY roles, policyname;

-- Step 2: Drop duplicate SELECT policies for authenticated role
-- Note: "Public read published news" might be incorrectly assigned to authenticated role
-- We'll drop it and recreate it for anon role only
DROP POLICY IF EXISTS "Admin read all news" ON public.news_announcements;
DROP POLICY IF EXISTS "Authenticated read all news" ON public.news_announcements;
DROP POLICY IF EXISTS "Authenticated users can view news" ON public.news_announcements;
DROP POLICY IF EXISTS "Authenticated and admins can read news" ON public.news_announcements;
DROP POLICY IF EXISTS "Public read published news" ON public.news_announcements;

-- Step 3: Create a single consolidated SELECT policy for authenticated role
-- This policy allows authenticated users to view all news (covers both regular users and admins)
DO $$
BEGIN
  CREATE POLICY "Authenticated read all news" 
  ON public.news_announcements 
  FOR SELECT 
  TO authenticated 
  USING (true);
  
  RAISE NOTICE '✅ Created consolidated SELECT policy for authenticated role';
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING '⚠️ Error creating policy: %', SQLERRM;
END $$;

-- Step 4: Ensure anon role has its own separate policy
-- IMPORTANT: "Public read published news" should ONLY be for anon role, not authenticated
-- This is separate from authenticated policies, so no duplicate issue
DO $$
BEGIN
  -- Always recreate the anon policy to ensure it's correct
  CREATE POLICY "Public read published news" 
  ON public.news_announcements 
  FOR SELECT 
  TO anon 
  USING (is_published = TRUE);
  
  RAISE NOTICE '✅ Created anon policy for published news';
EXCEPTION WHEN OTHERS THEN
  -- If it already exists, that's fine - the DROP above should have removed it
  RAISE NOTICE '⚠️ Could not create anon policy (may already exist): %', SQLERRM;
END $$;

-- Step 5: Verify the fix
SELECT 
  'After Fix' as status,
  policyname,
  cmd as command,
  roles,
  qual as using_clause,
  CASE 
    WHEN COUNT(*) OVER (PARTITION BY cmd, roles) = 1 THEN '✅ No duplicates'
    ELSE '❌ Still has duplicates'
  END as duplicate_status
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'news_announcements'
  AND cmd = 'SELECT'
ORDER BY roles, policyname;

-- Step 6: Check for other duplicate policies
SELECT 
  'Other Duplicates Check' as status,
  cmd as command,
  roles,
  COUNT(*) as policy_count,
  array_agg(policyname ORDER BY policyname) as policy_names
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'news_announcements'
GROUP BY cmd, roles
HAVING COUNT(*) > 1
ORDER BY cmd, roles;

-- Step 7: Summary
SELECT 
  'Summary' as status,
  COUNT(*) FILTER (WHERE cmd = 'SELECT' AND ('authenticated' = ANY(roles) OR roles IS NULL)) as authenticated_select_count,
  COUNT(*) FILTER (WHERE cmd = 'SELECT' AND ('anon' = ANY(roles) OR roles IS NULL)) as anon_select_count,
  CASE 
    WHEN COUNT(*) FILTER (WHERE cmd = 'SELECT' AND ('authenticated' = ANY(roles) OR roles IS NULL)) <= 1 
    THEN '✅ NO DUPLICATES FOR AUTHENTICATED - Fix successful'
    ELSE '❌ Still has duplicates for authenticated - check output above'
  END as result
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'news_announcements';

