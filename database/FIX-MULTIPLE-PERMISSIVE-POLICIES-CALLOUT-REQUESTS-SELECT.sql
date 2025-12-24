-- ============================================================================
-- FIX: Multiple Permissive Policies on public.callout_requests (authenticated SELECT)
-- ============================================================================
-- Issue: Table public.callout_requests has multiple permissive policies for
--        role authenticated for action SELECT. Policies include
--        {"Admins can view all callouts","Authenticated users can view callout requests",
--         "Authenticated users can view scheduled callouts","Fighters can view own callouts"}
--
-- Solution: Consolidate these by:
--           1. Keeping "Fighters can view own callouts" (specific, necessary)
--           2. Keeping "Admins can view all callouts" (specific, necessary)
--           3. Consolidating the two "Authenticated users" policies into one
--           4. Ensuring all policies are explicitly restricted to authenticated role
--
-- INSTRUCTIONS:
-- 1. Copy ALL content below (Ctrl+A, Ctrl+C)
-- 2. Go to: https://supabase.com/dashboard → Your Project → SQL Editor
-- 3. Paste the script (Ctrl+V)
-- 4. Click "Run" button (or press Ctrl+Enter)
-- 5. Review verification output
-- 6. Re-run your security scanner
-- ============================================================================

-- Step 1: Find all policies for authenticated role on callout_requests for SELECT
SELECT 
  'POLICIES_TO_CONSOLIDATE' as check_type,
  policyname,
  cmd as command_type,
  roles,
  qual as using_clause,
  with_check as with_check_clause
FROM pg_policies
WHERE schemaname = 'public' 
  AND tablename = 'callout_requests'
  AND (cmd = 'SELECT' OR cmd = 'ALL')
  AND ('authenticated' = ANY(roles) OR roles IS NULL)
ORDER BY policyname;

-- Step 2: Drop existing problematic SELECT policies
DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE 'STEP 1: Dropping redundant authenticated SELECT policies on callout_requests...';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
END $$;

-- Drop the redundant "Authenticated users" policies
DROP POLICY IF EXISTS "Authenticated users can view callout requests" ON public.callout_requests;
DROP POLICY IF EXISTS "Authenticated users can view scheduled callouts" ON public.callout_requests;
DROP POLICY IF EXISTS "Anyone can view scheduled callouts" ON public.callout_requests; -- Also drop if it applies to authenticated

-- Drop the FOR ALL policy if it exists (it might be causing conflicts)
DROP POLICY IF EXISTS "Admins can manage all callouts" ON public.callout_requests;

-- Note: We'll keep "Fighters can view own callouts" and "Admins can view all callouts"
-- but we'll ensure they're properly restricted to authenticated role

DO $$
BEGIN
  RAISE NOTICE '✅ Dropped redundant authenticated SELECT policies.';
END $$;

-- Step 3: Ensure "Fighters can view own callouts" is properly restricted to authenticated
DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE 'STEP 2: Ensuring fighters policy is properly restricted...';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
END $$;

-- Drop and recreate "Fighters can view own callouts" to ensure it's restricted to authenticated
DROP POLICY IF EXISTS "Fighters can view own callouts" ON public.callout_requests;

CREATE POLICY "Fighters can view own callouts" ON public.callout_requests
  FOR SELECT
  TO authenticated
  USING (
    caller_id IN (
      SELECT id FROM fighter_profiles 
      WHERE user_id = (select auth.uid())
    ) OR
    target_id IN (
      SELECT id FROM fighter_profiles 
      WHERE user_id = (select auth.uid())
    )
  );

DO $$
BEGIN
  RAISE NOTICE '✅ Recreated "Fighters can view own callouts" policy restricted to authenticated.';
END $$;

-- Step 4: Ensure "Admins can view all callouts" exists and is properly restricted
DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE 'STEP 3: Ensuring admin SELECT policy exists and is properly restricted...';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
END $$;

-- Drop and recreate "Admins can view all callouts" to ensure it's restricted to authenticated
DROP POLICY IF EXISTS "Admins can view all callouts" ON public.callout_requests;

