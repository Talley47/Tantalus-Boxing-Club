-- ============================================================================
-- FIX: callout_requests Duplicate INSERT Policies
-- ============================================================================
-- Consolidates duplicate INSERT policies: "Admins can insert callouts" 
-- and "Fighters and admins can create callouts" into a single policy
-- Copy ALL of this into Supabase SQL Editor and run it
-- ============================================================================

-- Step 1: Check current INSERT policies
SELECT 
  'Current INSERT Policies' as status,
  policyname,
  cmd as command,
  roles,
  qual as using_clause,
  with_check as with_check_clause
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'callout_requests'
  AND cmd = 'INSERT'
ORDER BY policyname;

-- Step 2: Drop duplicate INSERT policies
DROP POLICY IF EXISTS "Admins can insert callouts" ON public.callout_requests;
DROP POLICY IF EXISTS "Fighters and admins can create callouts" ON public.callout_requests;
DROP POLICY IF EXISTS "Fighters can create callouts" ON public.callout_requests;

-- Step 3: Create a single consolidated INSERT policy
-- This policy allows both fighters and admins to insert callouts
DO $$
BEGIN
  -- Check if is_admin_user function exists
  IF EXISTS (
    SELECT 1 FROM pg_proc 
    WHERE proname = 'is_admin_user' 
    AND pronamespace = 'public'::regnamespace
  ) THEN
    -- Use function (simpler and optimized)
    CREATE POLICY "Fighters and admins can create callouts" 
    ON public.callout_requests 
    FOR INSERT 
    TO authenticated 
    WITH CHECK (
      -- Fighters can create callouts (caller_id must match their fighter profile)
      caller_id IN (
        SELECT id FROM fighter_profiles 
        WHERE user_id = (select auth.uid())
      )
      OR
      -- Admins can create callouts
      is_admin_user()
    );
    
    RAISE NOTICE '✅ Created consolidated INSERT policy using is_admin_user()';
  ELSE
    -- Fallback: check profiles table with optimized (select auth.uid())
    CREATE POLICY "Fighters and admins can create callouts" 
    ON public.callout_requests 
    FOR INSERT 
    TO authenticated 
    WITH CHECK (
      -- Fighters can create callouts (caller_id must match their fighter profile)
      caller_id IN (
        SELECT id FROM fighter_profiles 
        WHERE user_id = (select auth.uid())
      )
      OR
      -- Admins can create callouts
      EXISTS (
        SELECT 1 FROM profiles 
        WHERE id = (select auth.uid()) 
        AND role = 'admin'
      )
    );
    
    RAISE NOTICE '✅ Created consolidated INSERT policy using (select auth.uid())';
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
  with_check as with_check_clause,
  CASE 
    WHEN COUNT(*) OVER (PARTITION BY cmd, roles) = 1 THEN '✅ No duplicates'
    ELSE '❌ Still has duplicates'
  END as duplicate_status
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'callout_requests'
  AND cmd = 'INSERT'
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
  COUNT(*) FILTER (WHERE cmd = 'INSERT' AND ('authenticated' = ANY(roles) OR roles IS NULL)) as insert_policy_count,
  CASE 
    WHEN COUNT(*) FILTER (WHERE cmd = 'INSERT' AND ('authenticated' = ANY(roles) OR roles IS NULL)) <= 1 
    THEN '✅ NO DUPLICATES - Fix successful'
    ELSE '❌ Still has duplicates - check output above'
  END as result
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'callout_requests';

