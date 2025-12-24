-- ============================================================================
-- FIX: Multiple Permissive Policies on training_camp_invitations table
-- ============================================================================
-- Issue: Table has multiple permissive policies for role 'anon' for action INSERT:
--        - "Admins can manage all training camp invitations" (FOR ALL - applies to all roles)
--        - "Fighters can create training camp invitations"
-- 
-- Solution: Consolidate INSERT policies into a single combined policy and ensure
--           they're properly restricted to authenticated role (not anon).
--           Multiple permissive policies are suboptimal because each must be
--           executed for every query.
-- ============================================================================

-- Step 1: Find all policies for INSERT on training_camp_invitations
SELECT 
  'POLICIES_TO_CONSOLIDATE' as check_type,
  policyname,
  cmd as command_type,
  roles,
  qual as using_clause,
  with_check as with_check_clause
FROM pg_policies
WHERE schemaname = 'public' 
  AND tablename = 'training_camp_invitations'
  AND (cmd = 'INSERT' OR cmd = 'ALL')
ORDER BY policyname;

-- Step 2: Drop existing INSERT policies that need consolidation
DROP POLICY IF EXISTS "Fighters can create training camp invitations" ON public.training_camp_invitations;
DROP POLICY IF EXISTS "Users can insert invitations" ON public.training_camp_invitations;
DROP POLICY IF EXISTS "Fighters and admins can create training camp invitations" ON public.training_camp_invitations;

-- Step 3: Handle the "Admins can manage all training camp invitations" policy
-- This policy uses FOR ALL, which might be applying to anon role
-- We need to drop it and recreate it properly restricted, OR split it
DO $$
BEGIN
  -- Check if the admin FOR ALL policy exists
  IF EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' 
      AND tablename = 'training_camp_invitations'
      AND policyname = 'Admins can manage all training camp invitations'
      AND cmd = 'ALL'
  ) THEN
    -- Drop the FOR ALL policy - we'll recreate it properly restricted
    DROP POLICY IF EXISTS "Admins can manage all training camp invitations" ON public.training_camp_invitations;
    RAISE NOTICE '✅ Dropped FOR ALL admin policy (will recreate properly restricted)';
  END IF;
END $$;

-- Step 4: Create a single consolidated INSERT policy for authenticated role
-- This combines fighters and admins into one policy to avoid multiple permissive policies
CREATE POLICY "Fighters and admins can create training camp invitations" ON public.training_camp_invitations
  FOR INSERT
  TO authenticated
  WITH CHECK (
    -- Fighters can create invitations where they are the inviter
    inviter_id IN (
      SELECT id FROM fighter_profiles 
      WHERE user_id = (select auth.uid())
    )
    OR
    -- Admins can create any invitation
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE id = (select auth.uid()) 
      AND role = 'admin'
    )
  );

-- Step 5: Drop existing admin policies before recreating them
DROP POLICY IF EXISTS "Admins can view all training camp invitations" ON public.training_camp_invitations;
DROP POLICY IF EXISTS "Admins can update all training camp invitations" ON public.training_camp_invitations;
DROP POLICY IF EXISTS "Admins can delete all training camp invitations" ON public.training_camp_invitations;

-- Step 6: Recreate admin policies for SELECT, UPDATE, DELETE (not INSERT)
-- This ensures admins can still manage invitations, but INSERT is handled by the combined policy above
DO $$
BEGIN
  -- Check if is_admin_user function exists
  IF EXISTS (
    SELECT 1 FROM pg_proc 
    WHERE proname = 'is_admin_user' 
    AND pronamespace = 'public'::regnamespace
  ) THEN
    -- Use is_admin_user function
    EXECUTE 'CREATE POLICY "Admins can view all training camp invitations" ON public.training_camp_invitations
      FOR SELECT TO authenticated USING (is_admin_user())';
    
    EXECUTE 'CREATE POLICY "Admins can update all training camp invitations" ON public.training_camp_invitations
      FOR UPDATE TO authenticated USING (is_admin_user()) WITH CHECK (is_admin_user())';
    
    EXECUTE 'CREATE POLICY "Admins can delete all training camp invitations" ON public.training_camp_invitations
      FOR DELETE TO authenticated USING (is_admin_user())';
  ELSE
    -- Fallback: check profiles table
    EXECUTE 'CREATE POLICY "Admins can view all training camp invitations" ON public.training_camp_invitations
      FOR SELECT TO authenticated USING (
        EXISTS (
          SELECT 1 FROM profiles 
          WHERE id = (select auth.uid()) 
          AND role = ''admin''
        )
      )';
    
    EXECUTE 'CREATE POLICY "Admins can update all training camp invitations" ON public.training_camp_invitations
      FOR UPDATE TO authenticated USING (
        EXISTS (
          SELECT 1 FROM profiles 
          WHERE id = (select auth.uid()) 
          AND role = ''admin''
        )
      ) WITH CHECK (
        EXISTS (
          SELECT 1 FROM profiles 
          WHERE id = (select auth.uid()) 
          AND role = ''admin''
        )
      )';
    
    EXECUTE 'CREATE POLICY "Admins can delete all training camp invitations" ON public.training_camp_invitations
      FOR DELETE TO authenticated USING (
        EXISTS (
          SELECT 1 FROM profiles 
          WHERE id = (select auth.uid()) 
          AND role = ''admin''
        )
      )';
  END IF;
  
  RAISE NOTICE '✅ Created separate admin policies for SELECT, UPDATE, DELETE';
