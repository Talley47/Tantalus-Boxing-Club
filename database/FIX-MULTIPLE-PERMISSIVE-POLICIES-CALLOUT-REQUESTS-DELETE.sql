-- ============================================================================
-- FIX: Multiple Permissive Policies on public.callout_requests (authenticated DELETE)
-- ============================================================================
-- Issue: Table public.callout_requests has multiple permissive policies for
--        role authenticated for action DELETE. Policies include
--        {"Admins can delete callouts","Admins can manage all callouts"}
--
-- Solution: Consolidate these by dropping the FOR ALL policy and creating
--           separate policies for each action (SELECT, INSERT, UPDATE, DELETE).
--           This ensures no duplicate permissive policies for the same role/action.
--
-- INSTRUCTIONS:
-- 1. Copy ALL content below (Ctrl+A, Ctrl+C)
-- 2. Go to: https://supabase.com/dashboard → Your Project → SQL Editor
-- 3. Paste the script (Ctrl+V)
-- 4. Click "Run" button (or press Ctrl+Enter)
-- 5. Review verification output
-- 6. Re-run your security scanner
-- ============================================================================

-- Step 1: Find all policies for authenticated role on callout_requests for DELETE
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
  AND (cmd = 'DELETE' OR cmd = 'ALL')
  AND ('authenticated' = ANY(roles) OR roles IS NULL)
ORDER BY policyname;

-- Step 2: Drop existing problematic policies
DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE 'STEP 1: Dropping existing admin policies on callout_requests...';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
END $$;

-- Drop the FOR ALL policy (this is causing the duplicate DELETE policy)
DROP POLICY IF EXISTS "Admins can manage all callouts" ON public.callout_requests;

-- Drop the specific DELETE policy
DROP POLICY IF EXISTS "Admins can delete callouts" ON public.callout_requests;

