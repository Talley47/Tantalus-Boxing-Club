-- ============================================================================
-- 🔧 DEFINITIVE FIX: Resolve RLS Blocking on fighter_profiles
-- ============================================================================
-- This script fixes ALL possible causes of RLS blocking:
-- 1. Missing GRANT permissions (schema USAGE + table SELECT)
-- 2. Missing or incorrect RLS policies
-- 3. RLS not enabled (security scanner requirement)
--
-- RUN THIS IN SUPABASE SQL EDITOR
-- ============================================================================

-- ============================================================================
-- STEP 1: Grant Schema USAGE (CRITICAL - often missing!)
-- ============================================================================
-- This allows roles to access the public schema
GRANT USAGE ON SCHEMA public TO anon, authenticated;

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE 'STEP 1: Schema USAGE granted ✅';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
END $$;

-- ============================================================================
-- STEP 2: Grant Table SELECT Permissions (CRITICAL - separate from RLS!)
-- ============================================================================
-- This allows roles to query the table (RLS will still filter rows)
GRANT SELECT ON TABLE public.fighter_profiles TO anon, authenticated;

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE 'STEP 2: Table SELECT permissions granted ✅';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
END $$;

-- ============================================================================
-- STEP 3: Enable RLS (Required by security scanner)
-- ============================================================================
ALTER TABLE public.fighter_profiles ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE 'STEP 3: RLS enabled ✅';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
END $$;

-- ============================================================================
-- STEP 4: Drop ALL existing policies (clean slate)
-- ============================================================================
DO $$ 
DECLARE 
  r RECORD;
  dropped_count INTEGER := 0;
BEGIN 
  FOR r IN 
    SELECT policyname 
    FROM pg_policies 
    WHERE schemaname = 'public' 
      AND tablename = 'fighter_profiles'
  LOOP 
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.fighter_profiles', r.policyname);
    dropped_count := dropped_count + 1;
    RAISE NOTICE '  Dropped policy: %', r.policyname;
  END LOOP;
  
  IF dropped_count = 0 THEN
    RAISE NOTICE '  No existing policies to drop';
  ELSE
    RAISE NOTICE '  Dropped % existing policy/policies', dropped_count;
  END IF;
END $$;

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE 'STEP 4: Existing policies dropped ✅';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
END $$;

-- ============================================================================
-- STEP 5: Create Permissive Policies for BOTH Roles
-- ============================================================================
-- CRITICAL: Homepage loads BEFORE login, so we need BOTH policies:
-- 1. anon policy (for homepage before login)
-- 2. authenticated policy (for logged-in users)

-- Policy for anonymous users (homepage before login)
CREATE POLICY "Anonymous users can view fighter profiles" 
ON public.fighter_profiles 
FOR SELECT 
TO anon 
USING (true);

-- Policy for authenticated users (logged-in users)
CREATE POLICY "Authenticated users can view fighter profiles" 
ON public.fighter_profiles 
FOR SELECT 
TO authenticated 
USING (true);

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE 'STEP 5: Permissive policies created ✅';
  RAISE NOTICE '  - anon: Can view all fighter profiles';
  RAISE NOTICE '  - authenticated: Can view all fighter profiles';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
END $$;