END $$;

-- Step 7: Verify the consolidated INSERT policy
SELECT 
  'CONSOLIDATED_INSERT_POLICIES' as check_type,
  policyname,
  cmd as command_type,
  roles,
  qual as using_clause,
  with_check as with_check_clause,
  CASE 
    WHEN COUNT(*) OVER (PARTITION BY tablename, cmd, roles) = 1 THEN '✅ Single policy'
    ELSE '❌ Multiple policies'
  END as consolidation_status
FROM pg_policies
WHERE schemaname = 'public' 
  AND tablename = 'training_camp_invitations'
  AND cmd = 'INSERT'
ORDER BY policyname;

-- Step 8: Final verification
DO $$
DECLARE
  anon_insert_policy_count INTEGER;
  authenticated_insert_policy_count INTEGER;
  consolidated_policy_exists BOOLEAN;
  admin_for_all_exists BOOLEAN;
BEGIN
  -- Count anon INSERT policies
  SELECT COUNT(*) INTO anon_insert_policy_count
  FROM pg_policies
  WHERE schemaname = 'public' 
    AND tablename = 'training_camp_invitations'
    AND cmd IN ('INSERT', 'ALL')
    AND ('anon' = ANY(roles) OR roles IS NULL);
  
  -- Count authenticated INSERT policies
  SELECT COUNT(*) INTO authenticated_insert_policy_count
  FROM pg_policies
  WHERE schemaname = 'public' 
    AND tablename = 'training_camp_invitations'
    AND cmd = 'INSERT'
    AND 'authenticated' = ANY(roles);
  
  -- Check if the consolidated policy exists
  SELECT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' 
      AND tablename = 'training_camp_invitations'
      AND policyname = 'Fighters and admins can create training camp invitations'
      AND cmd = 'INSERT'
      AND 'authenticated' = ANY(roles)
  ) INTO consolidated_policy_exists;
  
  -- Check if admin FOR ALL policy still exists (should not)
  SELECT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' 
      AND tablename = 'training_camp_invitations'
      AND policyname = 'Admins can manage all training camp invitations'
      AND cmd = 'ALL'
  ) INTO admin_for_all_exists;
  
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '                    VERIFICATION RESULTS';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '';
  RAISE NOTICE 'Anon INSERT Policies Count: %', anon_insert_policy_count;
  RAISE NOTICE 'Authenticated INSERT Policies Count: %', authenticated_insert_policy_count;
  RAISE NOTICE 'Consolidated Policy Exists: %', CASE WHEN consolidated_policy_exists THEN '✅ YES' ELSE '❌ NO' END;
  RAISE NOTICE 'Admin FOR ALL Policy Exists: %', CASE WHEN admin_for_all_exists THEN '⚠️ YES (should be removed)' ELSE '✅ NO' END;
  RAISE NOTICE '';
  
  IF consolidated_policy_exists 
     AND authenticated_insert_policy_count = 1 
     AND anon_insert_policy_count = 0 
     AND NOT admin_for_all_exists THEN
    RAISE NOTICE '✅ ✅ ✅ POLICIES CONSOLIDATED! ✅ ✅ ✅';
    RAISE NOTICE '';
    RAISE NOTICE 'Multiple permissive policies for INSERT have been consolidated.';
    RAISE NOTICE 'All INSERT policies are now properly restricted to authenticated role.';
    RAISE NOTICE 'Performance warning should be resolved.';
  ELSIF anon_insert_policy_count > 0 THEN
    RAISE WARNING '⚠️  Still have % anon INSERT policies - consolidation incomplete!', anon_insert_policy_count;
    RAISE WARNING '   Anonymous users should not be able to insert training camp invitations.';
    RAISE WARNING '   Review the CONSOLIDATED_INSERT_POLICIES output above.';
  ELSIF admin_for_all_exists THEN
    RAISE WARNING '⚠️  Admin FOR ALL policy still exists - this may apply to anon role!';
    RAISE WARNING '   The policy should be split into separate policies restricted to authenticated.';
  ELSE
    RAISE WARNING '❌ FAILED: Consolidated policy was not created correctly!';
    RAISE WARNING '   Please check for errors above.';
  END IF;
  
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
END $$;

-- ============================================================================
-- FIX COMPLETE
-- ============================================================================
-- Multiple permissive policies for INSERT on training_camp_invitations have been
-- consolidated into a single policy: "Fighters and admins can create training camp invitations"
-- 
-- Performance improvement:
-- - Before: Multiple policies executed for each query → slower
-- - After: Single policy executed → faster
-- 
-- Security improvement:
-- - Before: Policies might have applied to anon role (incorrect)
-- - After: All INSERT policies are properly restricted to authenticated role
-- 
-- Note: The consolidated policy allows:
-- - Fighters to create invitations where they are the inviter
-- - Admins to create any invitation
-- 
--       Admin policies for SELECT, UPDATE, DELETE are separate and properly
--       restricted to authenticated role.
-- 
-- Next steps:
-- 1. Re-run your security scanner
-- 2. Performance warning should be resolved ✅
-- ============================================================================

