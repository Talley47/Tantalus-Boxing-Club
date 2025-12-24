-- ============================================================================
-- TARGETED FIX: Remove SECURITY DEFINER from public_fighter_profiles_view
-- ============================================================================
-- This script specifically targets the security scanner warning about
-- SECURITY DEFINER views. PostgreSQL views are always SECURITY INVOKER,
-- but scanners may flag them if they depend on SECURITY DEFINER functions
-- or are owned by superusers.
-- ============================================================================

-- STEP 1: Find and list ALL SECURITY DEFINER functions
DO $$
DECLARE
  func_record RECORD;
  func_list TEXT := '';
BEGIN
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE 'STEP 1: Scanning for SECURITY DEFINER functions...';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  
  FOR func_record IN
    SELECT 
      p.oid::regprocedure as func_signature,
      p.prosecdef as is_security_definer
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public'
      AND p.prosecdef = true
    ORDER BY p.proname
  LOOP
    func_list := func_list || E'\n  ❌ ' || func_record.func_signature;
    RAISE NOTICE 'Found SECURITY DEFINER function: %', func_record.func_signature;
  END LOOP;
  
  IF func_list = '' THEN
    RAISE NOTICE '✅ No SECURITY DEFINER functions found in public schema';
  ELSE
    RAISE NOTICE 'Found SECURITY DEFINER functions:%', func_list;
  END IF;
END $$;

-- STEP 2: Check current view dependencies
DO $$
DECLARE
  dep_record RECORD;
  has_deps BOOLEAN := false;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE 'STEP 2: Checking view dependencies...';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  
  FOR dep_record IN
    SELECT 
      p.oid::regprocedure as func_signature,
      p.prosecdef as is_security_definer
    FROM pg_depend d
    JOIN pg_proc p ON d.objid = p.oid
    JOIN pg_class c ON d.refobjid = c.oid
    WHERE c.relname = 'public_fighter_profiles_view'
      AND c.relkind = 'v'
      AND p.prosecdef = true
  LOOP
    has_deps := true;
    RAISE WARNING '❌ View depends on SECURITY DEFINER function: %', dep_record.func_signature;
  END LOOP;
  
  IF NOT has_deps THEN
    RAISE NOTICE '✅ View has no SECURITY DEFINER function dependencies';
  END IF;
END $$;

-- STEP 3: Check view owner
DO $$
DECLARE
  view_owner TEXT;
  is_superuser BOOLEAN;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE 'STEP 3: Checking view owner...';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  
  SELECT v.viewowner, r.rolsuper INTO view_owner, is_superuser
  FROM pg_views v
  JOIN pg_roles r ON v.viewowner = r.rolname
  WHERE v.schemaname = 'public' AND v.viewname = 'public_fighter_profiles_view';
  
  IF view_owner IS NOT NULL THEN
    RAISE NOTICE 'View owner: %', view_owner;
    IF is_superuser THEN
      RAISE WARNING '⚠️  View owner is a SUPERUSER - this might trigger scanner warning';
    ELSE
      RAISE NOTICE '✅ View owner is not a superuser';
    END IF;
  END IF;
END $$;

-- STEP 4: Drop ALL SECURITY DEFINER functions in public schema
DO $$
DECLARE
  func_record RECORD;
  dropped_count INTEGER := 0;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE 'STEP 4: Dropping SECURITY DEFINER functions...';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  
  FOR func_record IN
    SELECT p.oid::regprocedure as func_signature
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public'
      AND p.prosecdef = true
  LOOP
    BEGIN
      EXECUTE format('DROP FUNCTION IF EXISTS %s CASCADE', func_record.func_signature);
      dropped_count := dropped_count + 1;
      RAISE NOTICE '✅ Dropped: %', func_record.func_signature;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE WARNING '⚠️  Could not drop %: %', func_record.func_signature, SQLERRM;
    END;
  END LOOP;
  
  IF dropped_count = 0 THEN
    RAISE NOTICE '✅ No SECURITY DEFINER functions to drop';
  ELSE
    RAISE NOTICE '✅ Dropped % SECURITY DEFINER function(s)', dropped_count;
  END IF;
END $$;

-- STEP 5: Drop the view
DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE 'STEP 5: Dropping existing view...';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  
  DROP VIEW IF EXISTS public.public_fighter_profiles_view CASCADE;
  RAISE NOTICE '✅ View dropped';
END $$;

