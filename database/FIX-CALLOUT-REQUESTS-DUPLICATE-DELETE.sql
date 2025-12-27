-- ============================================================================
-- FIX: callout_requests Duplicate DELETE Policies
-- ============================================================================
-- Consolidates duplicate DELETE policies: "Admins can delete all callouts" 
-- and "Admins can delete callouts" into a single policy
-- Copy ALL of this into Supabase SQL Editor and run it
-- ============================================================================

-- Step 1: Check current DELETE policies
SELECT 
  'Current DELETE Policies' as status,
  policyname,
  cmd as command,
  roles,
  qual as using_clause
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'callout_requests'
  AND cmd = 'DELETE'
ORDER BY policyname;

-- Step 2: Drop duplicate DELETE policies
DROP POLICY IF EXISTS "Admins can delete all callouts" ON public.callout_requests;
DROP POLICY IF EXISTS "Admins can delete callouts" ON public.callout_requests;

-- Step 3: Create a single consolidated DELETE policy
DO $$
BEGIN
  -- Check if is_admin_user function exists
  IF EXISTS (
    SELECT 1 FROM pg_proc 
    WHERE proname = 'is_admin_user' 
    AND pronamespace = 'public'::regnamespace
  ) THEN
    -- Use function (simpler and optimized)
    CREATE POLICY "Admins can delete callouts" 
    ON public.callout_requests 
    FOR DELETE 
    TO authenticated 
    USING (is_admin_user());
    
    RAISE NOTICE '✅ Created consolidated DELETE policy using is_admin_user()';
  ELSE
    -- Fallback: check profiles table with optimized (select auth.uid())
    CREATE POLICY "Admins can delete callouts" 
    ON public.callout_requests 
    FOR DELETE 
    TO authenticated 
    USING (
      EXISTS (
        SELECT 1 FROM profiles 
        WHERE id = (select auth.uid()) 
        AND role = 'admin'
      )
    );
    
    RAISE NOTICE '✅ Created consolidated DELETE policy using (select auth.uid())';
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
  CASE 
    WHEN COUNT(*) OVER (PARTITION BY cmd, roles) = 1 THEN '✅ No duplicates'
    ELSE '❌ Still has duplicates'
  END as duplicate_status
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'callout_requests'
  AND cmd = 'DELETE'
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
  COUNT(*) FILTER (WHERE cmd = 'DELETE' AND ('authenticated' = ANY(roles) OR roles IS NULL)) as delete_policy_count,
  CASE 
    WHEN COUNT(*) FILTER (WHERE cmd = 'DELETE' AND ('authenticated' = ANY(roles) OR roles IS NULL)) <= 1 
    THEN '✅ NO DUPLICATES - Fix successful'
    ELSE '❌ Still has duplicates - check output above'
  END as result
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'callout_requests';

