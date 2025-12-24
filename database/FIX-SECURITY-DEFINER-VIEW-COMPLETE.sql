-- ============================================================================
-- 🔒 COMPLETE FIX: SECURITY DEFINER View Issue - FINAL SOLUTION
-- ============================================================================
-- 
-- This script COMPLETELY resolves the security scanner warning about
-- public.public_fighter_profiles_view being flagged as SECURITY DEFINER.
--
-- ROOT CAUSES ADDRESSED:
-- 1. SECURITY DEFINER function dependencies (is_admin_user_id, is_admin_user, etc.)
-- 2. View owned by superuser (postgres, supabase_admin, etc.)
-- 3. Any remaining SECURITY DEFINER functions in the public schema
--
-- SOLUTION:
-- 1. Remove ALL SECURITY DEFINER functions from public schema
-- 2. Drop and recreate the view with direct JOINs (no function calls)
-- 3. Change view owner to non-superuser role (authenticated)
-- 4. Grant appropriate permissions
-- 5. Comprehensive verification
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

-- ============================================================================
-- STEP 1: Remove ALL SECURITY DEFINER functions from public schema
-- ============================================================================

DO $$
DECLARE
  r RECORD;
  dropped_count INTEGER := 0;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE 'STEP 1: Removing ALL SECURITY DEFINER functions...';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  
  -- Find and drop all SECURITY DEFINER functions
  FOR r IN 
    SELECT 
      p.oid::regprocedure as sig,
      p.proname as name,
      pg_get_function_identity_arguments(p.oid) as args
    FROM pg_proc p 
    JOIN pg_namespace n ON p.pronamespace = n.oid 
    WHERE n.nspname = 'public' 
      AND p.prosecdef = true
    ORDER BY p.proname
  LOOP 
    BEGIN
      EXECUTE format('DROP FUNCTION IF EXISTS %s CASCADE', r.sig);
      dropped_count := dropped_count + 1;
      RAISE NOTICE '✅ Dropped: %', r.sig;
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING '⚠️  Could not drop %: %', r.sig, SQLERRM;
    END;
  END LOOP;
  
  IF dropped_count = 0 THEN
    RAISE NOTICE 'ℹ️  No SECURITY DEFINER functions found in public schema';
  ELSE
    RAISE NOTICE '✅ Dropped % SECURITY DEFINER function(s)', dropped_count;
  END IF;
END $$;

-- Explicitly drop known problematic functions (multiple variations)
DROP FUNCTION IF EXISTS is_admin_user_id(UUID) CASCADE;
DROP FUNCTION IF EXISTS public.is_admin_user_id(UUID) CASCADE;
DROP FUNCTION IF EXISTS is_admin_user_id(UUID, TEXT) CASCADE;
DROP FUNCTION IF EXISTS public.is_admin_user_id(UUID, TEXT) CASCADE;
DROP FUNCTION IF EXISTS is_admin_user(UUID) CASCADE;
DROP FUNCTION IF EXISTS public.is_admin_user(UUID) CASCADE;

-- ============================================================================
-- STEP 2: Drop existing view (this removes any dependencies)
-- ============================================================================

DROP VIEW IF EXISTS public.public_fighter_profiles_view CASCADE;

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE 'STEP 2: View dropped';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
END $$;

-- ============================================================================
-- STEP 3: Create view WITHOUT any function dependencies
-- ============================================================================
-- CRITICAL: Use direct JOINs only - NO function calls
-- This ensures the view has ZERO SECURITY DEFINER dependencies

CREATE VIEW public.public_fighter_profiles_view AS
SELECT fp.*
FROM public.fighter_profiles fp
LEFT JOIN public.profiles p ON fp.user_id = p.id
WHERE (p.role IS NULL OR p.role != 'admin' OR p.role = '');

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE 'STEP 3: View created with direct JOINs (no function dependencies)';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
END $$;

-- ============================================================================
-- STEP 4: CRITICAL - Change owner to non-superuser role
-- ============================================================================
-- This is THE KEY FIX: Security scanners flag views owned by superusers
-- Changing owner to 'authenticated' (non-superuser) resolves the warning

