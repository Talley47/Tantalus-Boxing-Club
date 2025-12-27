-- ============================================================================
-- FIX: fighter_profiles RLS Performance - Simple Version
-- ============================================================================
-- Fixes the "Read own fighter profile" policy that re-evaluates auth.uid()
-- Copy ALL of this into Supabase SQL Editor and run it
-- ============================================================================

-- Step 1: Check current "Read own fighter profile" policy
SELECT 
  'Current Policy' as status,
  policyname,
  cmd as command,
  roles,
  qual as using_clause,
  CASE 
    WHEN qual LIKE '%auth.uid()%' AND qual NOT LIKE '%(select auth.uid())%' THEN '❌ Needs optimization'
    ELSE '✅ Already optimized'
  END as status
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'fighter_profiles'
  AND policyname LIKE '%own%fighter%profile%'
  OR policyname LIKE '%Read own%';

-- Step 2: Drop and recreate the policy with optimized auth.uid() call
DO $$
BEGIN
  -- Drop the policy if it exists (handle different possible names)
  DROP POLICY IF EXISTS "Users can view own fighter profile" ON public.fighter_profiles;
  DROP POLICY IF EXISTS "Read own fighter profile" ON public.fighter_profiles;
  DROP POLICY IF EXISTS "Users can view their own fighter profile" ON public.fighter_profiles;
  
  -- Recreate with optimized (select auth.uid()) instead of auth.uid()
  -- This evaluates once per query instead of once per row
  CREATE POLICY "Users can view own fighter profile" 
  ON public.fighter_profiles 
  FOR SELECT 
  TO authenticated 
  USING (user_id = (select auth.uid()));
  
  RAISE NOTICE '✅ Created optimized "Users can view own fighter profile" policy';
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING '⚠️ Error creating policy: %', SQLERRM;
END $$;

-- Step 3: Also optimize UPDATE and INSERT policies if they exist
DO $$
BEGIN
  -- Update policy
  DROP POLICY IF EXISTS "Users can update own fighter profile" ON public.fighter_profiles;
  DROP POLICY IF EXISTS "Users can update their own fighter profile" ON public.fighter_profiles;
  
  CREATE POLICY "Users can update own fighter profile" 
  ON public.fighter_profiles 
  FOR UPDATE 
  TO authenticated 
  USING (user_id = (select auth.uid()))
  WITH CHECK (user_id = (select auth.uid()));
  
  RAISE NOTICE '✅ Created optimized UPDATE policy';
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE '⚠️ UPDATE policy not created (may not exist): %', SQLERRM;
END $$;

DO $$
BEGIN
  -- Insert policy
  DROP POLICY IF EXISTS "Users can insert own fighter profile" ON public.fighter_profiles;
  DROP POLICY IF EXISTS "Users can insert their own fighter profile" ON public.fighter_profiles;
  
  CREATE POLICY "Users can insert own fighter profile" 
  ON public.fighter_profiles 
  FOR INSERT 
  TO authenticated 
  WITH CHECK (user_id = (select auth.uid()));
  
  RAISE NOTICE '✅ Created optimized INSERT policy';
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE '⚠️ INSERT policy not created (may not exist): %', SQLERRM;
END $$;

-- Step 4: Verify all policies are optimized
SELECT 
  'Verification' as status,
  policyname,
  cmd as command,
  CASE 
    WHEN qual LIKE '%(select auth.uid())%' OR qual IS NULL OR qual LIKE '%true%' THEN '✅ Optimized'
    WHEN qual LIKE '%auth.uid()%' THEN '❌ Still needs optimization'
    ELSE '✅ OK'
  END as using_status,
  CASE 
    WHEN with_check LIKE '%(select auth.uid())%' OR with_check IS NULL THEN '✅ Optimized'
    WHEN with_check LIKE '%auth.uid()%' THEN '❌ Still needs optimization'
    ELSE '✅ OK'
  END as with_check_status
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'fighter_profiles'
ORDER BY policyname;

-- Step 5: Final summary
SELECT 
  'Performance Fix Complete' as status,
  COUNT(*) FILTER (WHERE qual LIKE '%(select auth.uid())%' OR qual IS NULL OR qual LIKE '%true%') as optimized_count,
  COUNT(*) FILTER (WHERE qual LIKE '%auth.uid()%' AND qual NOT LIKE '%(select auth.uid())%') as unoptimized_count,
  CASE 
    WHEN COUNT(*) FILTER (WHERE qual LIKE '%auth.uid()%' AND qual NOT LIKE '%(select auth.uid())%') = 0 
    THEN '✅ ALL POLICIES OPTIMIZED - Performance warning should be resolved'
    ELSE '⚠️ Some policies may still need manual optimization'
  END as result
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'fighter_profiles';