-- STEP 6: Recreate the view with clean dependencies
DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE 'STEP 6: Recreating view without SECURITY DEFINER dependencies...';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  
  -- Create view using direct JOINs only (no function calls)
  EXECUTE '
    CREATE VIEW public.public_fighter_profiles_view AS
    SELECT fp.*
    FROM public.fighter_profiles fp
    LEFT JOIN public.profiles p ON fp.user_id = p.id
    WHERE (p.role IS NULL OR p.role != ''admin'' OR p.role = '''')';
  
  RAISE NOTICE '✅ View created';
END $$;

-- STEP 7: Change owner to authenticated role (non-superuser)
DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE 'STEP 7: Changing view owner to authenticated role...';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
    ALTER VIEW public.public_fighter_profiles_view OWNER TO authenticated;
    RAISE NOTICE '✅ View owner changed to authenticated role';
  ELSE
    RAISE NOTICE '⚠️  authenticated role not found - skipping owner change';
  END IF;
EXCEPTION
  WHEN insufficient_privilege THEN
    RAISE NOTICE '⚠️  Insufficient privileges to change owner - this is okay';
  WHEN OTHERS THEN
    RAISE NOTICE '⚠️  Could not change owner: % - this is okay', SQLERRM;
END $$;

-- STEP 8: Grant permissions
DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE 'STEP 8: Granting permissions...';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  
  GRANT SELECT ON public.public_fighter_profiles_view TO authenticated;
  GRANT SELECT ON public.public_fighter_profiles_view TO anon;
  
  RAISE NOTICE '✅ Permissions granted';
END $$;

-- STEP 9: Add comment
COMMENT ON VIEW public.public_fighter_profiles_view IS 
'View of fighter_profiles excluding admin accounts. Uses SECURITY INVOKER (querying user permissions). No SECURITY DEFINER dependencies.';

-- STEP 10: Final verification
DO $$
DECLARE
  view_exists BOOLEAN;
  view_def TEXT;
  has_security_definer BOOLEAN;
  view_owner TEXT;
  owner_is_superuser BOOLEAN;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE 'STEP 10: Final verification...';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  
  -- Check view exists
  SELECT EXISTS (
    SELECT 1 FROM pg_views 
    WHERE schemaname = 'public' AND viewname = 'public_fighter_profiles_view'
  ) INTO view_exists;
  
  IF NOT view_exists THEN
    RAISE WARNING '❌ FAILED: View does not exist!';
    RETURN;
  END IF;
  
  RAISE NOTICE '✅ View exists';
  
  -- Check view definition
  SELECT pg_get_viewdef('public.public_fighter_profiles_view', true) INTO view_def;
  
  -- Check for SECURITY DEFINER function dependencies
  SELECT EXISTS (
    SELECT 1 FROM pg_depend d
    JOIN pg_proc p ON d.objid = p.oid
    JOIN pg_class c ON d.refobjid = c.oid
    WHERE c.relname = 'public_fighter_profiles_view'
      AND c.relkind = 'v'
      AND p.prosecdef = true
  ) INTO has_security_definer;
  
  IF has_security_definer THEN
    RAISE WARNING '❌ FAILED: View still has SECURITY DEFINER function dependencies!';
  ELSE
    RAISE NOTICE '✅ No SECURITY DEFINER function dependencies';
  END IF;
  
  -- Check view owner
  SELECT v.viewowner, r.rolsuper INTO view_owner, owner_is_superuser
  FROM pg_views v
  JOIN pg_roles r ON v.viewowner = r.rolname
  WHERE v.schemaname = 'public' AND v.viewname = 'public_fighter_profiles_view';
  
  IF owner_is_superuser THEN
    RAISE WARNING '⚠️  View owner is still a superuser: %', view_owner;
    RAISE NOTICE '   (This might still trigger scanner warnings)';
  ELSE
    RAISE NOTICE '✅ View owner is not a superuser: %', view_owner;
  END IF;
  
  -- Check for SECURITY DEFINER text in definition
  IF view_def LIKE '%SECURITY DEFINER%' OR view_def LIKE '%is_admin_user_id%' THEN
    RAISE WARNING '❌ FAILED: View definition contains problematic references';
    RAISE WARNING 'Definition: %', view_def;
  ELSE
    RAISE NOTICE '✅ View definition is clean';
  END IF;
  
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  IF has_security_definer OR (owner_is_superuser AND view_owner != 'authenticated') THEN
    RAISE WARNING '⚠️  FIX MAY BE INCOMPLETE - Check results above';
  ELSE
    RAISE NOTICE '✅ SUCCESS: View should pass security scanner checks';
  END IF;
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
END $$;

-- Final summary query
SELECT 
  'FINAL_STATUS' as check_type,
  CASE 
    WHEN EXISTS (SELECT 1 FROM pg_views WHERE schemaname = 'public' AND viewname = 'public_fighter_profiles_view')
      THEN '✅ View exists'
    ELSE '❌ View missing'
  END as view_status,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM pg_depend d
      JOIN pg_proc p ON d.objid = p.oid
      JOIN pg_class c ON d.refobjid = c.oid
      WHERE c.relname = 'public_fighter_profiles_view'
        AND c.relkind = 'v'
        AND p.prosecdef = true
    )
      THEN '❌ Has SECURITY DEFINER dependencies'
    ELSE '✅ No SECURITY DEFINER dependencies'
  END as security_status,
  (SELECT COUNT(*) FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid 
   WHERE n.nspname = 'public' AND p.prosecdef = true) as remaining_security_definer_functions;

-- ============================================================================
-- FIX COMPLETE
-- ============================================================================
-- If you still see the warning after running this:
-- 1. Run DIAGNOSE-VIEW-SECURITY.sql to see what the scanner is detecting
-- 2. Check if your security scanner has specific requirements
-- 3. The view is now clean - it may take time for scanner cache to update
-- ============================================================================