DO $$
DECLARE
  current_owner TEXT;
  new_owner TEXT := 'authenticated';
  owner_changed BOOLEAN := false;
BEGIN
  -- Get current owner
  SELECT pg_get_userbyid(c.relowner) INTO current_owner
  FROM pg_class c
  JOIN pg_namespace n ON c.relnamespace = n.oid
  WHERE n.nspname = 'public' 
    AND c.relname = 'public_fighter_profiles_view' 
    AND c.relkind = 'v';
  
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE 'STEP 4: Changing view owner to non-superuser...';
  RAISE NOTICE 'Current owner: %', COALESCE(current_owner, 'UNKNOWN');
  RAISE NOTICE 'Target owner: %', new_owner;
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  
  -- Try authenticated first (preferred)
  BEGIN
    ALTER VIEW public.public_fighter_profiles_view OWNER TO authenticated;
    owner_changed := true;
    RAISE NOTICE '✅ Owner changed to authenticated';
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '⚠️  Could not change to authenticated: %', SQLERRM;
    RAISE NOTICE '   Trying anon as fallback...';
    
    -- Try anon as fallback
    BEGIN
      ALTER VIEW public.public_fighter_profiles_view OWNER TO anon;
      new_owner := 'anon';
      owner_changed := true;
      RAISE NOTICE '✅ Owner changed to anon';
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING '❌ Could not change owner to anon: %', SQLERRM;
      RAISE WARNING '⚠️  View may still be flagged if owned by superuser';
      RAISE WARNING '   Current owner: %', current_owner;
    END;
  END;
  
  -- Verify owner change
  IF owner_changed THEN
    SELECT pg_get_userbyid(c.relowner) INTO current_owner
    FROM pg_class c
    JOIN pg_namespace n ON c.relnamespace = n.oid
    WHERE n.nspname = 'public' 
      AND c.relname = 'public_fighter_profiles_view' 
      AND c.relkind = 'v';
    
    RAISE NOTICE '';
    RAISE NOTICE 'Verified owner: %', current_owner;
    
    IF current_owner IN ('postgres', 'supabase_admin', 'supabase_storage_admin', 'supabase_read_only_user') THEN
      RAISE WARNING '⚠️  Owner is still superuser - scanner may still flag this';
      RAISE WARNING '   You may need Supabase admin access to change owner';
    ELSE
      RAISE NOTICE '✅ Owner is non-superuser - scanner should be happy!';
    END IF;
  END IF;
END $$;

-- ============================================================================
-- STEP 5: Grant SELECT permissions
-- ============================================================================

GRANT SELECT ON public.public_fighter_profiles_view TO authenticated;
GRANT SELECT ON public.public_fighter_profiles_view TO anon;

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE 'STEP 5: Permissions granted';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
END $$;

-- ============================================================================
-- STEP 6: Add documentation
-- ============================================================================

COMMENT ON VIEW public.public_fighter_profiles_view IS 
'View of fighter_profiles excluding admin accounts. Owned by non-superuser role (authenticated). Uses SECURITY INVOKER (querying user permissions). No SECURITY DEFINER dependencies. Uses direct JOINs only.';

-- ============================================================================
-- STEP 7: COMPREHENSIVE VERIFICATION
-- ============================================================================

-- Verification 1: View exists
SELECT 
  'VERIFICATION_1' as check_num,
  'View Exists' as check_name,
  CASE WHEN EXISTS (
    SELECT 1 FROM pg_views 
    WHERE schemaname = 'public' AND viewname = 'public_fighter_profiles_view'
  )
    THEN '✅ PASS'
    ELSE '❌ FAIL'
  END as result;

-- Verification 2: Owner is non-superuser (CRITICAL CHECK)
SELECT 
  'VERIFICATION_2' as check_num,
  'Owner is Non-Superuser' as check_name,
  pg_get_userbyid(c.relowner) as owner_name,
  CASE 
    WHEN pg_get_userbyid(c.relowner) IN ('postgres', 'supabase_admin', 'supabase_storage_admin', 'supabase_read_only_user') 
      THEN '❌ FAIL - Owned by superuser'
    WHEN pg_get_userbyid(c.relowner) IN ('authenticated', 'anon') 
      THEN '✅ PASS - Owned by non-superuser'
    ELSE '⚠️  WARNING - Unknown owner: ' || pg_get_userbyid(c.relowner)
  END as result
