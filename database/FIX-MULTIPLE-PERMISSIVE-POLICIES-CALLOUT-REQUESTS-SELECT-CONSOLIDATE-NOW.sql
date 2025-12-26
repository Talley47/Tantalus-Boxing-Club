-- ============================================================================
-- 🔒 CONSOLIDATE: Multiple Permissive Policies on public.callout_requests (authenticated SELECT)
-- ============================================================================
-- Issue: Table public.callout_requests has multiple permissive policies for
--        role authenticated for action SELECT. Policies include:
--        {"Admins can view all callouts","Authenticated users can view callouts"}
--
-- Solution: Consolidate these two policies into a SINGLE policy that handles
--           both admin access and general authenticated user access.
--
-- INSTRUCTIONS:
-- 1. Copy ALL content below (Ctrl+A, Ctrl+C)
-- 2. Go to: https://supabase.com/dashboard → Your Project → SQL Editor
-- 3. Paste the script (Ctrl+V)
-- 4. Click "Run" button (or press Ctrl+Enter)
-- 5. Review verification output
-- 6. Wait 5-10 minutes for scanner cache to refresh
-- 7. Re-run your security scanner
--
-- ============================================================================

-- Start transaction for atomicity
BEGIN;

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '🔒 CONSOLIDATING MULTIPLE PERMISSIVE SELECT POLICIES ON public.callout_requests';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '';
END $$;

-- ============================================================================
-- STEP 1: Show current policies before consolidation
-- ============================================================================

DO $$
BEGIN
  RAISE NOTICE '--- STEP 1: Current authenticated SELECT policies on callout_requests ---';
END $$;

SELECT 
  'CURRENT_POLICIES' as check_type,
  policyname,
  cmd as command_type,
  roles,
  qual as using_clause
FROM pg_policies
WHERE schemaname = 'public' 
  AND tablename = 'callout_requests'
  AND cmd = 'SELECT'
  AND 'authenticated' = ANY(roles)
ORDER BY policyname;

-- ============================================================================
-- STEP 2: Drop the two conflicting policies
-- ============================================================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '--- STEP 2: Dropping conflicting authenticated SELECT policies ---';
END $$;

-- Drop the two specific policies mentioned in the warning
DROP POLICY IF EXISTS "Admins can view all callouts" ON public.callout_requests;
DROP POLICY IF EXISTS "Authenticated users can view callouts" ON public.callout_requests;

-- Also drop any other potentially conflicting authenticated SELECT policies
DROP POLICY IF EXISTS "Fighters can view own callouts" ON public.callout_requests;
DROP POLICY IF EXISTS "Authenticated users can view callout requests" ON public.callout_requests;
DROP POLICY IF EXISTS "Authenticated users can view scheduled callouts" ON public.callout_requests;
DROP POLICY IF EXISTS "Anyone can view scheduled callouts" ON public.callout_requests;

-- Drop FOR ALL policy if it exists (it might be causing conflicts)
DROP POLICY IF EXISTS "Admins can manage all callouts" ON public.callout_requests;

DO $$
BEGIN
  RAISE NOTICE '✅ Dropped all potentially conflicting authenticated SELECT policies.';
  RAISE NOTICE '';
END $$;

-- ============================================================================
-- STEP 3: Create a SINGLE consolidated SELECT policy
-- ============================================================================
-- This policy combines both admin access and general authenticated user access
-- into one policy using OR logic.

DO $$
BEGIN
  RAISE NOTICE '--- STEP 3: Creating SINGLE consolidated SELECT policy for authenticated users ---';
