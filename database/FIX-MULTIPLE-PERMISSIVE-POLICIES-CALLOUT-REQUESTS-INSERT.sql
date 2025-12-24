-- ============================================================================
-- FIX: Multiple Permissive Policies on public.callout_requests (authenticated INSERT)
-- ============================================================================
-- Issue: Table public.callout_requests has multiple permissive policies for
--        role authenticated for action INSERT. Policies include
--        {"Admins can insert callouts","Fighters can create callouts"}
--
-- Solution: Consolidate these into a single policy that allows both fighters
--           and admins to insert callouts. This avoids multiple permissive
--           policies for the same role/action.
--
-- INSTRUCTIONS:
-- 1. Copy ALL content below (Ctrl+A, Ctrl+C)
-- 2. Go to: https://supabase.com/dashboard → Your Project → SQL Editor
-- 3. Paste the script (Ctrl+V)
-- 4. Click "Run" button (or press Ctrl+Enter)
-- 5. Review verification output
-- 6. Re-run your security scanner
-- ============================================================================

-- Step 1: Find all policies for authenticated role on callout_requests for INSERT
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
  AND (cmd = 'INSERT' OR cmd = 'ALL')
  AND ('authenticated' = ANY(roles) OR roles IS NULL)
ORDER BY policyname;

-- Step 2: Drop existing problematic INSERT policies
DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE 'STEP 1: Dropping existing INSERT policies on callout_requests...';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
END $$;

-- Drop the specific INSERT policies
DROP POLICY IF EXISTS "Fighters can create callouts" ON public.callout_requests;
DROP POLICY IF EXISTS "Admins can insert callouts" ON public.callout_requests;

-- Also drop the FOR ALL policy if it exists (it might be causing conflicts)
-- Note: We'll handle this separately if needed, but for now focus on INSERT
DROP POLICY IF EXISTS "Admins can manage all callouts" ON public.callout_requests;

DO $$
BEGIN
  RAISE NOTICE '✅ Dropped potentially conflicting INSERT policies.';
END $$;

-- Step 3: Create a single consolidated INSERT policy for authenticated role
-- This combines fighters and admins into one policy to avoid multiple permissive policies
DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE 'STEP 2: Creating consolidated INSERT policy for fighters and admins...';
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
    -- Use is_admin_user function
    CREATE POLICY "Fighters and admins can create callouts" ON public.callout_requests
      FOR INSERT
      TO authenticated
      WITH CHECK (
        -- Fighters can create callouts where they are the caller
        caller_id IN (
          SELECT id FROM fighter_profiles 
          WHERE user_id = (select auth.uid())
        )
        OR
        -- Admins can create any callout
        is_admin_user()
      );
    
    RAISE NOTICE '✅ Created consolidated INSERT policy using is_admin_user() function.';
  ELSE
    -- Fallback: check profiles table for admin role
    CREATE POLICY "Fighters and admins can create callouts" ON public.callout_requests
      FOR INSERT
      TO authenticated
      WITH CHECK (
        -- Fighters can create callouts where they are the caller
        caller_id IN (
          SELECT id FROM fighter_profiles 
          WHERE user_id = (select auth.uid())
        )
        OR
        -- Admins can create any callout
        EXISTS (
          SELECT 1 FROM profiles
          WHERE id = (select auth.uid())
          AND role = 'admin'
        )
      );
    
    RAISE NOTICE '✅ Created consolidated INSERT policy using profiles table check.';
  END IF;
END $$;

-- Step 4: Recreate admin policies for other actions (SELECT, UPDATE, DELETE) if needed
-- This ensures admins can still manage callouts, but INSERT is handled by the combined policy above
DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE 'STEP 3: Ensuring admin policies for SELECT, UPDATE, DELETE exist...';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
END $$;

-- Check if admin policies for other actions exist, create them if not
DO $$
BEGIN
  -- Check if is_admin_user function exists
  IF EXISTS (
    SELECT 1 FROM pg_proc 
    WHERE proname = 'is_admin_user' 
    AND pronamespace = 'public'::regnamespace
  ) THEN
    -- Use is_admin_user function for SELECT, UPDATE, DELETE
    IF NOT EXISTS (
      SELECT 1 FROM pg_policies
      WHERE schemaname = 'public'
        AND tablename = 'callout_requests'
        AND policyname = 'Admins can view all callouts'
        AND cmd = 'SELECT'
        AND 'authenticated' = ANY(roles)
    ) THEN
      CREATE POLICY "Admins can view all callouts" ON public.callout_requests
        FOR SELECT
        TO authenticated
        USING (is_admin_user());
      RAISE NOTICE '✅ Created admin SELECT policy.';
    END IF;
    
    IF NOT EXISTS (
      SELECT 1 FROM pg_policies
      WHERE schemaname = 'public'
        AND tablename = 'callout_requests'
        AND policyname = 'Admins can update callouts'
        AND cmd = 'UPDATE'
        AND 'authenticated' = ANY(roles)
    ) THEN
      CREATE POLICY "Admins can update callouts" ON public.callout_requests
        FOR UPDATE
        TO authenticated
        USING (is_admin_user())
        WITH CHECK (is_admin_user());
      RAISE NOTICE '✅ Created admin UPDATE policy.';
    END IF;
    
    IF NOT EXISTS (
      SELECT 1 FROM pg_policies
      WHERE schemaname = 'public'
        AND tablename = 'callout_requests'
        AND policyname = 'Admins can delete callouts'
        AND cmd = 'DELETE'
        AND 'authenticated' = ANY(roles)
    ) THEN
      CREATE POLICY "Admins can delete callouts" ON public.callout_requests
        FOR DELETE
        TO authenticated
        USING (is_admin_user());
      RAISE NOTICE '✅ Created admin DELETE policy.';
    END IF;
  ELSE
    -- Fallback: check profiles table
    IF NOT EXISTS (
      SELECT 1 FROM pg_policies
      WHERE schemaname = 'public'
        AND tablename = 'callout_requests'
        AND policyname = 'Admins can view all callouts'
        AND cmd = 'SELECT'
        AND 'authenticated' = ANY(roles)
    ) THEN
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
      RAISE NOTICE '✅ Created admin SELECT policy.';
    END IF;
    
    IF NOT EXISTS (
      SELECT 1 FROM pg_policies
      WHERE schemaname = 'public'
        AND tablename = 'callout_requests'
        AND policyname = 'Admins can update callouts'
        AND cmd = 'UPDATE'
        AND 'authenticated' = ANY(roles)
    ) THEN
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
      RAISE NOTICE '✅ Created admin UPDATE policy.';
    END IF;
    
    IF NOT EXISTS (
      SELECT 1 FROM pg_policies
      WHERE schemaname = 'public'
        AND tablename = 'callout_requests'
        AND policyname = 'Admins can delete callouts'
        AND cmd = 'DELETE'
        AND 'authenticated' = ANY(roles)
    ) THEN
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
      RAISE NOTICE '✅ Created admin DELETE policy.';
    END IF;
  END IF;
