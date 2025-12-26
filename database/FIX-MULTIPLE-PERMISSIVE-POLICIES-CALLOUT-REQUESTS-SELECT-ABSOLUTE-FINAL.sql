-- ============================================================================
-- FIX: Multiple Permissive Policies on public.callout_requests (authenticated SELECT)
-- ABSOLUTE FINAL CONSOLIDATION - Single Policy Approach
-- ============================================================================
-- Issue: Table public.callout_requests has multiple permissive policies for
--        role authenticated for action SELECT. Policies include
--        {"Admins can view all callouts","Authenticated users can view callouts"}
--
-- Solution: Drop ALL authenticated SELECT policies and create a SINGLE
--           consolidated policy that handles all cases. Do NOT create any
--           separate admin SELECT policy.
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

-- Step 2: Drop ALL existing authenticated SELECT policies
DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE 'STEP 1: Dropping ALL authenticated SELECT policies on callout_requests...';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
END $$;

-- Drop ALL existing authenticated SELECT policies (including the consolidated one if it exists)
DROP POLICY IF EXISTS "Fighters can view own callouts" ON public.callout_requests;
DROP POLICY IF EXISTS "Admins can view all callouts" ON public.callout_requests;
DROP POLICY IF EXISTS "Authenticated users can view callout requests" ON public.callout_requests;
DROP POLICY IF EXISTS "Authenticated users can view scheduled callouts" ON public.callout_requests;
DROP POLICY IF EXISTS "Authenticated users can view callouts" ON public.callout_requests;
DROP POLICY IF EXISTS "Anyone can view scheduled callouts" ON public.callout_requests;

-- Drop the FOR ALL policy if it exists (it might be causing conflicts)
DROP POLICY IF EXISTS "Admins can manage all callouts" ON public.callout_requests;

DO $$
BEGIN
  RAISE NOTICE '✅ Dropped all existing authenticated SELECT policies.';
END $$;

-- Step 3: Create a SINGLE consolidated SELECT policy
-- This policy handles ALL cases: fighters, admins, and scheduled callouts
DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE 'STEP 2: Creating SINGLE consolidated SELECT policy...';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '   This single policy handles: fighters, admins, and scheduled callouts';
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
    CREATE POLICY "Authenticated users can view callouts" ON public.callout_requests
      FOR SELECT
      TO authenticated
      USING (
        -- Case 1: Fighters can view callouts where they are caller or target
        caller_id IN (
          SELECT id FROM fighter_profiles 
          WHERE user_id = (select auth.uid())
        ) OR
        target_id IN (
          SELECT id FROM fighter_profiles 
          WHERE user_id = (select auth.uid())
        )
        OR
        -- Case 2: Admins can view all callouts
        is_admin_user()
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
        -- Case 1: Fighters can view callouts where they are caller or target
        caller_id IN (
          SELECT id FROM fighter_profiles 
          WHERE user_id = (select auth.uid())
        ) OR
        target_id IN (
          SELECT id FROM fighter_profiles 
          WHERE user_id = (select auth.uid())
        )
        OR
        -- Case 2: Admins can view all callouts
        EXISTS (
          SELECT 1 FROM profiles
          WHERE id = (select auth.uid())
          AND role = 'admin'
        )
        OR
        -- Case 3: All authenticated users can view scheduled callouts
        status = 'scheduled'
      );
    
    RAISE NOTICE '✅ Created single consolidated SELECT policy using profiles table check.';
  END IF;
END $$;

-- Step 4: Ensure admin policies for other actions (INSERT, UPDATE, DELETE) exist
-- CRITICAL: Do NOT create a SELECT policy here - that's handled by the consolidated policy above
DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE 'STEP 3: Ensuring admin policies for INSERT, UPDATE, DELETE exist...';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '   NOTE: We do NOT create a SELECT policy here - that''s handled above';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
END $$;

-- Check if admin policies for other actions exist, create them if not
-- NOTE: We explicitly do NOT create a SELECT policy here
DO $$
BEGIN
  -- Check if is_admin_user function exists
  IF EXISTS (
    SELECT 1 FROM pg_proc 
    WHERE proname = 'is_admin_user' 
    AND pronamespace = 'public'::regnamespace
  ) THEN
    -- Use is_admin_user function for INSERT, UPDATE, DELETE (NOT SELECT)
    IF NOT EXISTS (
      SELECT 1 FROM pg_policies
      WHERE schemaname = 'public'
        AND tablename = 'callout_requests'
        AND policyname = 'Admins can insert callouts'
        AND cmd = 'INSERT'
        AND 'authenticated' = ANY(roles)
    ) THEN
      CREATE POLICY "Admins can insert callouts" ON public.callout_requests
        FOR INSERT
        TO authenticated
        WITH CHECK (is_admin_user());
      RAISE NOTICE '✅ Created admin INSERT policy.';
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
    -- Fallback: check profiles table for INSERT, UPDATE, DELETE (NOT SELECT)
    IF NOT EXISTS (
      SELECT 1 FROM pg_policies
      WHERE schemaname = 'public'
        AND tablename = 'callout_requests'
        AND policyname = 'Admins can insert callouts'
        AND cmd = 'INSERT'
        AND 'authenticated' = ANY(roles)
    ) THEN
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
      RAISE NOTICE '✅ Created admin INSERT policy.';
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

