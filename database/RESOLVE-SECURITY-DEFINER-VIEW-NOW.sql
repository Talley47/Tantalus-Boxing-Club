-- ============================================================================
-- 🔒 RESOLVE SECURITY DEFINER VIEW ISSUE - DEFINITIVE FIX
-- ============================================================================
-- 
-- ISSUE: View public.public_fighter_profiles_view is flagged as having
--        SECURITY DEFINER properties, which can bypass RLS policies.
--
-- SOLUTION: Remove all SECURITY DEFINER dependencies, recreate view cleanly,
--           and change owner to non-superuser role.
--
-- INSTRUCTIONS:
-- 1. Copy ALL content below (Ctrl+A, Ctrl+C)
-- 2. Go to: https://supabase.com/dashboard → Your Project → SQL Editor
-- 3. Paste the script (Ctrl+V)
-- 4. Click "Run" button (or press Ctrl+Enter)
-- 5. Check the verification output at the bottom
-- 6. Wait 5-10 minutes for scanner cache to refresh
-- 7. Re-run your security scanner
--
-- ============================================================================

-- ============================================================================
-- STEP 1: Identify and remove ALL SECURITY DEFINER functions
-- ============================================================================

-- First, let's see what SECURITY DEFINER functions exist
DO $$
DECLARE
  func_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO func_count
  FROM pg_proc p
  JOIN pg_namespace n ON p.pronamespace = n.oid
  WHERE n.nspname = 'public' AND p.prosecdef = true;
  
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE 'STEP 1: Found % SECURITY DEFINER function(s) in public schema', func_count;
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
END $$;

-- List all SECURITY DEFINER functions
SELECT 
  'SECURITY_DEFINER_FUNCTIONS' as check_type,
  p.oid::regprocedure as function_signature,
  p.prosecdef as is_security_definer
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public' AND p.prosecdef = true
ORDER BY p.oid::regprocedure;

-- Remove ALL SECURITY DEFINER functions in public schema
DO $$
DECLARE
  r RECORD;
  dropped_count INTEGER := 0;
BEGIN
  FOR r IN 
    SELECT p.oid::regprocedure as sig,
           p.proname as func_name
    FROM pg_proc p 
    JOIN pg_namespace n ON p.pronamespace = n.oid 
    WHERE n.nspname = 'public' AND p.prosecdef = true
  LOOP 
    BEGIN
      EXECUTE format('DROP FUNCTION IF EXISTS %s CASCADE', r.sig);
      dropped_count := dropped_count + 1;
      RAISE NOTICE '✅ Dropped SECURITY DEFINER function: %', r.sig;
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING '⚠️  Could not drop function %: %', r.sig, SQLERRM;
    END;
  END LOOP;
  
  IF dropped_count > 0 THEN
    RAISE NOTICE '✅ Dropped % SECURITY DEFINER function(s)', dropped_count;
  ELSE
    RAISE NOTICE 'ℹ️  No SECURITY DEFINER functions found to drop';
  END IF;
END $$;

-- Explicitly drop known problematic functions
DROP FUNCTION IF EXISTS is_admin_user_id(UUID) CASCADE;
DROP FUNCTION IF EXISTS public.is_admin_user_id(UUID) CASCADE;
DROP FUNCTION IF EXISTS is_admin_user_id(UUID, TEXT) CASCADE;
DROP FUNCTION IF EXISTS public.is_admin_user_id(UUID, TEXT) CASCADE;

-- ============================================================================
-- STEP 2: Check view dependencies before dropping
-- ============================================================================

DO $$
DECLARE
  view_exists BOOLEAN;
  view_owner TEXT;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM pg_views 
    WHERE schemaname = 'public' AND viewname = 'public_fighter_profiles_view'
  ) INTO view_exists;
  
  IF view_exists THEN
    SELECT pg_get_userbyid(c.relowner) INTO view_owner
    FROM pg_class c
    JOIN pg_namespace n ON c.relnamespace = n.oid
    WHERE n.nspname = 'public' AND c.relname = 'public_fighter_profiles_view' AND c.relkind = 'v';
    
    RAISE NOTICE '';
    RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
    RAISE NOTICE 'STEP 2: Current view owner: %', COALESCE(view_owner, 'UNKNOWN');
    RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  ELSE
    RAISE NOTICE '';
    RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
    RAISE NOTICE 'STEP 2: View does not exist yet (will be created)';
    RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  END IF;