END $$;

-- Step 5: Verification
DO $$
DECLARE
  auth_insert_policies_count INTEGER;
  auth_all_policies_count INTEGER;
  consolidated_policy_exists BOOLEAN;
  all_checks_pass BOOLEAN := true;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE 'STEP 4: Verifying policies on callout_requests...';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  
  -- Count authenticated INSERT policies
  SELECT COUNT(*) INTO auth_insert_policies_count
  FROM pg_policies
  WHERE schemaname = 'public'
    AND tablename = 'callout_requests'
    AND cmd = 'INSERT'
    AND 'authenticated' = ANY(roles);

  -- Count authenticated FOR ALL policies (should be 0)
  SELECT COUNT(*) INTO auth_all_policies_count
  FROM pg_policies
  WHERE schemaname = 'public'
    AND tablename = 'callout_requests'
    AND cmd = 'ALL'
    AND ('authenticated' = ANY(roles) OR roles IS NULL);

  -- Check if the consolidated policy exists
  SELECT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'callout_requests'
      AND policyname = 'Fighters and admins can create callouts'
      AND cmd = 'INSERT'
      AND 'authenticated' = ANY(roles)
  ) INTO consolidated_policy_exists;

  RAISE NOTICE '  - Authenticated INSERT Policies Count: %', auth_insert_policies_count;
  RAISE NOTICE '  - Authenticated FOR ALL Policies Count: %', auth_all_policies_count;
  RAISE NOTICE '  - Consolidated Policy Exists: %', CASE WHEN consolidated_policy_exists THEN '✅ YES' ELSE '❌ NO' END;

  IF auth_insert_policies_count = 1 THEN
    RAISE NOTICE '✅ Authenticated INSERT policies consolidated successfully.';
  ELSE
    RAISE WARNING '❌ Authenticated INSERT policies count is % (expected 1). Review policies.', auth_insert_policies_count;
    all_checks_pass := false;
  END IF;

  IF auth_all_policies_count = 0 THEN
    RAISE NOTICE '✅ No FOR ALL policies found (correct).';
  ELSE
    RAISE WARNING '⚠️  FOR ALL policies still exist (count: %). These may cause conflicts.', auth_all_policies_count;
    RAISE WARNING '   Consider running FIX-MULTIPLE-PERMISSIVE-POLICIES-CALLOUT-REQUESTS-DELETE.sql';
  END IF;

  IF consolidated_policy_exists THEN
    RAISE NOTICE '✅ Consolidated INSERT policy exists.';
  ELSE
    RAISE WARNING '❌ Consolidated INSERT policy was not created.';
    all_checks_pass := false;
  END IF;

  IF all_checks_pass THEN
    RAISE NOTICE '';
    RAISE NOTICE '✅ ✅ ✅ POLICIES CONSOLIDATED! ✅ ✅ ✅';
    RAISE NOTICE 'The "Multiple Permissive Policies" warning for authenticated INSERT on callout_requests should be resolved.';
    RAISE NOTICE 'Please re-run your security scanner.';
  ELSE
    RAISE WARNING '';
    RAISE WARNING '⚠️  ⚠️  ⚠️  CONSOLIDATION FAILED ⚠️  ⚠️  ⚠️';
    RAISE WARNING 'Review the output above and try running the script again.';
  END IF;
END $$;

-- Step 6: Show final policy list for verification
SELECT 
  'FINAL_POLICIES' as check_type,
  policyname,
  cmd as command_type,
  roles,
  qual as using_clause,
  with_check as with_check_clause
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
-- Multiple permissive policies for authenticated INSERT on callout_requests
-- have been consolidated by:
-- 1. Dropping "Fighters can create callouts" INSERT policy
-- 2. Dropping "Admins can insert callouts" INSERT policy
-- 3. Creating a single consolidated policy: "Fighters and admins can create callouts"
-- 4. Ensuring admin policies for other actions (SELECT, UPDATE, DELETE) exist
--
-- Performance improvement:
-- - Before: Multiple policies executed for each INSERT query → slower
-- - After: Single INSERT policy executed → faster
--
-- Note: The consolidated policy allows:
--       - Fighters to create callouts where they are the caller
--       - Admins to create any callout
--       This avoids multiple permissive policies for the same role/action.
--
-- Next steps:
-- 1. Re-run your security scanner
-- 2. Performance warning should be resolved ✅
-- ============================================================================

