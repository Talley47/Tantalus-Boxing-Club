-- ============================================================================
-- FIX: training_camp_invitations Duplicate SELECT Policies
-- ============================================================================
-- Consolidates multiple SELECT policies into a single one:
-- - "Admins can view all training camp invitations"
-- - "Authenticated can view active training camps"
-- - "Authenticated users can view training camp invitations"
-- - "Fighters can view own training camp invitations"
-- - "Users read own invitations"
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
  AND tablename = 'training_camp_invitations'
  AND cmd = 'SELECT'
ORDER BY policyname;

-- Step 2: Drop ALL duplicate SELECT policies
DROP POLICY IF EXISTS "Admins can view all training camp invitations" ON public.training_camp_invitations;
DROP POLICY IF EXISTS "Authenticated can view active training camps" ON public.training_camp_invitations;
DROP POLICY IF EXISTS "Authenticated users can view training camp invitations" ON public.training_camp_invitations;
DROP POLICY IF EXISTS "Fighters can view own training camp invitations" ON public.training_camp_invitations;
DROP POLICY IF EXISTS "Users read own invitations" ON public.training_camp_invitations;
DROP POLICY IF EXISTS "Users can view own invitations" ON public.training_camp_invitations;

-- Step 3: Create a single consolidated SELECT policy
-- This policy combines all the conditions: fighters can view their own invitations AND admins can view all
DO $$
BEGIN
  -- Check if is_admin_user function exists
  IF EXISTS (
    SELECT 1 FROM pg_proc 
    WHERE proname = 'is_admin_user' 
    AND pronamespace = 'public'::regnamespace
  ) THEN
    -- Use function (simpler and optimized)
    CREATE POLICY "Authenticated users can view training camp invitations" 
    ON public.training_camp_invitations 
    FOR SELECT 
    TO authenticated 
    USING (
      -- Fighters can view invitations where they are inviter or invitee
      inviter_id IN (
        SELECT id FROM fighter_profiles 
        WHERE user_id = (select auth.uid())
      )
      OR
      invitee_id IN (
        SELECT id FROM fighter_profiles 
        WHERE user_id = (select auth.uid())
      )
      OR
      -- Users can view invitations sent to them (if user_id column exists)
      (user_id IS NOT NULL AND user_id = (select auth.uid()))
      OR
      -- Admins can view all invitations
      is_admin_user()
    );
    
    RAISE NOTICE '✅ Created consolidated SELECT policy using is_admin_user()';
  ELSE
    -- Fallback: check profiles table with optimized (select auth.uid())
    CREATE POLICY "Authenticated users can view training camp invitations" 
    ON public.training_camp_invitations 
    FOR SELECT 
    TO authenticated 
    USING (
      -- Fighters can view invitations where they are inviter or invitee
      inviter_id IN (
        SELECT id FROM fighter_profiles 
        WHERE user_id = (select auth.uid())
      )
      OR
      invitee_id IN (
        SELECT id FROM fighter_profiles 
        WHERE user_id = (select auth.uid())
      )
      OR
      -- Users can view invitations sent to them (if user_id column exists)
      (user_id IS NOT NULL AND user_id = (select auth.uid()))
      OR
      -- Admins can view all invitations
      EXISTS (
        SELECT 1 FROM profiles 
        WHERE id = (select auth.uid()) 
        AND role = 'admin'
      )
    );
    
    RAISE NOTICE '✅ Created consolidated SELECT policy using (select auth.uid())';
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
  AND cmd = 'SELECT'
ORDER BY roles, policyname;

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
  COUNT(*) FILTER (WHERE cmd = 'SELECT' AND ('authenticated' = ANY(roles) OR roles IS NULL)) as authenticated_select_count,
  COUNT(*) FILTER (WHERE cmd = 'SELECT' AND ('anon' = ANY(roles) OR roles IS NULL)) as anon_select_count,
  CASE 
    WHEN COUNT(*) FILTER (WHERE cmd = 'SELECT' AND ('authenticated' = ANY(roles) OR roles IS NULL)) <= 1 
    THEN '✅ NO DUPLICATES FOR AUTHENTICATED - Fix successful'
    ELSE '❌ Still has duplicates for authenticated - check output above'
  END as result
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'training_camp_invitations';

