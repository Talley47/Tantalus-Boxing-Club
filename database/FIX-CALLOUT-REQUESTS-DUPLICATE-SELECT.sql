-- ============================================================================
-- FIX: callout_requests Duplicate SELECT Policies
-- ============================================================================
-- Consolidates duplicate SELECT policies: "Admins can view all callouts" 
-- and "Authenticated users can view callouts" into a single policy
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
  AND tablename = 'callout_requests'
  AND cmd = 'SELECT'
ORDER BY policyname;

-- Step 2: Drop duplicate SELECT policies
DROP POLICY IF EXISTS "Admins can view all callouts" ON public.callout_requests;
DROP POLICY IF EXISTS "Authenticated users can view callouts" ON public.callout_requests;
DROP POLICY IF EXISTS "Fighters can view own callouts" ON public.callout_requests;
DROP POLICY IF EXISTS "Users can view own callouts" ON public.callout_requests;

-- Step 3: Create a single consolidated SELECT policy
-- This policy allows fighters to view their own callouts AND admins to view all
DO $$
BEGIN
  -- Check if is_admin_user function exists
  IF EXISTS (
    SELECT 1 FROM pg_proc 
    WHERE proname = 'is_admin_user' 
    AND pronamespace = 'public'::regnamespace
  ) THEN
    -- Use function (simpler and optimized)
    CREATE POLICY "Authenticated users can view callouts" 
    ON public.callout_requests 
    FOR SELECT 
    TO authenticated 
    USING (
      -- Fighters can view callouts where they are caller or target
      caller_id IN (
        SELECT id FROM fighter_profiles 
        WHERE user_id = (select auth.uid())
      )
      OR
      target_id IN (
        SELECT id FROM fighter_profiles 
        WHERE user_id = (select auth.uid())
      )
      OR
      -- Admins can view all callouts
      is_admin_user()
      OR
      -- Public can view scheduled callouts (for matchmaking)
      status = 'scheduled'
    );
    
    RAISE NOTICE '✅ Created consolidated SELECT policy using is_admin_user()';
  ELSE
    -- Fallback: check profiles table with optimized (select auth.uid())
    CREATE POLICY "Authenticated users can view callouts" 
    ON public.callout_requests 
    FOR SELECT 
    TO authenticated 
    USING (
      -- Fighters can view callouts where they are caller or target
      caller_id IN (
        SELECT id FROM fighter_profiles 
        WHERE user_id = (select auth.uid())
      )
      OR
      target_id IN (
        SELECT id FROM fighter_profiles 
        WHERE user_id = (select auth.uid())
      )
      OR
      -- Admins can view all callouts
      EXISTS (
        SELECT 1 FROM profiles 
        WHERE id = (select auth.uid()) 
        AND role = 'admin'
      )
      OR
      -- Public can view scheduled callouts (for matchmaking)
      status = 'scheduled'
    );
    
    RAISE NOTICE '✅ Created consolidated SELECT policy using (select auth.uid())';
  END IF;
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING '⚠️ Error creating policy: %', SQLERRM;
END $$;

-- Step 4: Also ensure anon role has access to scheduled callouts (if needed)
-- This is separate from authenticated policies, so no duplicate issue
DO $$
BEGIN
  -- Check if anon policy exists
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'callout_requests'
      AND cmd = 'SELECT'
      AND ('anon' = ANY(roles) OR roles IS NULL)
  ) THEN
    CREATE POLICY "Public can view scheduled callouts" 
    ON public.callout_requests 
    FOR SELECT 
    TO anon 
    USING (status = 'scheduled');
    
    RAISE NOTICE '✅ Created anon policy for scheduled callouts';
  ELSE
    RAISE NOTICE '✅ Anon policy already exists';
  END IF;
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE '⚠️ Could not create anon policy: %', SQLERRM;
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
  AND tablename = 'callout_requests'
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
  AND tablename = 'callout_requests'
GROUP BY cmd, roles
HAVING COUNT(*) > 1
ORDER BY cmd, roles;

-- Step 7: Summary
SELECT 
  'Summary' as status,
  COUNT(*) FILTER (WHERE cmd = 'SELECT' AND ('authenticated' = ANY(roles) OR roles IS NULL)) as select_policy_count,
  CASE 
    WHEN COUNT(*) FILTER (WHERE cmd = 'SELECT' AND ('authenticated' = ANY(roles) OR roles IS NULL)) <= 1 
    THEN '✅ NO DUPLICATES - Fix successful'
    ELSE '❌ Still has duplicates - check output above'
  END as result
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'callout_requests';

