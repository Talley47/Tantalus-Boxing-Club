-- ============================================================================
-- FIX: RLS Performance Issue on callout_requests table
-- ============================================================================
-- Issue: RLS policy "Fighters can view own callouts" uses
--        auth.uid() directly, causing it to be re-evaluated for each row.
-- 
-- Solution: Wrap auth.uid() calls in (select auth.uid()) so they're
--           evaluated once per query instead of once per row.
-- ============================================================================

-- Step 1: Find all policies on callout_requests table that need optimization
SELECT 
  'POLICIES_TO_FIX' as check_type,
  policyname,
  cmd as command_type,
  qual as using_clause,
  with_check as with_check_clause
FROM pg_policies
WHERE schemaname = 'public' 
  AND tablename = 'callout_requests'
ORDER BY policyname;

-- Step 2: Drop existing policies that need optimization
DROP POLICY IF EXISTS "Fighters can view own callouts" ON public.callout_requests;
DROP POLICY IF EXISTS "Fighters can create callouts" ON public.callout_requests;
DROP POLICY IF EXISTS "Targets can update callouts" ON public.callout_requests;
DROP POLICY IF EXISTS "Admins can manage all callouts" ON public.callout_requests;

-- Step 3: Recreate policies with optimized auth.uid() calls
-- Using (select auth.uid()) instead of auth.uid() for better performance

-- Fighters can view own callouts (OPTIMIZED)
CREATE POLICY "Fighters can view own callouts" ON public.callout_requests
  FOR SELECT
  TO authenticated
  USING (
    caller_id IN (SELECT id FROM fighter_profiles WHERE user_id = (select auth.uid())) OR
    target_id IN (SELECT id FROM fighter_profiles WHERE user_id = (select auth.uid()))
  );

-- Fighters can create callouts (OPTIMIZED)
CREATE POLICY "Fighters can create callouts" ON public.callout_requests
  FOR INSERT
  TO authenticated
  WITH CHECK (
    caller_id IN (SELECT id FROM fighter_profiles WHERE user_id = (select auth.uid()))
  );

-- Targets can update callouts (OPTIMIZED)
CREATE POLICY "Targets can update callouts" ON public.callout_requests
  FOR UPDATE
  TO authenticated
  USING (
    target_id IN (SELECT id FROM fighter_profiles WHERE user_id = (select auth.uid()))
  )
  WITH CHECK (
    target_id IN (SELECT id FROM fighter_profiles WHERE user_id = (select auth.uid()))
  );

-- Admins can manage all callouts (OPTIMIZED)
CREATE POLICY "Admins can manage all callouts" ON public.callout_requests
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = (select auth.uid()) AND role = 'admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = (select auth.uid()) AND role = 'admin'
    )
  );

-- Step 4: Verify the optimized policies
SELECT 
  'OPTIMIZED_POLICIES' as check_type,
  policyname,
  cmd as command_type,
  qual as using_clause,
  with_check as with_check_clause,
  CASE 
    WHEN (qual LIKE '%(select auth.uid())%' OR qual IS NULL)
         AND (with_check LIKE '%(select auth.uid())%' OR with_check IS NULL) THEN '✅ Optimized'
    WHEN qual LIKE '%auth.uid()%' OR with_check LIKE '%auth.uid()%' THEN '❌ Needs optimization'
    WHEN qual LIKE '%current_setting(%' OR with_check LIKE '%current_setting(%' THEN '❌ Needs optimization'
    ELSE '✅ No auth functions'
  END as optimization_status
FROM pg_policies
WHERE schemaname = 'public' 
  AND tablename = 'callout_requests'
ORDER BY policyname;

-- Step 5: Final verification
DO $$
DECLARE
  unoptimized_count INTEGER;
  optimized_policy_exists BOOLEAN;
BEGIN
  -- Count unoptimized policies
  SELECT COUNT(*) INTO unoptimized_count
  FROM pg_policies
  WHERE schemaname = 'public' 
    AND tablename = 'callout_requests'
    AND (
      (qual LIKE '%auth.uid()%' AND qual NOT LIKE '%(select auth.uid())%')
      OR (with_check LIKE '%auth.uid()%' AND with_check NOT LIKE '%(select auth.uid())%')
      OR (qual LIKE '%current_setting(%' AND qual NOT LIKE '%(select current_setting(%')
      OR (with_check LIKE '%current_setting(%' AND with_check NOT LIKE '%(select current_setting(%')
    );
  
  -- Check if the optimized view policy exists
  SELECT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' 
      AND tablename = 'callout_requests'
      AND policyname = 'Fighters can view own callouts'
      AND qual LIKE '%(select auth.uid())%'
  ) INTO optimized_policy_exists;
  
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  
  IF optimized_policy_exists AND unoptimized_count = 0 THEN
    RAISE NOTICE '✅ SUCCESS: RLS policies on callout_requests table are optimized!';
    RAISE NOTICE '   "Fighters can view own callouts" now uses (select auth.uid())';
    RAISE NOTICE '   Performance warning should be resolved.';
  ELSIF optimized_policy_exists THEN
    RAISE WARNING '⚠️  View policy optimized, but % other policy/policies may need optimization', unoptimized_count;
    RAISE NOTICE '   Review the OPTIMIZED_POLICIES output above.';
  ELSE
    RAISE WARNING '❌ FAILED: Optimized policy was not created correctly!';
    RAISE WARNING '   Please check for errors above.';
  END IF;
  
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
END $$;

-- ============================================================================
-- FIX COMPLETE
-- ============================================================================
-- The "Fighters can view own callouts" policy has been optimized.
-- auth.uid() calls are now wrapped in (select auth.uid()) for better performance.
-- 
-- Performance improvement:
-- - Before: auth.uid() called for each row → slow at scale
-- - After: (select auth.uid()) called once per query → much faster
-- 
-- Next steps:
-- 1. Re-run your security scanner
-- 2. Performance warning should be resolved ✅
-- ============================================================================