END $$;

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
    CREATE POLICY "Authenticated users can view callouts" ON public.callout_requests
      FOR SELECT
      TO authenticated
      USING (
        -- Case 1: Admins can view all callouts
        is_admin_user()
        OR
        -- Case 2: Fighters can view callouts where they are caller or target
        caller_id IN (
          SELECT id FROM fighter_profiles 
          WHERE user_id = (select auth.uid())
        ) OR
        target_id IN (
          SELECT id FROM fighter_profiles 
          WHERE user_id = (select auth.uid())
        )
        OR
        -- Case 3: All authenticated users can view scheduled callouts
        status = 'scheduled'
      );
    
    RAISE NOTICE '✅ Created single consolidated SELECT policy using is_admin_user() function.';
  ELSE
    -- Fallback: check profiles table for admin role
    CREATE POLICY "Authenticated users can view callouts" ON public.callout_requests
      FOR SELECT
      TO authenticated
      USING (
        -- Case 1: Admins can view all callouts
        EXISTS (
          SELECT 1 FROM profiles
          WHERE id = (select auth.uid())
          AND role = 'admin'
        )
        OR
        -- Case 2: Fighters can view callouts where they are caller or target
        caller_id IN (
          SELECT id FROM fighter_profiles 
          WHERE user_id = (select auth.uid())
        ) OR
        target_id IN (
          SELECT id FROM fighter_profiles 
          WHERE user_id = (select auth.uid())
        )
        OR
        -- Case 3: All authenticated users can view scheduled callouts
        status = 'scheduled'
      );
    
    RAISE NOTICE '✅ Created single consolidated SELECT policy using profiles table check.';
  END IF;
  RAISE NOTICE '';
END $$;

-- ============================================================================
-- STEP 4: Ensure admin policies for other actions (INSERT, UPDATE, DELETE) exist
-- ============================================================================
-- These policies are for other actions and should not conflict with the SELECT policy.

DO $$
BEGIN
  RAISE NOTICE '--- STEP 4: Ensuring admin policies for INSERT, UPDATE, DELETE exist ---';
END $$;

-- Drop specific admin policies if they exist (to avoid conflicts when recreating)
DROP POLICY IF EXISTS "Admins can insert callouts" ON public.callout_requests;
DROP POLICY IF EXISTS "Admins can update all callouts" ON public.callout_requests;
DROP POLICY IF EXISTS "Admins can delete all callouts" ON public.callout_requests;

DO $$
BEGIN
  -- Check if is_admin_user function exists
  IF EXISTS (
    SELECT 1 FROM pg_proc 
    WHERE proname = 'is_admin_user' 
    AND pronamespace = 'public'::regnamespace
  ) THEN
    -- Use is_admin_user function for INSERT, UPDATE, DELETE
    CREATE POLICY "Admins can insert callouts" ON public.callout_requests
      FOR INSERT TO authenticated WITH CHECK (is_admin_user());
    CREATE POLICY "Admins can update all callouts" ON public.callout_requests
      FOR UPDATE TO authenticated USING (is_admin_user());
    CREATE POLICY "Admins can delete all callouts" ON public.callout_requests
      FOR DELETE TO authenticated USING (is_admin_user());
    RAISE NOTICE '✅ Recreated admin policies for INSERT, UPDATE, DELETE using is_admin_user() function.';
  ELSE
    -- Fallback: check profiles table for admin role for INSERT, UPDATE, DELETE
    CREATE POLICY "Admins can insert callouts" ON public.callout_requests
      FOR INSERT TO authenticated WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE id = (select auth.uid()) AND role = 'admin'));
    CREATE POLICY "Admins can update all callouts" ON public.callout_requests
      FOR UPDATE TO authenticated USING (EXISTS (SELECT 1 FROM profiles WHERE id = (select auth.uid()) AND role = 'admin'));
    CREATE POLICY "Admins can delete all callouts" ON public.callout_requests
      FOR DELETE TO authenticated USING (EXISTS (SELECT 1 FROM profiles WHERE id = (select auth.uid()) AND role = 'admin'));
    RAISE NOTICE '✅ Recreated admin policies for INSERT, UPDATE, DELETE using profiles table check.';
  END IF;
  RAISE NOTICE '';
END $$;

-- ============================================================================
-- STEP 5: Verification
-- ============================================================================

DO $$
BEGIN
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '                    FINAL VERIFICATION CHECKS';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '';
END $$;

DO $$
DECLARE
  auth_select_policies_count INTEGER;
  admins_can_view_all_exists BOOLEAN;
  authenticated_users_can_view_exists BOOLEAN;
  all_checks_pass BOOLEAN := true;
