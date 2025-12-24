-- ============================================================================
-- FIX: RLS Performance Issue on notifications table
-- ============================================================================
-- Issue: RLS policy "Users can view their own notifications" uses
--        auth.uid() directly, causing it to be re-evaluated for each row.
-- 
-- Solution: Wrap auth.uid() calls in (select auth.uid()) so they're
--           evaluated once per query instead of once per row.
-- ============================================================================

-- Step 1: Find all policies on notifications table that need optimization
SELECT 
  'POLICIES_TO_FIX' as check_type,
  policyname,
  cmd as command_type,
  qual as using_clause,
  with_check as with_check_clause
FROM pg_policies
WHERE schemaname = 'public' 
  AND tablename = 'notifications'
ORDER BY policyname;

-- Step 2: Drop existing policies that need optimization
DROP POLICY IF EXISTS "Users can view their own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users can update their own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users can insert their own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users can delete their own notifications" ON public.notifications;

-- Step 3: Recreate policies with optimized auth.uid() calls
-- Using (select auth.uid()) instead of auth.uid() for better performance

-- Users can view their own notifications (OPTIMIZED)
CREATE POLICY "Users can view their own notifications" ON public.notifications
  FOR SELECT
  TO authenticated
  USING ((select auth.uid()) = user_id);

-- Users can update their own notifications (OPTIMIZED)
CREATE POLICY "Users can update their own notifications" ON public.notifications
  FOR UPDATE
  TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

-- Users can delete their own notifications (OPTIMIZED)
CREATE POLICY "Users can delete their own notifications" ON public.notifications
  FOR DELETE
  TO authenticated
  USING ((select auth.uid()) = user_id);

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
  AND tablename = 'notifications'
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
    AND tablename = 'notifications'
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
      AND tablename = 'notifications'
      AND policyname = 'Users can view their own notifications'
      AND qual LIKE '%(select auth.uid())%'
  ) INTO optimized_policy_exists;
  
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  
  IF optimized_policy_exists AND unoptimized_count = 0 THEN
    RAISE NOTICE '✅ SUCCESS: RLS policies on notifications table are optimized!';
    RAISE NOTICE '   "Users can view their own notifications" now uses (select auth.uid())';
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
-- The "Users can view their own notifications" policy has been optimized.
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

