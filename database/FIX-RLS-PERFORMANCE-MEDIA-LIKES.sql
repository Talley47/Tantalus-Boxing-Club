-- ============================================================================
-- FIX: RLS Performance Issue on media_likes table
-- ============================================================================
-- Issue: RLS policy "Users can insert their own media likes" uses
--        auth.uid() directly, causing it to be re-evaluated for each row.
-- 
-- Solution: Wrap auth.uid() calls in (select auth.uid()) so they're
--           evaluated once per query instead of once per row.
-- ============================================================================

-- Step 1: Find all policies on media_likes table that need optimization
SELECT 
  'POLICIES_TO_FIX' as check_type,
  policyname,
  cmd as command_type,
  qual as using_clause,
  with_check as with_check_clause
FROM pg_policies
WHERE schemaname = 'public' 
  AND tablename = 'media_likes'
ORDER BY policyname;

-- Step 2: Drop existing policies that need optimization
DROP POLICY IF EXISTS "Users can insert their own media likes" ON public.media_likes;
DROP POLICY IF EXISTS "Users can delete their own media likes" ON public.media_likes;

-- Note: "Users can view all media likes" policy uses (true) and doesn't need optimization

-- Step 3: Recreate policies with optimized auth.uid() calls
-- Using (select auth.uid()) instead of auth.uid() for better performance

-- Users can insert their own media likes (OPTIMIZED)
CREATE POLICY "Users can insert their own media likes" ON public.media_likes
  FOR INSERT
  TO authenticated
  WITH CHECK ((select auth.uid()) = media_likes.user_id);

-- Users can delete their own media likes (OPTIMIZED)
CREATE POLICY "Users can delete their own media likes" ON public.media_likes
  FOR DELETE
  TO authenticated
  USING ((select auth.uid()) = media_likes.user_id);

-- Step 4: Verify the optimized policies
SELECT 
  'OPTIMIZED_POLICIES' as check_type,
  policyname,
  cmd as command_type,
  qual as using_clause,
  with_check as with_check_clause,
  CASE 
    WHEN (qual LIKE '%(select auth.uid())%' OR qual IS NULL OR qual LIKE '%true%')
         AND (with_check LIKE '%(select auth.uid())%' OR with_check IS NULL) THEN '✅ Optimized'
    WHEN qual LIKE '%auth.uid()%' OR with_check LIKE '%auth.uid()%' THEN '❌ Needs optimization'
    WHEN qual LIKE '%current_setting(%' OR with_check LIKE '%current_setting(%' THEN '❌ Needs optimization'
    ELSE '✅ No auth functions'
  END as optimization_status
FROM pg_policies
WHERE schemaname = 'public' 
  AND tablename = 'media_likes'
ORDER BY policyname;

-- Step 5: Final verification
DO $$
DECLARE
  unoptimized_count INTEGER;
  optimized_insert_policy_exists BOOLEAN;
  optimized_delete_policy_exists BOOLEAN;
BEGIN
  -- Count unoptimized policies
  SELECT COUNT(*) INTO unoptimized_count
  FROM pg_policies
  WHERE schemaname = 'public' 
    AND tablename = 'media_likes'
    AND (
      (qual LIKE '%auth.uid()%' AND qual NOT LIKE '%(select auth.uid())%' AND qual NOT LIKE '%true%')
      OR (with_check LIKE '%auth.uid()%' AND with_check NOT LIKE '%(select auth.uid())%')
      OR (qual LIKE '%current_setting(%' AND qual NOT LIKE '%(select current_setting(%')
      OR (with_check LIKE '%current_setting(%' AND with_check NOT LIKE '%(select current_setting(%')
    );
  
  -- Check if the optimized insert policy exists
  SELECT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' 
      AND tablename = 'media_likes'
      AND policyname = 'Users can insert their own media likes'
      AND with_check LIKE '%(select auth.uid())%'
  ) INTO optimized_insert_policy_exists;
  
  -- Check if the optimized delete policy exists
  SELECT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' 
      AND tablename = 'media_likes'
      AND policyname = 'Users can delete their own media likes'
      AND qual LIKE '%(select auth.uid())%'
  ) INTO optimized_delete_policy_exists;
  
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '                    VERIFICATION RESULTS';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '';
  RAISE NOTICE 'Insert Policy Optimized: %', CASE WHEN optimized_insert_policy_exists THEN '✅ YES' ELSE '❌ NO' END;
  RAISE NOTICE 'Delete Policy Optimized: %', CASE WHEN optimized_delete_policy_exists THEN '✅ YES' ELSE '❌ NO' END;
  RAISE NOTICE 'Unoptimized Policies Remaining: %', unoptimized_count;
  RAISE NOTICE '';
  RAISE NOTICE 'Note: "Users can view all media likes" uses (true) and is already optimized.';
  RAISE NOTICE '';
  
  IF optimized_insert_policy_exists 
     AND optimized_delete_policy_exists 
     AND unoptimized_count = 0 THEN
    RAISE NOTICE '✅ ✅ ✅ ALL POLICIES OPTIMIZED! ✅ ✅ ✅';
    RAISE NOTICE '';
    RAISE NOTICE 'All RLS policies on media_likes table are now optimized!';
    RAISE NOTICE 'Performance warning should be resolved.';
  ELSIF optimized_insert_policy_exists THEN
    RAISE WARNING '⚠️  Insert policy optimized, but delete policy may need optimization';
    RAISE NOTICE '   Review the OPTIMIZED_POLICIES output above.';
  ELSE
    RAISE WARNING '❌ FAILED: Optimized policies were not created correctly!';
    RAISE WARNING '   Please check for errors above.';
  END IF;
  
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
END $$;

-- ============================================================================
-- FIX COMPLETE
-- ============================================================================
-- The "Users can insert their own media likes" policy (and delete policy)
-- have been optimized. auth.uid() calls are now wrapped in (select auth.uid())
-- for better performance.
-- 
-- Performance improvement:
-- - Before: auth.uid() called for each row → slow at scale
-- - After: (select auth.uid()) called once per query → much faster
-- 
-- Next steps:
-- 1. Re-run your security scanner
-- 2. Performance warning should be resolved ✅
-- ============================================================================