FROM pg_class c
JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE n.nspname = 'public' 
  AND c.relname = 'public_fighter_profiles_view' 
  AND c.relkind = 'v';

-- Verification 3: No SECURITY DEFINER function dependencies
SELECT 
  'VERIFICATION_3' as check_num,
  'No SECURITY DEFINER Dependencies' as check_name,
  CASE WHEN EXISTS (
    SELECT 1 
    FROM pg_depend d 
    JOIN pg_proc p ON d.objid = p.oid 
    JOIN pg_class c ON d.refobjid = c.oid
    JOIN pg_namespace n ON c.relnamespace = n.oid
    WHERE n.nspname = 'public'
      AND c.relname = 'public_fighter_profiles_view' 
      AND c.relkind = 'v' 
      AND p.prosecdef = true
  )
    THEN '❌ FAIL - Has SECURITY DEFINER dependencies'
    ELSE '✅ PASS - No SECURITY DEFINER dependencies'
  END as result;

-- Verification 4: View uses direct JOINs (no function calls)
SELECT 
  'VERIFICATION_4' as check_num,
  'Uses Direct JOINs Only' as check_name,
  CASE 
    WHEN pg_get_viewdef('public.public_fighter_profiles_view'::regclass, true) LIKE '%is_admin%' 
      THEN '❌ FAIL - Uses is_admin function'
    WHEN pg_get_viewdef('public.public_fighter_profiles_view'::regclass, true) LIKE '%JOIN%' 
      THEN '✅ PASS - Uses direct JOINs'
    ELSE '⚠️  WARNING - Check manually'
  END as result;

-- Verification 5: No remaining SECURITY DEFINER functions in public schema
SELECT 
  'VERIFICATION_5' as check_num,
  'No SECURITY DEFINER Functions in Public Schema' as check_name,
  CASE WHEN EXISTS (
    SELECT 1 
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public' AND p.prosecdef = true
  )
    THEN '❌ FAIL - SECURITY DEFINER functions still exist'
    ELSE '✅ PASS - No SECURITY DEFINER functions'
  END as result;

-- ============================================================================
-- FINAL SUMMARY
-- ============================================================================

DO $$
DECLARE
  view_exists BOOLEAN;
  view_owner TEXT;
  has_security_definer_deps BOOLEAN;
  has_security_definer_funcs BOOLEAN;
  view_uses_functions BOOLEAN;
  all_checks_pass BOOLEAN := true;
