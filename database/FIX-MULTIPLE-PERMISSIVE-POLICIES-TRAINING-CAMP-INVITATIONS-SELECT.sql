-- ============================================================================
-- FIX: Multiple Permissive Policies on training_camp_invitations table (SELECT)
-- ============================================================================
-- Issue: Table has multiple permissive policies for role 'anon' for action SELECT:
--        - "Fighters can view own training camp invitations" (should be authenticated only)
--        - "Public can view training camp invitations" or "Anyone can view active training camps"
-- 
-- Solution: Consolidate anon SELECT policies into a single policy and ensure
--           fighters policy is properly restricted to authenticated role.
--           Multiple permissive policies are suboptimal because each must be
--           executed for every query.
-- ============================================================================

-- Step 1: Find all policies for anon role on training_camp_invitations for SELECT
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
  AND cmd = 'SELECT'
  AND ('anon' = ANY(roles) OR roles IS NULL)
ORDER BY policyname;

-- Step 2: Drop all anon SELECT policies (we'll recreate a single one)
DROP POLICY IF EXISTS "Public can view training camp invitations" ON public.training_camp_invitations;
DROP POLICY IF EXISTS "Anyone can view active training camps" ON public.training_camp_invitations;

-- Step 3: Ensure "Fighters can view own training camp invitations" is restricted to authenticated
-- Drop it if it exists without role restriction or applies to anon
DROP POLICY IF EXISTS "Fighters can view own training camp invitations" ON public.training_camp_invitations;

-- Step 4: Create a single consolidated policy for anon role
-- This policy allows anonymous users to view active training camps
-- (needed for public display on HomePage)
CREATE POLICY "Public can view active training camps" ON public.training_camp_invitations
  FOR SELECT
  TO anon
  USING (
    status = 'accepted' 
    AND expires_at >= NOW()
  );

-- Step 5: Recreate fighters policy properly restricted to authenticated role
CREATE POLICY "Fighters can view own training camp invitations" ON public.training_camp_invitations
  FOR SELECT
  TO authenticated
  USING (
    inviter_id IN (
      SELECT id FROM fighter_profiles 
      WHERE user_id = (select auth.uid())
    )
    OR invitee_id IN (
      SELECT id FROM fighter_profiles 
      WHERE user_id = (select auth.uid())
    )
  );

-- Step 6: Ensure authenticated users can also view active training camps
-- (This allows authenticated users to see both their own AND all active camps)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' 
      AND tablename = 'training_camp_invitations'
      AND cmd = 'SELECT'
      AND 'authenticated' = ANY(roles)
      AND qual LIKE '%status = ''accepted''%'
  ) THEN
    CREATE POLICY "Authenticated can view active training camps" ON public.training_camp_invitations
      FOR SELECT
      TO authenticated
      USING (
        status = 'accepted' 
        AND expires_at >= NOW()
      );
    
    RAISE NOTICE '✅ Created separate policy for authenticated users to view active camps';
  ELSE
    RAISE NOTICE 'ℹ️  Authenticated users already have a policy to view active camps';
  END IF;
END $$;

-- Step 7: Verify the consolidated policies
SELECT 
  'CONSOLIDATED_POLICIES' as check_type,
  policyname,
  cmd as command_type,
  roles,
  qual as using_clause,
  CASE 
    WHEN COUNT(*) OVER (PARTITION BY tablename, cmd, roles) = 1 THEN '✅ Single policy'
    ELSE '❌ Multiple policies'
  END as consolidation_status
FROM pg_policies
WHERE schemaname = 'public' 
  AND tablename = 'training_camp_invitations'
  AND cmd = 'SELECT'
  AND ('anon' = ANY(roles) OR roles IS NULL)
ORDER BY policyname;

-- Step 8: Final verification
DO $$
DECLARE
  anon_select_policy_count INTEGER;
  consolidated_policy_exists BOOLEAN;
  fighters_policy_restricted BOOLEAN;
  authenticated_policy_exists BOOLEAN;
