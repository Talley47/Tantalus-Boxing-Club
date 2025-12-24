-- ============================================================================
-- FIX: Multiple Permissive Policies on news_announcements table
-- ============================================================================
-- Issue: Table has multiple permissive policies for role 'anon' for action SELECT:
--        - "Public can view news"
--        - "Public can view news announcements"
--        - "Public read published news"
-- 
-- Solution: Consolidate into a single policy to improve performance.
--           Multiple permissive policies are suboptimal because each must be
--           executed for every query.
-- ============================================================================

-- Step 1: Find all policies for anon role on news_announcements for SELECT
SELECT 
  'POLICIES_TO_CONSOLIDATE' as check_type,
  policyname,
  cmd as command_type,
  roles,
  qual as using_clause,
  with_check as with_check_clause
FROM pg_policies
WHERE schemaname = 'public' 
  AND tablename = 'news_announcements'
  AND cmd = 'SELECT'
  AND ('anon' = ANY(roles) OR roles IS NULL)
ORDER BY policyname;

-- Step 2: Drop all anon SELECT policies (we'll recreate a single one)
DROP POLICY IF EXISTS "Public can view news" ON public.news_announcements;
DROP POLICY IF EXISTS "Public can view news announcements" ON public.news_announcements;
DROP POLICY IF EXISTS "Public read published news" ON public.news_announcements;
DROP POLICY IF EXISTS "Anyone can view news and announcements" ON public.news_announcements;

-- Step 3: Create a single consolidated policy for anon role
-- This policy allows anonymous users to view only published news
-- (most restrictive and appropriate for public access)
CREATE POLICY "Public read published news" ON public.news_announcements
  FOR SELECT
  TO anon
  USING (is_published = TRUE);

-- Step 4: Ensure authenticated users have their own separate policy
-- (This avoids multiple permissive policies for authenticated role)
-- Check if authenticated policy exists, if not create it
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' 
      AND tablename = 'news_announcements'
      AND cmd = 'SELECT'
      AND 'authenticated' = ANY(roles)
  ) THEN
    -- Create policy that allows authenticated users to read published news
    -- Admins can read all news (handled by admin policy if it exists)
    CREATE POLICY "Authenticated can read published news" ON public.news_announcements
      FOR SELECT
      TO authenticated
      USING (is_published = TRUE);
    
    RAISE NOTICE '✅ Created separate policy for authenticated users';
  ELSE
    RAISE NOTICE 'ℹ️  Authenticated users already have a SELECT policy';
  END IF;
END $$;

-- Step 5: Verify the consolidated policy
SELECT 
  'CONSOLIDATED_POLICIES' as check_type,
  policyname,
  cmd as command_type,
  roles,
  qual as using_clause,
  CASE 
    WHEN COUNT(*) OVER (PARTITION BY tablename, cmd, roles) = 1 THEN '✅ Single policy'
    ELSE '❌ Multiple policies'
  END as consolidation_status
FROM pg_policies
WHERE schemaname = 'public' 
  AND tablename = 'news_announcements'
  AND cmd = 'SELECT'
  AND ('anon' = ANY(roles) OR roles IS NULL)
ORDER BY policyname;

-- Step 6: Final verification
DO $$
DECLARE
  anon_select_policy_count INTEGER;
  consolidated_policy_exists BOOLEAN;
  authenticated_policy_exists BOOLEAN;
BEGIN
  -- Count anon SELECT policies
  SELECT COUNT(*) INTO anon_select_policy_count
  FROM pg_policies
  WHERE schemaname = 'public' 
    AND tablename = 'news_announcements'
    AND cmd = 'SELECT'
    AND ('anon' = ANY(roles) OR roles IS NULL);
  
  -- Check if the consolidated policy exists
  SELECT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' 
      AND tablename = 'news_announcements'
      AND policyname = 'Public read published news'
      AND cmd = 'SELECT'
      AND 'anon' = ANY(roles)
  ) INTO consolidated_policy_exists;
  
  -- Check if authenticated policy exists
  SELECT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' 
      AND tablename = 'news_announcements'
      AND cmd = 'SELECT'
      AND 'authenticated' = ANY(roles)
  ) INTO authenticated_policy_exists;
  
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '                    VERIFICATION RESULTS';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '';
  RAISE NOTICE 'Anon SELECT Policies Count: %', anon_select_policy_count;
  RAISE NOTICE 'Consolidated Policy Exists: %', CASE WHEN consolidated_policy_exists THEN '✅ YES' ELSE '❌ NO' END;
  RAISE NOTICE 'Authenticated Policy Exists: %', CASE WHEN authenticated_policy_exists THEN '✅ YES' ELSE '❌ NO' END;
  RAISE NOTICE '';
  
  IF consolidated_policy_exists AND anon_select_policy_count = 1 THEN
    RAISE NOTICE '✅ ✅ ✅ POLICIES CONSOLIDATED! ✅ ✅ ✅';
    RAISE NOTICE '';
    RAISE NOTICE 'Multiple permissive policies for anon role have been consolidated.';
    RAISE NOTICE 'Performance warning should be resolved.';
    IF authenticated_policy_exists THEN
      RAISE NOTICE '✅ Authenticated users have separate policy (no conflicts).';
    END IF;
  ELSIF anon_select_policy_count > 1 THEN
    RAISE WARNING '⚠️  Still have % anon SELECT policies - consolidation incomplete!', anon_select_policy_count;
    RAISE WARNING '   Review the CONSOLIDATED_POLICIES output above.';
  ELSE
    RAISE WARNING '❌ FAILED: Consolidated policy was not created correctly!';
    RAISE WARNING '   Please check for errors above.';
  END IF;
  
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
END $$;

-- ============================================================================
-- FIX COMPLETE
-- ============================================================================
-- Multiple permissive policies for anon role on news_announcements have been
-- consolidated into a single policy: "Public read published news"
-- 
-- Performance improvement:
-- - Before: Multiple policies executed for each query → slower
-- - After: Single policy executed → faster
-- 
-- Note: The consolidated policy allows anonymous users to view only published
--       news (is_published = TRUE), which is the most restrictive and
--       appropriate for public access.
-- 
--       Authenticated users have a separate policy to avoid conflicts.
--       This ensures both anon and authenticated roles can view news
--       without multiple permissive policies for the same role.
-- 
-- Next steps:
-- 1. Re-run your security scanner
-- 2. Performance warning should be resolved ✅
-- ============================================================================