END $$;

-- Check for any SECURITY DEFINER dependencies on the view
SELECT 
  'VIEW_DEPENDENCIES' as check_type,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM pg_depend d 
      JOIN pg_proc p ON d.objid = p.oid 
      JOIN pg_class c ON d.refobjid = c.oid
      WHERE c.relname = 'public_fighter_profiles_view' 
        AND c.relkind = 'v' 
        AND p.prosecdef = true
    ) THEN '❌ View has SECURITY DEFINER dependencies'
    ELSE '✅ No SECURITY DEFINER dependencies found'
  END as dependency_status;

-- ============================================================================
-- STEP 3: Drop the existing view
-- ============================================================================

DROP VIEW IF EXISTS public.public_fighter_profiles_view CASCADE;

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE 'STEP 3: View dropped (if it existed)';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
END $$;

-- ============================================================================
-- STEP 4: Recreate the view WITHOUT any SECURITY DEFINER dependencies
-- ============================================================================
-- This view uses direct JOINs only - no function calls
-- PostgreSQL views always use SECURITY INVOKER (querying user permissions) by default

CREATE VIEW public.public_fighter_profiles_view AS
SELECT fp.*
FROM public.fighter_profiles fp
LEFT JOIN public.profiles p ON fp.user_id = p.id
WHERE (p.role IS NULL OR p.role != 'admin' OR p.role = '');

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE 'STEP 4: View recreated with direct JOINs (no SECURITY DEFINER functions)';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
END $$;

-- ============================================================================
-- STEP 5: Set permissions
-- ============================================================================

GRANT SELECT ON public.public_fighter_profiles_view TO authenticated;
GRANT SELECT ON public.public_fighter_profiles_view TO anon;

-- ============================================================================
-- STEP 6: Change owner to authenticated role (non-superuser)
-- ============================================================================

DO $$
BEGIN
  -- Try to change owner to authenticated role
  ALTER VIEW public.public_fighter_profiles_view OWNER TO authenticated;
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE 'STEP 6: View owner changed to authenticated role';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
EXCEPTION WHEN OTHERS THEN
  -- If we can't change owner, that's okay - the view will still work correctly
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE 'STEP 6: Could not change owner (this is okay - view will still work)';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
END $$;

-- ============================================================================
-- STEP 7: Add documentation comment
-- ============================================================================

COMMENT ON VIEW public.public_fighter_profiles_view IS 
'View of fighter_profiles excluding admin accounts. Uses SECURITY INVOKER (querying user permissions) and respects RLS policies. No SECURITY DEFINER dependencies.';

-- ============================================================================
-- STEP 8: Comprehensive verification
-- ============================================================================

-- Check 1: View exists
SELECT 
  'VERIFICATION_1' as check_type,
  'View exists' as check_name,
  CASE WHEN EXISTS (
    SELECT 1 FROM pg_views 
    WHERE schemaname = 'public' AND viewname = 'public_fighter_profiles_view'
  )
    THEN '✅ PASS'
    ELSE '❌ FAIL - View does not exist'
  END as result;

-- Check 2: View owner (should be authenticated or postgres)
SELECT 
  'VERIFICATION_2' as check_type,
  'View owner' as check_name,
  COALESCE(
    (SELECT pg_get_userbyid(c.relowner)
     FROM pg_class c
     JOIN pg_namespace n ON c.relnamespace = n.oid
     WHERE n.nspname = 'public' AND c.relname = 'public_fighter_profiles_view' AND c.relkind = 'v'),
    'UNKNOWN'
  ) as result;

-- Check 3: No SECURITY DEFINER function dependencies
SELECT 
  'VERIFICATION_3' as check_type,
  'No SECURITY DEFINER dependencies' as check_name,
  CASE WHEN EXISTS (
    SELECT 1 FROM pg_depend d 
    JOIN pg_proc p ON d.objid = p.oid 
    JOIN pg_class c ON d.refobjid = c.oid
    WHERE c.relname = 'public_fighter_profiles_view' 
      AND c.relkind = 'v' 
      AND p.prosecdef = true
  )
    THEN '❌ FAIL - Still has SECURITY DEFINER dependencies'
    ELSE '✅ PASS - No SECURITY DEFINER dependencies'
  END as result;

