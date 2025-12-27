-- ============================================================================
-- FIX: callout_requests Duplicate UPDATE Policies
-- ============================================================================
-- Consolidates duplicate UPDATE policies:
-- - "Admins can update all callouts"
-- - "Admins can update callouts"
-- - "Targets can update callouts"
-- Into a single consolidated policy
-- Copy ALL of this into Supabase SQL Editor and run it
-- ============================================================================

-- Step 1: Check current UPDATE policies
SELECT 
  'Current UPDATE Policies' as status,
  policyname,
  cmd as command,
  roles,
  qual as using_clause,
  with_check as with_check_clause
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'callout_requests'
  AND cmd = 'UPDATE'
ORDER BY policyname;

-- Step 2: Drop duplicate UPDATE policies
DROP POLICY IF EXISTS "Admins can update all callouts" ON public.callout_requests;
DROP POLICY IF EXISTS "Admins can update callouts" ON public.callout_requests;
DROP POLICY IF EXISTS "Targets can update callouts" ON public.callout_requests;
DROP POLICY IF EXISTS "Targets can update own callouts" ON public.callout_requests;

-- Step 3: Create a single consolidated UPDATE policy
-- This policy allows targets to update callouts AND admins to update all
DO $$
BEGIN
  -- Check if is_admin_user function exists
  IF EXISTS (
    SELECT 1 FROM pg_proc 
    WHERE proname = 'is_admin_user' 
    AND pronamespace = 'public'::regnamespace
  ) THEN
    -- Use function (simpler and optimized)
    CREATE POLICY "Targets and admins can update callouts" 
    ON public.callout_requests 
    FOR UPDATE 
    TO authenticated 
    USING (
      -- Targets can update callouts where they are the target
      target_id IN (
        SELECT id FROM fighter_profiles 
        WHERE user_id = (select auth.uid())
      )
      OR
      -- Admins can update all callouts
      is_admin_user()
    )
    WITH CHECK (
      -- Same conditions for WITH CHECK
      target_id IN (
        SELECT id FROM fighter_profiles 
        WHERE user_id = (select auth.uid())
      )
      OR
      is_admin_user()
    );
    
    RAISE NOTICE '✅ Created consolidated UPDATE policy using is_admin_user()';
  ELSE
    -- Fallback: check profiles table with optimized (select auth.uid())
    CREATE POLICY "Targets and admins can update callouts" 
    ON public.callout_requests 
    FOR UPDATE 
    TO authenticated 
    USING (
      -- Targets can update callouts where they are the target
      target_id IN (
        SELECT id FROM fighter_profiles 
        WHERE user_id = (select auth.uid())
      )
      OR
      -- Admins can update all callouts
      EXISTS (
        SELECT 1 FROM profiles 
        WHERE id = (select auth.uid()) 
        AND role = 'admin'
      )
    )
    WITH CHECK (
      -- Same conditions for WITH CHECK
      target_id IN (
        SELECT id FROM fighter_profiles 
        WHERE user_id = (select auth.uid())
      )
      OR
      EXISTS (
        SELECT 1 FROM profiles 
        WHERE id = (select auth.uid()) 
        AND role = 'admin'
      )
    );
    
    RAISE NOTICE '✅ Created consolidated UPDATE policy using (select auth.uid())';
  END IF;
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING '⚠️ Error creating policy: %', SQLERRM;
END $$;

-- Step 4: Verify the fix
SELECT 
  'After Fix' as status,
  policyname,
  cmd as command,
  roles,
  qual as using_clause,
  with_check as with_check_clause,
  CASE 
    WHEN COUNT(*) OVER (PARTITION BY cmd, roles) = 1 THEN '✅ No duplicates'
    ELSE '❌ Still has duplicates'
  END as duplicate_status
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'callout_requests'
  AND cmd = 'UPDATE'
ORDER BY policyname;

-- Step 5: Check for other duplicate policies
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

-- Step 6: Summary
SELECT 
  'Summary' as status,
  COUNT(*) FILTER (WHERE cmd = 'UPDATE' AND ('authenticated' = ANY(roles) OR roles IS NULL)) as update_policy_count,
  CASE 
    WHEN COUNT(*) FILTER (WHERE cmd = 'UPDATE' AND ('authenticated' = ANY(roles) OR roles IS NULL)) <= 1 
    THEN '✅ NO DUPLICATES - Fix successful'
    ELSE '❌ Still has duplicates - check output above'
  END as result
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'callout_requests';