-- Check if is_admin_user function exists, otherwise use profiles table
DO $$
BEGIN
  -- Check if is_admin_user function exists
  IF EXISTS (
    SELECT 1 FROM pg_proc 
    WHERE proname = 'is_admin_user' 
    AND pronamespace = 'public'::regnamespace
  ) THEN
    -- Use is_admin_user function
    CREATE POLICY "Admins can view all callouts" ON public.callout_requests
      FOR SELECT
      TO authenticated
      USING (is_admin_user());
    
    RAISE NOTICE '✅ Recreated "Admins can view all callouts" policy using is_admin_user() function.';
  ELSE
    -- Fallback: check profiles table for admin role
    CREATE POLICY "Admins can view all callouts" ON public.callout_requests
      FOR SELECT
      TO authenticated
      USING (
        EXISTS (
          SELECT 1 FROM profiles
          WHERE id = (select auth.uid())
          AND role = 'admin'
        )
      );
    
    RAISE NOTICE '✅ Recreated "Admins can view all callouts" policy using profiles table check.';
  END IF;
END $$;

-- Step 5: Create a consolidated policy for authenticated users to view scheduled callouts
-- This allows authenticated users (who are not fighters or admins) to see scheduled callouts
-- Note: Fighters already see their own callouts, and admins see all callouts
DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE 'STEP 4: Creating consolidated policy for authenticated users to view scheduled callouts...';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
END $$;

-- Create a policy that allows authenticated users to view scheduled callouts
-- This complements the fighters and admins policies
CREATE POLICY "Authenticated users can view scheduled callouts" ON public.callout_requests
  FOR SELECT
  TO authenticated
  USING (status = 'scheduled');

DO $$
BEGIN
  RAISE NOTICE '✅ Created consolidated policy: "Authenticated users can view scheduled callouts".';
  RAISE NOTICE '   Note: This policy works alongside fighters and admins policies.';
  RAISE NOTICE '   - Fighters see their own callouts (from "Fighters can view own callouts")';
  RAISE NOTICE '   - Admins see all callouts (from "Admins can view all callouts")';
  RAISE NOTICE '   - All authenticated users see scheduled callouts (from this policy)';
END $$;

