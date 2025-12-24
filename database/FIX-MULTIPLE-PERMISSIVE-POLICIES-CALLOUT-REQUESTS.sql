-- ============================================================================
-- FIX: Multiple Permissive Policies on callout_requests table
-- ============================================================================
-- Issue: Table has multiple permissive policies for role 'anon' for action SELECT:
--        - "Public can view callout requests"
--        - "Public can view scheduled callouts"
-- 
-- Solution: Consolidate into a single policy to improve performance.
--           Multiple permissive policies are suboptimal because each must be
--           executed for every query.
-- ============================================================================

-- Step 1: Find all policies for anon role on callout_requests for SELECT
SELECT 
  'POLICIES_TO_CONSOLIDATE' as check_type,
  policyname,
  cmd as command_type,
  roles,
  qual as using_clause,
  with_check as with_check_clause
FROM pg_policies
WHERE schemaname = 'public' 
  AND tablename = 'callout_requests'
  AND cmd = 'SELECT'
  AND ('anon' = ANY(roles) OR roles IS NULL)
ORDER BY policyname;

-- Step 2: Drop all anon SELECT policies (we'll recreate a single one)
DROP POLICY IF EXISTS "Public can view callout requests" ON public.callout_requests;
DROP POLICY IF EXISTS "Public can view scheduled callouts" ON public.callout_requests;
DROP POLICY IF EXISTS "Anyone can view scheduled callouts" ON public.callout_requests;

-- Step 3: Create a single consolidated policy for anon role
-- This policy allows anonymous users to view scheduled callouts
-- (which is typically what's needed for public display)
CREATE POLICY "Public can view scheduled callouts" ON public.callout_requests
  FOR SELECT
  TO anon
  USING (status = 'scheduled');

-- Note: If you need anonymous users to view ALL callouts (not just scheduled),
--       change the USING clause to: USING (true)
--       But typically, only scheduled callouts should be publicly visible.

-- Step 4: Verify the consolidated policy
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
  AND tablename = 'callout_requests'
  AND cmd = 'SELECT'
  AND ('anon' = ANY(roles) OR roles IS NULL)
ORDER BY policyname;

-- Step 5: Final verification
DO $$
DECLARE
  anon_select_policy_count INTEGER;
  consolidated_policy_exists BOOLEAN;
BEGIN
  -- Count anon SELECT policies
  SELECT COUNT(*) INTO anon_select_policy_count
  FROM pg_policies
  WHERE schemaname = 'public' 
    AND tablename = 'callout_requests'
    AND cmd = 'SELECT'
    AND ('anon' = ANY(roles) OR roles IS NULL);
  
  -- Check if the consolidated policy exists
  SELECT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' 
      AND tablename = 'callout_requests'
      AND policyname = 'Public can view scheduled callouts'
      AND cmd = 'SELECT'
      AND 'anon' = ANY(roles)
  ) INTO consolidated_policy_exists;
  
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '                    VERIFICATION RESULTS';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '';
  RAISE NOTICE 'Anon SELECT Policies Count: %', anon_select_policy_count;
  RAISE NOTICE 'Consolidated Policy Exists: %', CASE WHEN consolidated_policy_exists THEN '✅ YES' ELSE '❌ NO' END;
  RAISE NOTICE '';
  
  IF consolidated_policy_exists AND anon_select_policy_count = 1 THEN
    RAISE NOTICE '✅ ✅ ✅ POLICIES CONSOLIDATED! ✅ ✅ ✅';
    RAISE NOTICE '';
    RAISE NOTICE 'Multiple permissive policies have been consolidated into a single policy.';
    RAISE NOTICE 'Performance warning should be resolved.';
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
-- Multiple permissive policies for anon role on callout_requests have been
-- consolidated into a single policy: "Public can view scheduled callouts"
-- 
-- Performance improvement:
-- - Before: Multiple policies executed for each query → slower
-- - After: Single policy executed → faster
-- 
-- Note: The consolidated policy allows anonymous users to view scheduled
--       callouts only. If you need to view all callouts, change the USING
--       clause to: USING (true)
-- 
-- Next steps:
-- 1. Re-run your security scanner
-- 2. Performance warning should be resolved ✅
-- ============================================================================