BEGIN
  -- Count anon SELECT policies
  SELECT COUNT(*) INTO anon_select_policy_count
  FROM pg_policies
  WHERE schemaname = 'public' 
    AND tablename = 'training_camp_invitations'
    AND cmd = 'SELECT'
    AND ('anon' = ANY(roles) OR roles IS NULL);
  
  -- Check if the consolidated policy exists
  SELECT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' 
      AND tablename = 'training_camp_invitations'
      AND policyname = 'Public can view active training camps'
      AND cmd = 'SELECT'
      AND 'anon' = ANY(roles)
  ) INTO consolidated_policy_exists;
  
  -- Check if fighters policy is properly restricted to authenticated
  SELECT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' 
      AND tablename = 'training_camp_invitations'
      AND policyname = 'Fighters can view own training camp invitations'
      AND cmd = 'SELECT'
      AND 'authenticated' = ANY(roles)
      AND NOT ('anon' = ANY(roles) OR roles IS NULL)
  ) INTO fighters_policy_restricted;
  
  -- Check if authenticated policy exists
  SELECT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' 
      AND tablename = 'training_camp_invitations'
      AND cmd = 'SELECT'
      AND 'authenticated' = ANY(roles)
  ) INTO authenticated_policy_exists;
  
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '                    VERIFICATION RESULTS';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '';
  RAISE NOTICE 'Anon SELECT Policies Count: %', anon_select_policy_count;
  RAISE NOTICE 'Consolidated Policy Exists: %', CASE WHEN consolidated_policy_exists THEN '✅ YES' ELSE '❌ NO' END;
  RAISE NOTICE 'Fighters Policy Restricted to Authenticated: %', CASE WHEN fighters_policy_restricted THEN '✅ YES' ELSE '❌ NO' END;
  RAISE NOTICE 'Authenticated Policy Exists: %', CASE WHEN authenticated_policy_exists THEN '✅ YES' ELSE '❌ NO' END;
  RAISE NOTICE '';
  
  IF consolidated_policy_exists 
     AND anon_select_policy_count = 1 
     AND fighters_policy_restricted THEN
    RAISE NOTICE '✅ ✅ ✅ POLICIES CONSOLIDATED! ✅ ✅ ✅';
    RAISE NOTICE '';
    RAISE NOTICE 'Multiple permissive policies for anon role have been consolidated.';
    RAISE NOTICE 'Fighters policy is now properly restricted to authenticated role.';
    RAISE NOTICE 'Performance warning should be resolved.';
    IF authenticated_policy_exists THEN
      RAISE NOTICE '✅ Authenticated users have separate policies (no conflicts).';
    END IF;
  ELSIF anon_select_policy_count > 1 THEN
    RAISE WARNING '⚠️  Still have % anon SELECT policies - consolidation incomplete!', anon_select_policy_count;
    RAISE WARNING '   Review the CONSOLIDATED_POLICIES output above.';
  ELSIF NOT fighters_policy_restricted THEN
    RAISE WARNING '⚠️  Fighters policy is not properly restricted to authenticated role!';
    RAISE WARNING '   This may cause the multiple permissive policies warning.';
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
-- Multiple permissive policies for anon role on training_camp_invitations have been
-- consolidated into a single policy: "Public can view active training camps"
-- 
-- Performance improvement:
-- - Before: Multiple policies executed for each query → slower
-- - After: Single policy executed → faster
-- 
-- Security improvement:
-- - Before: "Fighters can view own training camp invitations" might apply to anon
-- - After: Fighters policy is properly restricted to authenticated role only
-- 
-- Note: The consolidated policy allows anonymous users to view only active training
--       camps (status = 'accepted' and not expired), which is needed for public
--       display on HomePage.
-- 
--       Authenticated users have separate policies:
--       - "Fighters can view own training camp invitations" (their own camps)
--       - "Authenticated can view active training camps" (all active camps)
-- 
-- Next steps:
-- 1. Re-run your security scanner
-- 2. Performance warning should be resolved ✅
-- ============================================================================