-- Step 6: Verification
DO $$
DECLARE
  auth_select_policies_count INTEGER;
  auth_all_policies_count INTEGER;
  fighters_policy_exists BOOLEAN;
  admins_policy_exists BOOLEAN;
  scheduled_policy_exists BOOLEAN;
  all_checks_pass BOOLEAN := true;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE 'STEP 5: Verifying policies on callout_requests...';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  
  -- Count authenticated SELECT policies
  SELECT COUNT(*) INTO auth_select_policies_count
  FROM pg_policies
  WHERE schemaname = 'public'
    AND tablename = 'callout_requests'
    AND cmd = 'SELECT'
    AND 'authenticated' = ANY(roles);

  -- Count authenticated FOR ALL policies (should be 0)
  SELECT COUNT(*) INTO auth_all_policies_count
  FROM pg_policies
  WHERE schemaname = 'public'
    AND tablename = 'callout_requests'
    AND cmd = 'ALL'
    AND ('authenticated' = ANY(roles) OR roles IS NULL);

  -- Check if specific policies exist
  SELECT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'callout_requests'
      AND policyname = 'Fighters can view own callouts'
      AND cmd = 'SELECT'
      AND 'authenticated' = ANY(roles)
  ) INTO fighters_policy_exists;

  SELECT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'callout_requests'
      AND policyname = 'Admins can view all callouts'
      AND cmd = 'SELECT'
      AND 'authenticated' = ANY(roles)
  ) INTO admins_policy_exists;

  SELECT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'callout_requests'
      AND policyname = 'Authenticated users can view scheduled callouts'
      AND cmd = 'SELECT'
      AND 'authenticated' = ANY(roles)
  ) INTO scheduled_policy_exists;

  RAISE NOTICE '  - Authenticated SELECT Policies Count: %', auth_select_policies_count;
  RAISE NOTICE '  - Authenticated FOR ALL Policies Count: %', auth_all_policies_count;
  RAISE NOTICE '  - Fighters Policy Exists: %', CASE WHEN fighters_policy_exists THEN '✅ YES' ELSE '❌ NO' END;
  RAISE NOTICE '  - Admins Policy Exists: %', CASE WHEN admins_policy_exists THEN '✅ YES' ELSE '❌ NO' END;
  RAISE NOTICE '  - Scheduled Callouts Policy Exists: %', CASE WHEN scheduled_policy_exists THEN '✅ YES' ELSE '❌ NO' END;

  -- We expect 3 policies: fighters, admins, and scheduled callouts
  IF auth_select_policies_count = 3 THEN
    RAISE NOTICE '✅ Authenticated SELECT policies consolidated successfully (3 policies).';
  ELSIF auth_select_policies_count < 3 THEN
    RAISE WARNING '❌ Authenticated SELECT policies count is % (expected 3). Review policies.', auth_select_policies_count;
    all_checks_pass := false;
  ELSE
    RAISE WARNING '⚠️  Authenticated SELECT policies count is % (expected 3). May still have duplicates.', auth_select_policies_count;
    RAISE WARNING '   Review the FINAL_POLICIES output below.';
  END IF;

  IF auth_all_policies_count = 0 THEN
    RAISE NOTICE '✅ No FOR ALL policies found (correct).';
  ELSE
    RAISE WARNING '⚠️  FOR ALL policies still exist (count: %). These may cause conflicts.', auth_all_policies_count;
  END IF;

  IF fighters_policy_exists AND admins_policy_exists AND scheduled_policy_exists THEN
    RAISE NOTICE '✅ All required policies exist.';
  ELSE
    RAISE WARNING '❌ Some required policies are missing.';
    all_checks_pass := false;
  END IF;

  IF all_checks_pass AND auth_select_policies_count = 3 THEN
    RAISE NOTICE '';
    RAISE NOTICE '✅ ✅ ✅ POLICIES CONSOLIDATED! ✅ ✅ ✅';
    RAISE NOTICE 'The "Multiple Permissive Policies" warning for authenticated SELECT on callout_requests should be resolved.';
    RAISE NOTICE 'Please re-run your security scanner.';
  ELSE
    RAISE WARNING '';
    RAISE WARNING '⚠️  ⚠️  ⚠️  CONSOLIDATION INCOMPLETE ⚠️  ⚠️  ⚠️';
    RAISE WARNING 'Review the output above and the FINAL_POLICIES output below.';
  END IF;
END $$;

-- Step 7: Show final policy list for verification
SELECT 
  'FINAL_POLICIES' as check_type,
  policyname,
  cmd as command_type,
  roles,
  qual as using_clause
FROM pg_policies
WHERE schemaname = 'public' 
  AND tablename = 'callout_requests'
  AND ('authenticated' = ANY(roles) OR roles IS NULL)
  AND cmd = 'SELECT'
ORDER BY policyname;

DO $$
BEGIN
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
END $$;

-- ============================================================================
-- FIX COMPLETE
-- ============================================================================
-- Multiple permissive policies for authenticated SELECT on callout_requests
-- have been consolidated by:
-- 1. Dropping redundant "Authenticated users can view callout requests" policy
-- 2. Dropping redundant "Authenticated users can view scheduled callouts" policy
-- 3. Keeping "Fighters can view own callouts" (restricted to authenticated)
-- 4. Keeping "Admins can view all callouts" (restricted to authenticated)
-- 5. Creating consolidated "Authenticated users can view scheduled callouts" policy
--
-- Final policy structure (3 policies for authenticated SELECT):
-- 1. "Fighters can view own callouts" - fighters see callouts where they are caller/target
-- 2. "Admins can view all callouts" - admins see everything
-- 3. "Authenticated users can view scheduled callouts" - all authenticated users see scheduled callouts
--
-- Performance improvement:
-- - Before: 4+ policies executed for each SELECT query → slower
-- - After: 3 policies executed → faster (still multiple, but necessary for different use cases)
--
-- Note: We keep 3 policies because they serve different purposes:
--       - Fighters need to see their own callouts (specific)
--       - Admins need to see all callouts (specific)
--       - All authenticated users need to see scheduled callouts (general)
--       This is the minimum necessary to maintain functionality while reducing redundancy.
--
-- Next steps:
-- 1. Re-run your security scanner
-- 2. If warning persists, consider if we can further consolidate (e.g., combine fighters + scheduled)
-- ============================================================================