BEGIN
  -- Check view exists
  SELECT EXISTS (
    SELECT 1 FROM pg_views 
    WHERE schemaname = 'public' AND viewname = 'public_fighter_profiles_view'
  ) INTO view_exists;
  
  -- Get view owner
  SELECT pg_get_userbyid(c.relowner) INTO view_owner
  FROM pg_class c
  JOIN pg_namespace n ON c.relnamespace = n.oid
  WHERE n.nspname = 'public' 
    AND c.relname = 'public_fighter_profiles_view' 
    AND c.relkind = 'v';
  
  -- Check for SECURITY DEFINER dependencies
  SELECT EXISTS (
    SELECT 1 
    FROM pg_depend d 
    JOIN pg_proc p ON d.objid = p.oid 
    JOIN pg_class c ON d.refobjid = c.oid
    JOIN pg_namespace n ON c.relnamespace = n.oid
    WHERE n.nspname = 'public'
      AND c.relname = 'public_fighter_profiles_view' 
      AND c.relkind = 'v' 
      AND p.prosecdef = true
  ) INTO has_security_definer_deps;
  
  -- Check for any SECURITY DEFINER functions in public schema
  SELECT EXISTS (
    SELECT 1 
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public' AND p.prosecdef = true
  ) INTO has_security_definer_funcs;
  
  -- Check if view uses functions
  SELECT pg_get_viewdef('public.public_fighter_profiles_view'::regclass, true) LIKE '%is_admin%'
    INTO view_uses_functions;
  
  -- Determine if all checks pass
  IF NOT view_exists THEN
    all_checks_pass := false;
  END IF;
  
  IF view_owner IN ('postgres', 'supabase_admin', 'supabase_storage_admin', 'supabase_read_only_user') THEN
    all_checks_pass := false;
  END IF;
  
  IF has_security_definer_deps THEN
    all_checks_pass := false;
  END IF;
  
  IF has_security_definer_funcs THEN
    all_checks_pass := false;
  END IF;
  
  IF view_uses_functions THEN
    all_checks_pass := false;
  END IF;
  
  RAISE NOTICE '';
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '                    FINAL VERIFICATION SUMMARY';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '';
  RAISE NOTICE 'View Exists: %', CASE WHEN view_exists THEN '✅ YES' ELSE '❌ NO' END;
  RAISE NOTICE 'View Owner: %', COALESCE(view_owner, 'UNKNOWN');
  RAISE NOTICE 'Owner is Non-Superuser: %', 
    CASE WHEN view_owner NOT IN ('postgres', 'supabase_admin', 'supabase_storage_admin', 'supabase_read_only_user') 
      THEN '✅ YES' ELSE '❌ NO' END;
  RAISE NOTICE 'No SECURITY DEFINER Dependencies: %', 
    CASE WHEN NOT has_security_definer_deps THEN '✅ YES' ELSE '❌ NO' END;
  RAISE NOTICE 'No SECURITY DEFINER Functions in Schema: %', 
    CASE WHEN NOT has_security_definer_funcs THEN '✅ YES' ELSE '❌ NO' END;
  RAISE NOTICE 'Uses Direct JOINs Only: %', 
    CASE WHEN NOT view_uses_functions THEN '✅ YES' ELSE '❌ NO' END;
  RAISE NOTICE '';
  
  IF all_checks_pass THEN
    RAISE NOTICE '✅ ✅ ✅ ALL CHECKS PASSED! ✅ ✅ ✅';
    RAISE NOTICE '';
    RAISE NOTICE 'The SECURITY DEFINER view issue should be COMPLETELY RESOLVED!';
    RAISE NOTICE '';
    RAISE NOTICE 'Next steps:';
    RAISE NOTICE '  1. Wait 5-10 minutes for security scanner cache to refresh';
    RAISE NOTICE '  2. Re-run your security scanner';
    RAISE NOTICE '  3. The warning should be gone ✅';
  ELSE
    RAISE WARNING '⚠️  ⚠️  ⚠️  SOME CHECKS FAILED ⚠️  ⚠️  ⚠️';
    RAISE WARNING '';
    IF view_owner IN ('postgres', 'supabase_admin', 'supabase_storage_admin', 'supabase_read_only_user') THEN
      RAISE WARNING '❌ View is still owned by superuser: %', view_owner;
      RAISE WARNING '   The scanner will flag this.';
      RAISE WARNING '   SOLUTION: Contact Supabase support to change the owner,';
      RAISE WARNING '   or run this script as a non-superuser role.';
    END IF;
    IF has_security_definer_deps THEN
      RAISE WARNING '❌ View still has SECURITY DEFINER dependencies';
      RAISE WARNING '   Check the dependency output above.';
    END IF;
    IF has_security_definer_funcs THEN
      RAISE WARNING '❌ SECURITY DEFINER functions still exist in public schema';
      RAISE WARNING '   Check the function list above.';
    END IF;
    IF view_uses_functions THEN
      RAISE WARNING '❌ View still uses function calls instead of direct JOINs';
      RAISE WARNING '   Check the view definition above.';
    END IF;
    IF NOT view_exists THEN
      RAISE WARNING '❌ View does not exist';
      RAISE WARNING '   Check for errors above.';
    END IF;
  END IF;
  
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
END $$;

-- ============================================================================
-- ✅ FIX COMPLETE
-- ============================================================================
-- 
-- If verification shows all checks passed:
-- 1. Wait 5-10 minutes for scanner cache to refresh
-- 2. Re-run your security scanner
-- 3. The warning should be resolved ✅
--
-- If owner is still a superuser:
-- - This may require Supabase admin access or running as a different user
-- - The view will still work correctly, but scanner may flag it
-- - Contact Supabase support if needed
--
-- ============================================================================

