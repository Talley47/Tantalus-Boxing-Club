-- ============================================================================
-- FIX: RLS Performance Issue on profiles table
-- ============================================================================
-- Issue: RLS policies using auth.uid() or current_setting() directly
--        are re-evaluated for each row, causing performance problems.
-- 
-- Solution: Wrap auth.uid() calls in (select auth.uid()) so they're
--           evaluated once per query instead of once per row.
-- ============================================================================

-- Step 1: Find all policies on profiles table that need optimization
SELECT 
  'POLICIES_TO_FIX' as check_type,
  policyname,
  cmd as command_type,
  qual as using_clause,
  with_check as with_check_clause
FROM pg_policies
WHERE schemaname = 'public' 
  AND tablename = 'profiles'
ORDER BY policyname;

-- Step 2: Drop existing policies that need optimization
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can read their own profile" ON public.profiles;

-- Step 3: Recreate policies with optimized auth.uid() calls
-- Using (select auth.uid()) instead of auth.uid() for better performance

-- Users can view their own profile
CREATE POLICY "Users can view own profile" ON public.profiles
  FOR SELECT
  TO authenticated
  USING (id = (select auth.uid()));

-- Users can update their own profile (OPTIMIZED)
CREATE POLICY "Users can update own profile" ON public.profiles
  FOR UPDATE
  TO authenticated
  USING (id = (select auth.uid()))
  WITH CHECK (id = (select auth.uid()));

-- Users can insert their own profile
CREATE POLICY "Users can insert own profile" ON public.profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (id = (select auth.uid()));

-- Step 4: Check for admin policies that might also need optimization
-- (Drop and recreate if they use auth functions directly)
DO $$
DECLARE
  policy_record RECORD;
  policy_def TEXT;
BEGIN
  -- Find admin policies that might use auth.uid() directly
  FOR policy_record IN
    SELECT policyname, qual, with_check
    FROM pg_policies
    WHERE schemaname = 'public' 
      AND tablename = 'profiles'
      AND (policyname LIKE '%admin%' OR policyname LIKE '%Admin%')
  LOOP
    -- Check if policy uses auth.uid() without subquery
    IF (policy_record.qual LIKE '%auth.uid()%' AND policy_record.qual NOT LIKE '%(select auth.uid())%')
       OR (policy_record.with_check LIKE '%auth.uid()%' AND policy_record.with_check NOT LIKE '%(select auth.uid())%') THEN
      RAISE NOTICE 'Found policy that may need optimization: %', policy_record.policyname;
      -- Note: We don't auto-fix admin policies as they might use different patterns
      -- But we'll log them for review
    END IF;
  END LOOP;
END $$;

-- Step 5: Verify the optimized policies
SELECT 
  'OPTIMIZED_POLICIES' as check_type,
  policyname,
  cmd as command_type,
  qual as using_clause,
  CASE 
    WHEN qual LIKE '%(select auth.uid())%' OR qual IS NULL THEN '✅ Optimized'
    WHEN qual LIKE '%auth.uid()%' THEN '❌ Needs optimization'
    ELSE '✅ No auth.uid()'
  END as optimization_status
FROM pg_policies
WHERE schemaname = 'public' 
  AND tablename = 'profiles'
ORDER BY policyname;

-- Step 6: Final verification
DO $$
DECLARE
  unoptimized_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO unoptimized_count
  FROM pg_policies
  WHERE schemaname = 'public' 
    AND tablename = 'profiles'
    AND (
      (qual LIKE '%auth.uid()%' AND qual NOT LIKE '%(select auth.uid())%')
      OR (with_check LIKE '%auth.uid()%' AND with_check NOT LIKE '%(select auth.uid())%')
      OR (qual LIKE '%current_setting(%' AND qual NOT LIKE '%(select current_setting(%')
      OR (with_check LIKE '%current_setting(%' AND with_check NOT LIKE '%(select current_setting(%')
    );
  
  IF unoptimized_count = 0 THEN
    RAISE NOTICE '';
    RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
    RAISE NOTICE '✅ SUCCESS: All RLS policies on profiles table are optimized!';
    RAISE NOTICE '   Performance warning should be resolved.';
    RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  ELSE
    RAISE WARNING '';
    RAISE WARNING '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
    RAISE WARNING '⚠️  Found % policy/policies that still need optimization', unoptimized_count;
    RAISE WARNING '   Review the OPTIMIZED_POLICIES output above.';
    RAISE WARNING '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  END IF;
END $$;

-- ============================================================================
-- FIX COMPLETE
-- ============================================================================
-- The "Users can update own profile" policy has been optimized.
-- auth.uid() calls are now wrapped in (select auth.uid()) for better performance.
-- 
-- Next steps:
-- 1. Re-run your security scanner
-- 2. Performance warning should be resolved ✅
-- ============================================================================

