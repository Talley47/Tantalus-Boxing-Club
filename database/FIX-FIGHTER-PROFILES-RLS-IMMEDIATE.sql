-- ============================================================================
-- 🚨 IMMEDIATE FIX: Enable fighter_profiles Access for All Users
-- ============================================================================
-- Issue: RLS policies are blocking access to fighter_profiles table
--        Query succeeds (HTTP 200) but returns 0 rows
--
-- Solution: Grant SELECT permissions and create permissive RLS policies
--           for both authenticated and anonymous users
--
-- INSTRUCTIONS:
-- 1. Copy ALL content below (Ctrl+A, Ctrl+C)
-- 2. Go to: https://supabase.com/dashboard → Your Project → SQL Editor
-- 3. Paste the script (Ctrl+V)
-- 4. Click "Run" button (or press Ctrl+Enter)
-- 5. Hard refresh your app (Ctrl+Shift+R)
-- 6. Fighters should appear immediately!
--
-- ============================================================================

BEGIN;

-- Step 1: Grant schema and table permissions (required before RLS policies work)
DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '🔧 STEP 1: Granting schema and table permissions...';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
END $$;

GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT ON TABLE public.fighter_profiles TO anon, authenticated;

-- Step 2: Enable RLS (keep it enabled for security)
DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '🔧 STEP 2: Enabling Row Level Security...';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
END $$;

ALTER TABLE public.fighter_profiles ENABLE ROW LEVEL SECURITY;

-- Step 3: Drop ALL existing SELECT policies (clean slate)
DO $$
DECLARE
  r RECORD;
  dropped_count INTEGER := 0;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '🔧 STEP 3: Dropping existing SELECT policies...';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  
  FOR r IN
    SELECT policyname
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'fighter_profiles'
      AND (cmd = 'SELECT' OR cmd = 'ALL')
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.fighter_profiles', r.policyname);
    RAISE NOTICE '  ✅ Dropped policy: %', r.policyname;
    dropped_count := dropped_count + 1;
  END LOOP;
  
  IF dropped_count = 0 THEN
    RAISE NOTICE '  ℹ️  No existing SELECT policies to drop';
  ELSE
    RAISE NOTICE '  ✅ Dropped % policy/policies', dropped_count;
  END IF;
END $$;

-- Step 4: Create permissive SELECT policies for BOTH roles
DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '🔧 STEP 4: Creating new permissive SELECT policies...';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
END $$;

-- Policy for authenticated users (logged in)
CREATE POLICY "Authenticated users can view fighter profiles"
ON public.fighter_profiles
FOR SELECT
TO authenticated
USING (true);

-- Policy for anonymous users (not logged in)
-- REQUIRED because homepage loads before login
CREATE POLICY "Anonymous users can view fighter profiles"
ON public.fighter_profiles
FOR SELECT
TO anon
USING (true);

DO $$
BEGIN
  RAISE NOTICE '  ✅ Created policy: "Authenticated users can view fighter profiles"';
  RAISE NOTICE '  ✅ Created policy: "Anonymous users can view fighter profiles"';
END $$;

-- Step 5: Verification
DO $$
DECLARE
  policy_count INTEGER;
  authenticated_exists BOOLEAN;
  anon_exists BOOLEAN;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '                    VERIFICATION';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  
  -- Count SELECT policies
  SELECT COUNT(*) INTO policy_count
  FROM pg_policies
  WHERE schemaname = 'public'
    AND tablename = 'fighter_profiles'
    AND cmd = 'SELECT';
  
  -- Check if both policies exist
  SELECT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'fighter_profiles'
      AND policyname = 'Authenticated users can view fighter profiles'
      AND cmd = 'SELECT'
  ) INTO authenticated_exists;
  
  SELECT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'fighter_profiles'
      AND policyname = 'Anonymous users can view fighter profiles'
      AND cmd = 'SELECT'
  ) INTO anon_exists;
  
  RAISE NOTICE '';
  RAISE NOTICE '  📊 SELECT Policies Count: %', policy_count;
  RAISE NOTICE '  ✅ Authenticated policy exists: %', CASE WHEN authenticated_exists THEN 'YES' ELSE 'NO' END;
  RAISE NOTICE '  ✅ Anonymous policy exists: %', CASE WHEN anon_exists THEN 'YES' ELSE 'NO' END;
  RAISE NOTICE '';
  
  IF policy_count >= 2 AND authenticated_exists AND anon_exists THEN
    RAISE NOTICE '  ✅ ✅ ✅ FIX SUCCESSFUL! ✅ ✅ ✅';
    RAISE NOTICE '';
    RAISE NOTICE '  Next steps:';
    RAISE NOTICE '    1. Hard refresh your app (Ctrl+Shift+R)';
    RAISE NOTICE '    2. Fighters should appear on homepage immediately!';
  ELSE
    RAISE WARNING '  ⚠️  Verification failed. Please review the output above.';
  END IF;
  
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
END $$;

-- Show final policy list
SELECT 
  'FINAL_POLICIES' as check_type,
  policyname,
  cmd as command_type,
  roles,
  qual as using_clause
FROM pg_policies
WHERE schemaname = 'public' 
  AND tablename = 'fighter_profiles'
ORDER BY cmd, policyname;

COMMIT;

-- ============================================================================
-- ✅ FIX COMPLETE
-- ============================================================================
-- RLS policies have been configured to allow both authenticated and
-- anonymous users to read fighter_profiles.
--
-- What was fixed:
-- ✅ Granted schema and table permissions to anon and authenticated roles
-- ✅ Enabled Row Level Security (kept enabled for security)
-- ✅ Dropped all existing SELECT policies (clean slate)
-- ✅ Created permissive SELECT policies for both roles
--
-- Security note:
-- These policies allow READ access only. Users can view fighter profiles
-- but cannot modify them without additional policies.
--
-- Next steps:
-- 1. Hard refresh your app (Ctrl+Shift+R)
-- 2. Fighters should appear on homepage immediately!
-- 3. If still not working, check browser console for errors
-- ============================================================================