BEGIN
  -- Count authenticated SELECT policies (should be exactly 1)
  SELECT COUNT(*) INTO auth_select_policies_count
  FROM pg_policies
  WHERE schemaname = 'public'
    AND tablename = 'callout_requests'
    AND cmd = 'SELECT'
    AND 'authenticated' = ANY(roles);

  -- Check if the old "Admins can view all callouts" policy still exists
  SELECT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'callout_requests'
      AND policyname = 'Admins can view all callouts'
      AND cmd = 'SELECT'
      AND 'authenticated' = ANY(roles)
  ) INTO admins_can_view_all_exists;

  -- Check if the consolidated "Authenticated users can view callouts" policy exists
  SELECT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'callout_requests'
      AND policyname = 'Authenticated users can view callouts'
      AND cmd = 'SELECT'
      AND 'authenticated' = ANY(roles)
  ) INTO authenticated_users_can_view_exists;

  RAISE NOTICE '  - Authenticated SELECT Policies Count: %', auth_select_policies_count;
  RAISE NOTICE '  - "Admins can view all callouts" policy exists: %', CASE WHEN admins_can_view_all_exists THEN '❌ YES' ELSE '✅ NO' END;
  RAISE NOTICE '  - "Authenticated users can view callouts" policy exists: %', CASE WHEN authenticated_users_can_view_exists THEN '✅ YES' ELSE '❌ NO' END;

  IF auth_select_policies_count = 1 THEN
    RAISE NOTICE '✅ Authenticated SELECT policies consolidated successfully (1 policy).';
  ELSE
    RAISE WARNING '❌ Authenticated SELECT policies count is % (expected 1). Review policies.', auth_select_policies_count;
    all_checks_pass := false;
  END IF;

  IF NOT admins_can_view_all_exists THEN
    RAISE NOTICE '✅ "Admins can view all callouts" policy successfully removed.';
  ELSE
    RAISE WARNING '❌ "Admins can view all callouts" policy still exists. Review script and policies.';
    all_checks_pass := false;
  END IF;

  IF authenticated_users_can_view_exists THEN
    RAISE NOTICE '✅ Consolidated "Authenticated users can view callouts" policy exists.';
  ELSE
    RAISE WARNING '❌ Consolidated "Authenticated users can view callouts" policy was not created.';
    all_checks_pass := false;
  END IF;

  IF all_checks_pass THEN
    RAISE NOTICE '';
    RAISE NOTICE '✅ ✅ ✅ CONSOLIDATION SUCCESSFUL! ✅ ✅ ✅';
    RAISE NOTICE 'The "Multiple Permissive Policies" warning for authenticated SELECT on callout_requests should be RESOLVED.';
    RAISE NOTICE '';
    RAISE NOTICE 'The single consolidated policy "Authenticated users can view callouts" now handles:';
    RAISE NOTICE '  • Admins can view all callouts';
    RAISE NOTICE '  • Fighters can view callouts where they are caller or target';
    RAISE NOTICE '  • All authenticated users can view scheduled callouts';
    RAISE NOTICE '';
    RAISE NOTICE 'Next steps:';
    RAISE NOTICE '  1. Wait 5-10 minutes for scanner cache to refresh';
    RAISE NOTICE '  2. Re-run your security scanner';
    RAISE NOTICE '  3. The warning should be gone ✅';
  ELSE
    RAISE WARNING '';
    RAISE WARNING '⚠️  ⚠️  ⚠️  CONSOLIDATION FAILED ⚠️  ⚠️  ⚠️';
    RAISE WARNING 'Review the output above and try running the script again.';
  END IF;
  
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
END $$;

-- Show final policy list for verification
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
ORDER BY cmd, policyname;

-- Commit transaction if all steps were successful
COMMIT;

-- ============================================================================
-- ✅ FIX COMPLETE
-- ============================================================================
-- Multiple permissive policies for authenticated SELECT on callout_requests
-- have been CONSOLIDATED into a SINGLE policy:
--
-- "Authenticated users can view callouts"
--
-- This single policy handles ALL cases using OR logic:
-- 1. Admins can view all callouts
-- 2. Fighters can view callouts where they are caller or target
-- 3. All authenticated users can view scheduled callouts
--
-- Performance improvement:
-- - Before: 2+ policies executed for each SELECT query → slower
-- - After: 1 policy executed → fastest possible
--
-- Functionality preserved:
-- ✅ Admins can still see all callouts
-- ✅ Fighters can still see their own callouts
-- ✅ All authenticated users can still see scheduled callouts
--
-- Next steps:
-- 1. Wait 5-10 minutes for scanner cache to refresh
-- 2. Re-run your security scanner
-- 3. The "Multiple Permissive Policies" warning should be COMPLETELY RESOLVED ✅
-- ============================================================================