-- ============================================================================
-- STEP 6: VERIFICATION - Test Access
-- ============================================================================
DO $$
DECLARE
  rls_enabled BOOLEAN;
  policy_count INTEGER;
  grant_count INTEGER;
  schema_usage_count INTEGER;
  data_exists BOOLEAN;
  anon_can_see INTEGER;
  auth_can_see INTEGER;
  all_checks_pass BOOLEAN := true;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '                    VERIFICATION RESULTS';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '';
  
  -- Check RLS enabled
  SELECT rowsecurity INTO rls_enabled
  FROM pg_tables 
  WHERE schemaname = 'public' AND tablename = 'fighter_profiles';
  
  IF rls_enabled THEN
    RAISE NOTICE '✅ RLS Enabled: YES';
  ELSE
    RAISE WARNING '❌ RLS Enabled: NO';
    all_checks_pass := false;
  END IF;
  
  -- Check policy count
  SELECT COUNT(*) INTO policy_count
  FROM pg_policies 
  WHERE schemaname = 'public' AND tablename = 'fighter_profiles';
  
  IF policy_count >= 2 THEN
    RAISE NOTICE '✅ Policies: % (need 2)', policy_count;
  ELSE
    RAISE WARNING '❌ Policies: % (need 2)', policy_count;
    all_checks_pass := false;
  END IF;
  
  -- Check grants
  SELECT COUNT(*) INTO grant_count
  FROM information_schema.table_privileges
  WHERE table_schema = 'public' 
    AND table_name = 'fighter_profiles'
    AND privilege_type = 'SELECT'
    AND grantee IN ('anon', 'authenticated');
  
  IF grant_count >= 2 THEN
    RAISE NOTICE '✅ SELECT Grants: % (need 2)', grant_count;
  ELSE
    RAISE WARNING '❌ SELECT Grants: % (need 2)', grant_count;
    all_checks_pass := false;
  END IF;
  
  -- Check schema usage
  SELECT COUNT(*) INTO schema_usage_count
  FROM information_schema.usage_privileges
  WHERE object_schema = 'public' 
    AND grantee IN ('anon', 'authenticated');
  
  IF schema_usage_count >= 2 THEN
    RAISE NOTICE '✅ Schema USAGE Grants: % (need 2)', schema_usage_count;
  ELSE
    RAISE WARNING '❌ Schema USAGE Grants: % (need 2)', schema_usage_count;
    all_checks_pass := false;
  END IF;
  
  -- Check if data exists
  SET ROLE postgres;
  SELECT COUNT(*) > 0 INTO data_exists FROM public.fighter_profiles;
  RESET ROLE;
  
  IF data_exists THEN
    RAISE NOTICE '✅ Data Exists: YES';
  ELSE
    RAISE WARNING '❌ Data Exists: NO (table is empty)';
    all_checks_pass := false;
  END IF;
  
  -- Test anon access
  SET ROLE anon;
  SELECT COUNT(*) INTO anon_can_see FROM public.fighter_profiles;
  RESET ROLE;
  
  IF anon_can_see > 0 OR NOT data_exists THEN
    RAISE NOTICE '✅ Anon Can See: % rows', anon_can_see;
  ELSE
    RAISE WARNING '❌ Anon Can See: 0 rows (RLS still blocking!)';
    all_checks_pass := false;
  END IF;
  
  -- Test authenticated access
  SET ROLE authenticated;
  SELECT COUNT(*) INTO auth_can_see FROM public.fighter_profiles;
  RESET ROLE;
  
  IF auth_can_see > 0 OR NOT data_exists THEN
    RAISE NOTICE '✅ Authenticated Can See: % rows', auth_can_see;
  ELSE
    RAISE WARNING '❌ Authenticated Can See: 0 rows (RLS still blocking!)';
    all_checks_pass := false;
  END IF;
  
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  
  IF all_checks_pass THEN
    RAISE NOTICE '✅ ✅ ✅ ALL CHECKS PASSED! ✅ ✅ ✅';
    RAISE NOTICE '';
    RAISE NOTICE 'The RLS blocking issue should be RESOLVED!';
    RAISE NOTICE '';
    RAISE NOTICE 'NEXT STEPS:';
    RAISE NOTICE '  1. Hard refresh your browser (Ctrl+Shift+R)';
    RAISE NOTICE '  2. Check your homepage - fighters should appear!';
    RAISE NOTICE '  3. If still not working, check browser console for errors';
  ELSE
    RAISE WARNING '⚠️  ⚠️  ⚠️  SOME CHECKS FAILED ⚠️  ⚠️  ⚠️';
    RAISE WARNING '';
    RAISE WARNING 'Review the errors above and try running this script again.';
    RAISE WARNING 'If issues persist, share the verification output.';
  END IF;
  
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
END $$;

-- ============================================================================
-- ✅ FIX COMPLETE
-- ============================================================================
-- If verification shows all checks passed:
-- 1. Hard refresh your browser (Ctrl+Shift+R)
-- 2. Check your homepage - fighters should appear!
-- 3. The "NO FIGHTERS RETURNED FROM QUERY" error should be gone
--
-- If verification shows failures:
-- - Review the error messages above
-- - Try running this script again
-- - Share the verification output if issues persist
-- ============================================================================

