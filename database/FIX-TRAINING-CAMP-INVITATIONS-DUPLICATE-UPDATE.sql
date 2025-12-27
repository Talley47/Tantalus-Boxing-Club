-- ============================================================================
-- FIX: training_camp_invitations Duplicate UPDATE Policies
-- ============================================================================
-- Consolidates duplicate UPDATE policies:
-- - "Admins can update all training camp invitations"
-- - "Invitees can update training camp invitations"
-- - "Users can update invitations"
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
  AND tablename = 'training_camp_invitations'
  AND cmd = 'UPDATE'
ORDER BY policyname;

-- Step 2: Drop duplicate UPDATE policies
DROP POLICY IF EXISTS "Admins can update all training camp invitations" ON public.training_camp_invitations;
DROP POLICY IF EXISTS "Invitees can update training camp invitations" ON public.training_camp_invitations;
DROP POLICY IF EXISTS "Users can update invitations" ON public.training_camp_invitations;
DROP POLICY IF EXISTS "Users can update own invitations" ON public.training_camp_invitations;

-- Step 3: Create a single consolidated UPDATE policy
-- This policy allows invitees to update their invitations AND admins to update any
DO $$
BEGIN
  -- Check if is_admin_user function exists
  IF EXISTS (
    SELECT 1 FROM pg_proc 
    WHERE proname = 'is_admin_user' 
    AND pronamespace = 'public'::regnamespace
  ) THEN
    -- Use function (simpler and optimized)
    CREATE POLICY "Invitees and admins can update invitations" 
    ON public.training_camp_invitations 
    FOR UPDATE 
    TO authenticated 
    USING (
      -- Invitees can update invitations sent to them
      invitee_id IN (
        SELECT id FROM fighter_profiles 
        WHERE user_id = (select auth.uid())
      )
      OR
      -- Users can update invitations sent to them (if user_id column exists)
      (user_id IS NOT NULL AND user_id = (select auth.uid()))
      OR
      -- Admins can update any invitation
      is_admin_user()
    )
    WITH CHECK (
      -- Same conditions for WITH CHECK
      invitee_id IN (
        SELECT id FROM fighter_profiles 
        WHERE user_id = (select auth.uid())
      )
      OR
      (user_id IS NOT NULL AND user_id = (select auth.uid()))
      OR
      is_admin_user()
    );
    
    RAISE NOTICE '✅ Created consolidated UPDATE policy using is_admin_user()';
  ELSE
    -- Fallback: check profiles table with optimized (select auth.uid())
    CREATE POLICY "Invitees and admins can update invitations" 
    ON public.training_camp_invitations 
    FOR UPDATE 
    TO authenticated 
    USING (
      -- Invitees can update invitations sent to them
      invitee_id IN (
        SELECT id FROM fighter_profiles 
        WHERE user_id = (select auth.uid())
      )
      OR
      -- Users can update invitations sent to them (if user_id column exists)
      (user_id IS NOT NULL AND user_id = (select auth.uid()))
      OR
      -- Admins can update any invitation
      EXISTS (
        SELECT 1 FROM profiles 
        WHERE id = (select auth.uid()) 
        AND role = 'admin'
      )
    )
    WITH CHECK (
      -- Same conditions for WITH CHECK
      invitee_id IN (
        SELECT id FROM fighter_profiles 
        WHERE user_id = (select auth.uid())
      )
      OR
      (user_id IS NOT NULL AND user_id = (select auth.uid()))
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
  AND tablename = 'training_camp_invitations'
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
  AND tablename = 'training_camp_invitations'
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
  AND tablename = 'training_camp_invitations';

