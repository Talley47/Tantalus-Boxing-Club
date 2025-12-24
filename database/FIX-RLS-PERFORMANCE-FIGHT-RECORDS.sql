-- ============================================================================
-- FIX: RLS Performance Issue on fight_records table
-- ============================================================================
-- Issue: RLS policy "Users can insert their own fight records" uses
--        auth.uid() directly, causing it to be re-evaluated for each row.
-- 
-- Solution: Wrap auth.uid() calls in (select auth.uid()) so they're
--           evaluated once per query instead of once per row.
-- ============================================================================

-- Step 1: Find all policies on fight_records table that need optimization
SELECT 
  'POLICIES_TO_FIX' as check_type,
  policyname,
  cmd as command_type,
  qual as using_clause,
  with_check as with_check_clause
FROM pg_policies
WHERE schemaname = 'public' 
  AND tablename = 'fight_records'
ORDER BY policyname;

-- Step 2: Drop existing policies that need optimization
DROP POLICY IF EXISTS "Users can insert their own fight records" ON public.fight_records;
DROP POLICY IF EXISTS "Users can insert own fight records" ON public.fight_records;
DROP POLICY IF EXISTS "Users can update their own fight records" ON public.fight_records;
DROP POLICY IF EXISTS "Users can update own fight records" ON public.fight_records;
DROP POLICY IF EXISTS "Users can delete their own fight records" ON public.fight_records;
DROP POLICY IF EXISTS "Users can delete own fight records" ON public.fight_records;

-- Step 3: Recreate policies with optimized auth.uid() calls
-- Using (select auth.uid()) instead of auth.uid() for better performance

-- Users can insert their own fight records (OPTIMIZED)
CREATE POLICY "Users can insert their own fight records" ON public.fight_records
  FOR INSERT
  TO authenticated
  WITH CHECK ((select auth.uid()) = (SELECT user_id FROM fighter_profiles WHERE id = fighter_id));

-- Step 4: Check for other policies that might need optimization
-- (View policies typically don't need optimization unless they use auth functions)
DO $$
DECLARE
  policy_record RECORD;
BEGIN
  -- Find policies that might use auth.uid() directly
  FOR policy_record IN
    SELECT policyname, qual, with_check
    FROM pg_policies
    WHERE schemaname = 'public' 
      AND tablename = 'fight_records'
      AND (
        (qual LIKE '%auth.uid()%' AND qual NOT LIKE '%(select auth.uid())%')
        OR (with_check LIKE '%auth.uid()%' AND with_check NOT LIKE '%(select auth.uid())%')
        OR (qual LIKE '%current_setting(%' AND qual NOT LIKE '%(select current_setting(%')
        OR (with_check LIKE '%current_setting(%' AND with_check NOT LIKE '%(select current_setting(%')
      )
  LOOP
    RAISE NOTICE 'Found policy that may need optimization: %', policy_record.policyname;
    RAISE NOTICE '  Using clause: %', policy_record.qual;
    RAISE NOTICE '  With check clause: %', policy_record.with_check;
  END LOOP;
END $$;

-- Step 5: Verify the optimized policies
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
  AND tablename = 'fight_records'
ORDER BY policyname;

-- Step 6: Final verification
DO $$
DECLARE
  unoptimized_count INTEGER;
  optimized_policy_exists BOOLEAN;
BEGIN
  -- Count unoptimized policies
  SELECT COUNT(*) INTO unoptimized_count
  FROM pg_policies
  WHERE schemaname = 'public' 
    AND tablename = 'fight_records'
    AND (
      (qual LIKE '%auth.uid()%' AND qual NOT LIKE '%(select auth.uid())%')
      OR (with_check LIKE '%auth.uid()%' AND with_check NOT LIKE '%(select auth.uid())%')
      OR (qual LIKE '%current_setting(%' AND qual NOT LIKE '%(select current_setting(%')
      OR (with_check LIKE '%current_setting(%' AND with_check NOT LIKE '%(select current_setting(%')
    );
  
  -- Check if the optimized insert policy exists
  SELECT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' 
      AND tablename = 'fight_records'
      AND policyname = 'Users can insert their own fight records'
      AND with_check LIKE '%(select auth.uid())%'
  ) INTO optimized_policy_exists;
  
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  
  IF optimized_policy_exists AND unoptimized_count = 0 THEN
    RAISE NOTICE '✅ SUCCESS: RLS policy on fight_records table is optimized!';
    RAISE NOTICE '   "Users can insert their own fight records" now uses (select auth.uid())';
    RAISE NOTICE '   Performance warning should be resolved.';
  ELSIF optimized_policy_exists THEN
    RAISE WARNING '⚠️  Insert policy optimized, but % other policy/policies may need optimization', unoptimized_count;
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
-- The "Users can insert their own fight records" policy has been optimized.
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