-- Also drop any other admin policies that might exist (we'll recreate them properly)
DROP POLICY IF EXISTS "Admins can insert callouts" ON public.callout_requests;
DROP POLICY IF EXISTS "Admins can update callouts" ON public.callout_requests;
DROP POLICY IF EXISTS "Admins can view all callouts" ON public.callout_requests;

DO $$
BEGIN
  RAISE NOTICE '✅ Dropped potentially conflicting admin policies.';
END $$;

-- Step 3: Create separate admin policies for each action (SELECT, INSERT, UPDATE, DELETE)
-- This ensures no duplicate permissive policies for the same role/action
DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE 'STEP 2: Creating separate admin policies for each action...';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
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
    -- Use is_admin_user function for all admin policies
    CREATE POLICY "Admins can view all callouts" ON public.callout_requests
      FOR SELECT
      TO authenticated
      USING (is_admin_user());
    
    CREATE POLICY "Admins can insert callouts" ON public.callout_requests
      FOR INSERT
      TO authenticated
      WITH CHECK (is_admin_user());
    
    CREATE POLICY "Admins can update callouts" ON public.callout_requests
      FOR UPDATE
      TO authenticated
      USING (is_admin_user())
      WITH CHECK (is_admin_user());
    
    CREATE POLICY "Admins can delete callouts" ON public.callout_requests
      FOR DELETE
      TO authenticated
      USING (is_admin_user());
    
    RAISE NOTICE '✅ Created admin policies using is_admin_user() function.';
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
    
    CREATE POLICY "Admins can insert callouts" ON public.callout_requests
      FOR INSERT
      TO authenticated
      WITH CHECK (
        EXISTS (
          SELECT 1 FROM profiles
          WHERE id = (select auth.uid())
          AND role = 'admin'
        )
      );
    
    CREATE POLICY "Admins can update callouts" ON public.callout_requests
      FOR UPDATE
      TO authenticated
      USING (
        EXISTS (
          SELECT 1 FROM profiles
          WHERE id = (select auth.uid())
          AND role = 'admin'
        )
      )
      WITH CHECK (
        EXISTS (
          SELECT 1 FROM profiles
          WHERE id = (select auth.uid())
          AND role = 'admin'
        )
      );
    
    CREATE POLICY "Admins can delete callouts" ON public.callout_requests
      FOR DELETE
      TO authenticated
      USING (
        EXISTS (
          SELECT 1 FROM profiles
          WHERE id = (select auth.uid())
          AND role = 'admin'
        )
      );
    
    RAISE NOTICE '✅ Created admin policies using profiles table check.';
  END IF;
END $$;

-- Step 4: Verification
DO $$
DECLARE
  auth_delete_policies_count INTEGER;
  auth_all_policies_count INTEGER;
  admin_delete_policy_exists BOOLEAN;
  admin_all_policy_exists BOOLEAN;
  all_checks_pass BOOLEAN := true;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE 'STEP 3: Verifying policies on callout_requests...';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  
  -- Count authenticated DELETE policies
  SELECT COUNT(*) INTO auth_delete_policies_count
  FROM pg_policies
  WHERE schemaname = 'public'
    AND tablename = 'callout_requests'
    AND cmd = 'DELETE'
    AND 'authenticated' = ANY(roles);

  -- Count authenticated FOR ALL policies (should be 0)
  SELECT COUNT(*) INTO auth_all_policies_count
  FROM pg_policies
  WHERE schemaname = 'public'
    AND tablename = 'callout_requests'
    AND cmd = 'ALL'
    AND ('authenticated' = ANY(roles) OR roles IS NULL);

  -- Check if the specific admin DELETE policy exists
  SELECT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'callout_requests'
      AND policyname = 'Admins can delete callouts'
      AND cmd = 'DELETE'
      AND 'authenticated' = ANY(roles)
  ) INTO admin_delete_policy_exists;

  -- Check if the FOR ALL policy still exists (should be false)
  SELECT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'callout_requests'
      AND policyname = 'Admins can manage all callouts'
      AND cmd = 'ALL'
  ) INTO admin_all_policy_exists;

  RAISE NOTICE '  - Authenticated DELETE Policies Count: %', auth_delete_policies_count;
  RAISE NOTICE '  - Authenticated FOR ALL Policies Count: %', auth_all_policies_count;
  RAISE NOTICE '  - Admin DELETE Policy Exists: %', CASE WHEN admin_delete_policy_exists THEN '✅ YES' ELSE '❌ NO' END;
  RAISE NOTICE '  - FOR ALL Policy Removed: %', CASE WHEN NOT admin_all_policy_exists THEN '✅ YES' ELSE '❌ NO' END;

  IF auth_delete_policies_count = 1 THEN
    RAISE NOTICE '✅ Authenticated DELETE policies consolidated successfully.';
  ELSE
    RAISE WARNING '❌ Authenticated DELETE policies count is % (expected 1). Review policies.', auth_delete_policies_count;
    all_checks_pass := false;
  END IF;

  IF auth_all_policies_count = 0 THEN
    RAISE NOTICE '✅ No FOR ALL policies found (correct).';
  ELSE
    RAISE WARNING '❌ FOR ALL policies still exist (count: %). Review policies.', auth_all_policies_count;
    all_checks_pass := false;
  END IF;

  IF admin_delete_policy_exists THEN
    RAISE NOTICE '✅ Admin DELETE policy exists.';
  ELSE
    RAISE WARNING '❌ Admin DELETE policy was not created.';
    all_checks_pass := false;
  END IF;

  IF NOT admin_all_policy_exists THEN
    RAISE NOTICE '✅ FOR ALL policy removed successfully.';
  ELSE
    RAISE WARNING '❌ FOR ALL policy still exists.';
    all_checks_pass := false;
  END IF;

  IF all_checks_pass THEN
    RAISE NOTICE '';
    RAISE NOTICE '✅ ✅ ✅ POLICIES CONSOLIDATED! ✅ ✅ ✅';
    RAISE NOTICE 'The "Multiple Permissive Policies" warning for authenticated DELETE on callout_requests should be resolved.';
    RAISE NOTICE 'Please re-run your security scanner.';
  ELSE
    RAISE WARNING '';
    RAISE WARNING '⚠️  ⚠️  ⚠️  CONSOLIDATION FAILED ⚠️  ⚠️  ⚠️';
    RAISE WARNING 'Review the output above and try running the script again.';
  END IF;
END $$;

-- Step 5: Show final policy list for verification
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

DO $$
BEGIN
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
END $$;

-- ============================================================================
-- FIX COMPLETE
-- ============================================================================
-- Multiple permissive policies for authenticated DELETE on callout_requests
-- have been consolidated by:
-- 1. Dropping the "Admins can manage all callouts" FOR ALL policy
-- 2. Dropping the "Admins can delete callouts" DELETE policy
-- 3. Creating separate policies for SELECT, INSERT, UPDATE, DELETE
-- 4. Ensuring all admin policies are restricted to authenticated role
--
-- Performance improvement:
-- - Before: Multiple policies executed for each DELETE query → slower
-- - After: Single DELETE policy executed → faster
--
-- Note: Admins can still manage all callouts through the separate policies
--       for each action (SELECT, INSERT, UPDATE, DELETE). This approach
--       avoids multiple permissive policies for the same role/action.
--
-- Next steps:
-- 1. Re-run your security scanner
-- 2. Performance warning should be resolved ✅
-- ============================================================================

