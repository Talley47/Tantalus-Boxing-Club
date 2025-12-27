-- ============================================================================
-- FIX: training_camp_invitations Duplicate DELETE Policies
-- ============================================================================
-- Consolidates duplicate DELETE policies:
-- - "Admins can delete all training camp invitation"
-- - "Users can delete invitations"
-- Into a single consolidated policy
-- Copy ALL of this into Supabase SQL Editor and run it
-- ============================================================================

-- Step 1: Check current DELETE policies
SELECT 
  'Current DELETE Policies' as status,
  policyname,
  cmd as command,
  roles,
  qual as using_clause,
  with_check as with_check_clause
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'training_camp_invitations'
  AND cmd = 'DELETE'
ORDER BY policyname;

-- Step 2: Drop duplicate DELETE policies
DROP POLICY IF EXISTS "Admins can delete all training camp invitation" ON public.training_camp_invitations;
DROP POLICY IF EXISTS "Admins can delete all training camp invitations" ON public.training_camp_invitations;
DROP POLICY IF EXISTS "Users can delete invitations" ON public.training_camp_invitations;
DROP POLICY IF EXISTS "Users can delete own invitations" ON public.training_camp_invitations;

-- Step 3: Create a single consolidated DELETE policy
-- This policy allows users to delete their own invitations AND admins to delete any
DO $$
BEGIN
  -- Check if is_admin_user function exists
  IF EXISTS (
    SELECT 1 FROM pg_proc 
    WHERE proname = 'is_admin_user' 
    AND pronamespace = 'public'::regnamespace
  ) THEN
    -- Use function (simpler and optimized)
    CREATE POLICY "Users and admins can delete invitations" 
    ON public.training_camp_invitations 
    FOR DELETE 
    TO authenticated 
    USING (
      -- Users can delete invitations sent to them
      user_id = (select auth.uid())
      OR
      -- Admins can delete any invitation
      is_admin_user()
    );
    
    RAISE NOTICE '✅ Created consolidated DELETE policy using is_admin_user()';
  ELSE
    -- Fallback: check profiles table with optimized (select auth.uid())
    CREATE POLICY "Users and admins can delete invitations" 
    ON public.training_camp_invitations 
    FOR DELETE 
    TO authenticated 
    USING (
      -- Users can delete invitations sent to them
      user_id = (select auth.uid())
      OR
      -- Admins can delete any invitation
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
  AND tablename = 'training_camp_invitations'
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
  AND tablename = 'training_camp_invitations'
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
  AND tablename = 'training_camp_invitations';