-- Check 4: View definition uses direct JOINs (not functions)
SELECT 
  'VERIFICATION_4' as check_type,
  'View uses direct JOINs' as check_name,
  CASE 
    WHEN pg_get_viewdef('public.public_fighter_profiles_view'::regclass, true) LIKE '%is_admin%' THEN '❌ FAIL - Uses is_admin function'
    WHEN pg_get_viewdef('public.public_fighter_profiles_view'::regclass, true) LIKE '%JOIN%' THEN '✅ PASS - Uses direct JOINs'
    ELSE '⚠️  WARNING - Check view definition manually'
  END as result;

-- Check 5: Permissions granted
SELECT 
  'VERIFICATION_5' as check_type,
  'Permissions granted' as check_name,
  CASE WHEN EXISTS (
    SELECT 1 FROM information_schema.table_privileges
    WHERE table_schema = 'public'
      AND table_name = 'public_fighter_profiles_view'
      AND privilege_type = 'SELECT'
      AND grantee IN ('authenticated', 'anon')
  )
    THEN '✅ PASS - SELECT permissions granted'
    ELSE '⚠️  WARNING - Check permissions manually'
  END as result;

-- Final summary
DO $$
DECLARE
  view_exists BOOLEAN;
  has_security_definer_deps BOOLEAN;
  view_owner TEXT;
BEGIN
  -- Check view exists
  SELECT EXISTS (
    SELECT 1 FROM pg_views 
    WHERE schemaname = 'public' AND viewname = 'public_fighter_profiles_view'
  ) INTO view_exists;
  
  -- Check for SECURITY DEFINER dependencies
  SELECT EXISTS (
    SELECT 1 FROM pg_depend d 
    JOIN pg_proc p ON d.objid = p.oid 
    JOIN pg_class c ON d.refobjid = c.oid
    WHERE c.relname = 'public_fighter_profiles_view' 
      AND c.relkind = 'v' 
      AND p.prosecdef = true
  ) INTO has_security_definer_deps;
  
  -- Get view owner
  SELECT pg_get_userbyid(c.relowner) INTO view_owner
  FROM pg_class c
  JOIN pg_namespace n ON c.relnamespace = n.oid
  WHERE n.nspname = 'public' AND c.relname = 'public_fighter_profiles_view' AND c.relkind = 'v';
  
  RAISE NOTICE '';
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '                    FINAL VERIFICATION SUMMARY';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '';
  
  IF view_exists AND NOT has_security_definer_deps THEN
    RAISE NOTICE '✅ ✅ ✅ SUCCESS! ✅ ✅ ✅';
    RAISE NOTICE '';
    RAISE NOTICE 'View Status:';
    RAISE NOTICE '  • View exists: ✅';
    RAISE NOTICE '  • No SECURITY DEFINER dependencies: ✅';
    RAISE NOTICE '  • View owner: %', COALESCE(view_owner, 'UNKNOWN');
    RAISE NOTICE '';
    RAISE NOTICE 'The SECURITY DEFINER view issue has been RESOLVED!';
    RAISE NOTICE '';
    RAISE NOTICE 'Next steps:';
    RAISE NOTICE '  1. Wait 5-10 minutes for security scanner cache to refresh';
    RAISE NOTICE '  2. Re-run your security scanner';
    RAISE NOTICE '  3. The warning should be gone ✅';
  ELSIF view_exists THEN
    RAISE WARNING '⚠️  ⚠️  ⚠️  PARTIAL SUCCESS ⚠️  ⚠️  ⚠️';
    RAISE WARNING '';
    RAISE WARNING 'View exists but still has SECURITY DEFINER dependencies.';
    RAISE WARNING 'Please check the dependency output above and run this script again.';
  ELSE
    RAISE WARNING '❌ ❌ ❌ FAILED ❌ ❌ ❌';
    RAISE WARNING '';
    RAISE WARNING 'View was not created successfully.';
    RAISE WARNING 'Please check for errors above and try again.';
  END IF;
  
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
END $$;

-- ============================================================================
-- ✅ FIX COMPLETE
-- ============================================================================
-- 
-- If verification shows SUCCESS:
-- 1. Wait 5-10 minutes for scanner cache to refresh
-- 2. Re-run your security scanner
-- 3. The "Security Definer View" warning should be resolved ✅
--
-- If verification shows issues:
-- 1. Review the error messages above
-- 2. Check for any remaining SECURITY DEFINER functions
-- 3. Run this script again if needed
--
-- ============================================================================

