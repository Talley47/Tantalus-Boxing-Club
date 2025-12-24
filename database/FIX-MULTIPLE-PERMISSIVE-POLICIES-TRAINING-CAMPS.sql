-- ============================================================================
-- FIX: Multiple Permissive Policies on public.training_camps (anon SELECT)
-- ============================================================================
-- Issue: Table public.training_camps has multiple permissive policies for
--        role anon for action SELECT. Policies include
--        {"Public can view training camps","Users can view all training camps"}
--
-- Solution: Consolidate these into a single, clear policy for anon SELECT.
--           Ensure authenticated users have a separate, appropriate policy.
--
-- INSTRUCTIONS:
-- 1. Copy ALL content below (Ctrl+A, Ctrl+C)
-- 2. Go to: https://supabase.com/dashboard → Your Project → SQL Editor
-- 3. Paste the script (Ctrl+V)
-- 4. Click "Run" button (or press Ctrl+Enter)
-- 5. Review verification output
-- 6. Re-run your security scanner
-- ============================================================================

-- Step 1: Find all policies for anon role on training_camps for SELECT
SELECT 
  'POLICIES_TO_CONSOLIDATE' as check_type,
  policyname,
  cmd as command_type,
  roles,
  qual as using_clause,
  with_check as with_check_clause
FROM pg_policies
WHERE schemaname = 'public' 
  AND tablename = 'training_camps'
  AND cmd = 'SELECT'
  AND ('anon' = ANY(roles) OR roles IS NULL)
ORDER BY policyname;

-- Step 2: Drop existing problematic policies for anon SELECT
DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE 'STEP 1: Dropping existing anon SELECT policies on training_camps...';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
END $$;

DROP POLICY IF EXISTS "Public can view training camps" ON public.training_camps;
DROP POLICY IF EXISTS "Users can view all training camps" ON public.training_camps;
DROP POLICY IF EXISTS "Training camps are publicly viewable" ON public.training_camps; -- Also drop this common variant
DROP POLICY IF EXISTS "Anyone can view training camps" ON public.training_camps; -- Also drop this common variant

DO $$
BEGIN
  RAISE NOTICE '✅ Dropped potentially conflicting anon SELECT policies.';
END $$;

-- Step 3: Create a single, consolidated policy for anon SELECT
DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE 'STEP 2: Creating consolidated anon SELECT policy on training_camps...';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
END $$;

-- This policy allows anonymous users to view all training camps.
CREATE POLICY "Public can view training camps"
ON public.training_camps
FOR SELECT
TO anon
USING (true);

DO $$
BEGIN
  RAISE NOTICE '✅ Created consolidated policy: "Public can view training camps" for anon.';
END $$;

-- Step 4: Ensure authenticated users have a separate policy (if needed)
DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE 'STEP 3: Ensuring authenticated SELECT policy on training_camps...';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
END $$;

-- Drop any old authenticated policies that might conflict
DROP POLICY IF EXISTS "Authenticated can view training camps" ON public.training_camps;
DROP POLICY IF EXISTS "Users can view own training camps" ON public.training_camps;

-- Create a general authenticated SELECT policy if it doesn't exist
-- This ensures authenticated users can view all training camps, without conflicting with anon policy
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'training_camps'
      AND policyname = 'Authenticated can view training camps'
      AND cmd = 'SELECT'
      AND 'authenticated' = ANY(roles)
  ) THEN
    CREATE POLICY "Authenticated can view training camps"
    ON public.training_camps
    FOR SELECT
    TO authenticated
    USING (true); -- Authenticated users also see all training camps
    RAISE NOTICE '✅ Created policy: "Authenticated can view training camps"';
  ELSE
    RAISE NOTICE 'ℹ️ Policy "Authenticated can view training camps" already exists.';
  END IF;
END $$;

-- Step 5: Verification
DO $$
DECLARE
  anon_select_policies_count INTEGER;
  auth_select_policies_count INTEGER;
  all_checks_pass BOOLEAN := true;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE 'STEP 4: Verifying policies on training_camps...';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  
  -- Count anon SELECT policies
  SELECT COUNT(*) INTO anon_select_policies_count
  FROM pg_policies
  WHERE schemaname = 'public'
    AND tablename = 'training_camps'
    AND cmd = 'SELECT'
    AND 'anon' = ANY(roles);

  -- Count authenticated SELECT policies
  SELECT COUNT(*) INTO auth_select_policies_count
  FROM pg_policies
  WHERE schemaname = 'public'
    AND tablename = 'training_camps'
    AND cmd = 'SELECT'
    AND 'authenticated' = ANY(roles);

  RAISE NOTICE '  - Anon SELECT Policies Count: %', anon_select_policies_count;
  RAISE NOTICE '  - Authenticated SELECT Policies Count: %', auth_select_policies_count;

  IF anon_select_policies_count = 1 THEN
    RAISE NOTICE '✅ Anon SELECT policies consolidated successfully.';
  ELSE
    RAISE WARNING '❌ Anon SELECT policies count is % (expected 1). Review policies.', anon_select_policies_count;
    all_checks_pass := false;
  END IF;

  IF auth_select_policies_count >= 1 THEN -- At least one authenticated policy is expected
    RAISE NOTICE '✅ Authenticated SELECT policies exist.';
  ELSE
    RAISE WARNING '❌ No authenticated SELECT policies found. Review policies.';
    all_checks_pass := false;
  END IF;

  IF all_checks_pass THEN
    RAISE NOTICE '';
    RAISE NOTICE '✅ ✅ ✅ POLICIES CONSOLIDATED! ✅ ✅ ✅';
    RAISE NOTICE 'The "Multiple Permissive Policies" warning for anon SELECT on training_camps should be resolved.';
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
  qual as using_clause
FROM pg_policies
WHERE schemaname = 'public' 
  AND tablename = 'training_camps'
  AND cmd = 'SELECT'
ORDER BY roles, policyname;

DO $$
BEGIN
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
END $$;

-- ============================================================================
-- FIX COMPLETE
-- ============================================================================