-- Step 5: Final verification - ensure only 1 SELECT policy exists
DO $$
DECLARE
  auth_select_policies_count INTEGER;
  auth_all_policies_count INTEGER;
  consolidated_policy_exists BOOLEAN;
  admins_select_policy_exists BOOLEAN;
  all_checks_pass BOOLEAN := true;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE 'STEP 4: Verifying policies on callout_requests...';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  
  -- Count authenticated SELECT policies (should be exactly 1)
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

  -- Check if the consolidated policy exists
  SELECT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'callout_requests'
      AND policyname = 'Authenticated users can view callouts'
      AND cmd = 'SELECT'
      AND 'authenticated' = ANY(roles)
  ) INTO consolidated_policy_exists;

  -- Check if "Admins can view all callouts" still exists (should be false)
  SELECT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'callout_requests'
      AND policyname = 'Admins can view all callouts'
      AND cmd = 'SELECT'
      AND 'authenticated' = ANY(roles)
  ) INTO admins_select_policy_exists;

  RAISE NOTICE '  - Authenticated SELECT Policies Count: %', auth_select_policies_count;
  RAISE NOTICE '  - Authenticated FOR ALL Policies Count: %', auth_all_policies_count;
  RAISE NOTICE '  - Consolidated Policy Exists: %', CASE WHEN consolidated_policy_exists THEN '✅ YES' ELSE '❌ NO' END;
  RAISE NOTICE '  - "Admins can view all callouts" Still Exists: %', CASE WHEN admins_select_policy_exists THEN '❌ YES (BAD!)' ELSE '✅ NO (GOOD!)' END;

  IF auth_select_policies_count = 1 THEN
    RAISE NOTICE '✅ Authenticated SELECT policies consolidated successfully (1 policy).';
  ELSE
    RAISE WARNING '❌ Authenticated SELECT policies count is % (expected 1). Review policies.', auth_select_policies_count;
    all_checks_pass := false;
  END IF;

  IF auth_all_policies_count = 0 THEN
    RAISE NOTICE '✅ No FOR ALL policies found (correct).';
  ELSE
    RAISE WARNING '⚠️  FOR ALL policies still exist (count: %). These may cause conflicts.', auth_all_policies_count;
  END IF;

  IF consolidated_policy_exists THEN
    RAISE NOTICE '✅ Consolidated SELECT policy exists.';
  ELSE
    RAISE WARNING '❌ Consolidated SELECT policy was not created.';
    all_checks_pass := false;
  END IF;

  IF admins_select_policy_exists THEN
    RAISE WARNING '❌ "Admins can view all callouts" policy still exists! This will cause conflicts.';
    RAISE WARNING '   This policy should NOT exist - admins are handled by the consolidated policy.';
    RAISE WARNING '   Please manually drop this policy or re-run this script.';
    all_checks_pass := false;
  ELSE
    RAISE NOTICE '✅ "Admins can view all callouts" policy does not exist (correct).';
  END IF;

  IF all_checks_pass AND auth_select_policies_count = 1 AND NOT admins_select_policy_exists THEN
    RAISE NOTICE '';
    RAISE NOTICE '✅ ✅ ✅ POLICIES CONSOLIDATED! ✅ ✅ ✅';
    RAISE NOTICE 'The "Multiple Permissive Policies" warning for authenticated SELECT on callout_requests should be RESOLVED.';
    RAISE NOTICE 'All functionality is preserved in a single policy.';
    RAISE NOTICE 'Please re-run your security scanner.';
  ELSE
    RAISE WARNING '';
    RAISE WARNING '⚠️  ⚠️  ⚠️  CONSOLIDATION FAILED ⚠️  ⚠️  ⚠️';
    RAISE WARNING 'Review the output above and the FINAL_POLICIES output below.';
  END IF;
END $$;

-- Step 6: Show final policy list for verification
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
-- Multiple permissive policies for authenticated SELECT on callout_requests
-- have been COMPLETELY CONSOLIDATED into a SINGLE policy:
--
-- "Authenticated users can view callouts"
--
-- This single policy handles ALL three cases using OR logic:
-- 1. Fighters can view callouts where they are caller or target
-- 2. Admins can view all callouts
-- 3. All authenticated users can view scheduled callouts
--
-- Performance improvement:
-- - Before: 2 policies executed for each SELECT query → slower
-- - After: 1 policy executed → fastest possible
--
-- Functionality preserved:
-- ✅ Fighters can still see their own callouts
-- ✅ Admins can still see all callouts
-- ✅ All authenticated users can still see scheduled callouts
--
-- Important: This script explicitly does NOT create a separate "Admins can view all callouts"
--            policy. The consolidated policy handles admins along with fighters and scheduled callouts.
--
-- Next steps:
-- 1. Re-run your security scanner
-- 2. The "Multiple Permissive Policies" warning should be COMPLETELY RESOLVED ✅
-- ============================================================================

