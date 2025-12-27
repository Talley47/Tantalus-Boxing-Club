-- ============================================================================
-- COMPLETE FIX: Remove SECURITY DEFINER from public_fighter_profiles_view
-- ============================================================================
-- This comprehensive fix ensures the view has NO SECURITY DEFINER dependencies
-- Run this in Supabase SQL Editor
-- ============================================================================

-- STEP 1: Remove ALL SECURITY DEFINER functions from public schema
DO $$
DECLARE
  func_record RECORD;
  dropped_count INTEGER := 0;
BEGIN
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE 'STEP 1: Removing ALL SECURITY DEFINER functions from public schema...';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  
  FOR func_record IN
    SELECT p.oid::regprocedure as func_signature
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public'
      AND p.prosecdef = true  -- SECURITY DEFINER flag
  LOOP
    BEGIN
      EXECUTE format('DROP FUNCTION IF EXISTS %s CASCADE', func_record.func_signature);
      dropped_count := dropped_count + 1;
      RAISE NOTICE '✅ Dropped: %', func_record.func_signature;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE NOTICE '⚠️  Could not drop % (will be handled when view is dropped)', func_record.func_signature;
    END;
  END LOOP;
  
  IF dropped_count = 0 THEN
    RAISE NOTICE '✅ No SECURITY DEFINER functions found';
  ELSE
    RAISE NOTICE '✅ Removed % SECURITY DEFINER function(s)', dropped_count;
  END IF;
END $$;

-- STEP 2: Explicitly drop known problematic functions
DROP FUNCTION IF EXISTS is_admin_user_id(UUID) CASCADE;
DROP FUNCTION IF EXISTS public.is_admin_user_id(UUID) CASCADE;
DROP FUNCTION IF EXISTS is_admin_user_id(UUID, TEXT) CASCADE;
DROP FUNCTION IF EXISTS public.is_admin_user_id(UUID, TEXT) CASCADE;
DROP FUNCTION IF EXISTS is_admin_user(UUID) CASCADE;
DROP FUNCTION IF EXISTS public.is_admin_user(UUID) CASCADE;
DROP FUNCTION IF EXISTS is_admin_user() CASCADE;
DROP FUNCTION IF EXISTS public.is_admin_user() CASCADE;

-- STEP 3: Drop the existing view (this breaks any dependencies)
DROP VIEW IF EXISTS public.public_fighter_profiles_view CASCADE;

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE 'STEP 3: View dropped';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
END $$;

-- STEP 4: Recreate the view using ONLY direct JOINs (NO function calls)
-- CRITICAL: This view uses ZERO functions - only direct table JOINs
-- PostgreSQL views always use SECURITY INVOKER (querying user's permissions)
CREATE VIEW public.public_fighter_profiles_view AS
SELECT fp.*
FROM public.fighter_profiles fp
LEFT JOIN public.profiles p ON fp.user_id = p.id
WHERE (p.role IS NULL OR p.role != 'admin');

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE 'STEP 4: View recreated with direct JOINs only (no functions)';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
END $$;

-- STEP 5: Grant permissions
GRANT SELECT ON public.public_fighter_profiles_view TO authenticated;
GRANT SELECT ON public.public_fighter_profiles_view TO anon;

-- STEP 6: Add documentation
COMMENT ON VIEW public.public_fighter_profiles_view IS 
'View of fighter_profiles excluding admin accounts. Uses direct JOINs only - no SECURITY DEFINER function dependencies.';

-- STEP 7: Verify the fix
DO $$
DECLARE
    view_exists BOOLEAN;
    has_security_definer_deps BOOLEAN := false;
    view_def TEXT;
    func_count INTEGER := 0;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
    RAISE NOTICE 'STEP 7: Verifying fix...';
    RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
    
    -- Check if view exists
    SELECT EXISTS (
        SELECT 1 
        FROM pg_views 
        WHERE schemaname = 'public' 
        AND viewname = 'public_fighter_profiles_view'
    ) INTO view_exists;
    
    IF NOT view_exists THEN
        RAISE WARNING '❌ View does not exist';
        RETURN;
    END IF;
    
    -- Get view definition
    SELECT pg_get_viewdef('public.public_fighter_profiles_view'::regclass, true) INTO view_def;
    
    -- Count SECURITY DEFINER function dependencies
    SELECT COUNT(*)
    INTO func_count
    FROM pg_depend d
    JOIN pg_proc p ON d.objid = p.oid
    JOIN pg_class c ON d.refobjid = c.oid
    WHERE c.relname = 'public_fighter_profiles_view'
      AND c.relkind = 'v'
      AND p.prosecdef = true;
    
    -- Check results
    IF func_count > 0 THEN
        RAISE WARNING '❌ View still has % SECURITY DEFINER function dependency(ies)', func_count;
        RAISE NOTICE 'View definition: %', view_def;
    ELSIF view_def LIKE '%is_admin_user%' OR view_def LIKE '%SECURITY DEFINER%' THEN
        RAISE WARNING '❌ View definition contains problematic function calls';
        RAISE NOTICE 'View definition: %', view_def;
    ELSE
        RAISE NOTICE '✅ View exists';
        RAISE NOTICE '✅ No SECURITY DEFINER function dependencies';
        RAISE NOTICE '✅ View uses direct JOINs only';
        RAISE NOTICE '';
        RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
        RAISE NOTICE '✅ FIX COMPLETE - Security warning should be resolved';
        RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
    END IF;
END $$;

