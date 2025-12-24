-- ============================================================================
-- 🔍 DIAGNOSE: Why is public_fighter_profiles_view flagged as SECURITY DEFINER?
-- ============================================================================
-- Run this FIRST to understand what the scanner is detecting
-- ============================================================================

-- Check 1: View exists and basic info
SELECT 
  'CHECK_1' as check_num,
  'View Exists' as check_name,
  CASE WHEN EXISTS (
    SELECT 1 FROM pg_views 
    WHERE schemaname = 'public' AND viewname = 'public_fighter_profiles_view'
  )
    THEN '✅ EXISTS'
    ELSE '❌ MISSING'
  END as result;

-- Check 2: View owner (THIS IS KEY!)
SELECT 
  'CHECK_2' as check_num,
  'View Owner' as check_name,
  pg_get_userbyid(c.relowner) as owner_name,
  CASE 
    WHEN pg_get_userbyid(c.relowner) = 'postgres' THEN '❌ OWNED BY SUPERUSER - SCANNER FLAGS THIS!'
    WHEN pg_get_userbyid(c.relowner) = 'authenticated' THEN '✅ OWNED BY NON-SUPERUSER'
    WHEN pg_get_userbyid(c.relowner) = 'anon' THEN '✅ OWNED BY NON-SUPERUSER'
    ELSE '⚠️  UNKNOWN OWNER: ' || pg_get_userbyid(c.relowner)
  END as result
FROM pg_class c
JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE n.nspname = 'public' AND c.relname = 'public_fighter_profiles_view' AND c.relkind = 'v';

-- Check 3: View creator (who created it?)
SELECT 
  'CHECK_3' as check_num,
  'View Creator' as check_name,
  pg_get_userbyid(c.relowner) as creator,
  CASE 
    WHEN pg_get_userbyid(c.relowner) IN ('postgres', 'supabase_admin', 'supabase_storage_admin') THEN '❌ CREATED BY SUPERUSER'
    ELSE '✅ CREATED BY NON-SUPERUSER'
  END as result
FROM pg_class c
JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE n.nspname = 'public' AND c.relname = 'public_fighter_profiles_view' AND c.relkind = 'v';

-- Check 4: SECURITY DEFINER function dependencies
SELECT 
  'CHECK_4' as check_num,
  'SECURITY DEFINER Dependencies' as check_name,
  CASE WHEN EXISTS (
    SELECT 1 FROM pg_depend d 
    JOIN pg_proc p ON d.objid = p.oid 
    JOIN pg_class c ON d.refobjid = c.oid
    WHERE c.relname = 'public_fighter_profiles_view' 
      AND c.relkind = 'v' 
      AND p.prosecdef = true
  )
    THEN '❌ HAS SECURITY DEFINER FUNCTION DEPENDENCIES'
    ELSE '✅ NO SECURITY DEFINER FUNCTION DEPENDENCIES'
  END as result;

-- Check 5: List ALL SECURITY DEFINER functions in public schema
SELECT 
  'CHECK_5' as check_num,
  'SECURITY DEFINER Functions' as check_name,
  p.oid::regprocedure as function_signature,
  '❌ FOUND SECURITY DEFINER FUNCTION' as result
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public' AND p.prosecdef = true
ORDER BY p.oid::regprocedure;

-- If no functions found, show that
SELECT 
  'CHECK_5' as check_num,
  'SECURITY DEFINER Functions' as check_name,
  '✅ NONE FOUND' as function_signature,
  '✅ NO SECURITY DEFINER FUNCTIONS' as result
WHERE NOT EXISTS (
  SELECT 1 FROM pg_proc p
  JOIN pg_namespace n ON p.pronamespace = n.oid
  WHERE n.nspname = 'public' AND p.prosecdef = true
);

-- Check 6: View definition (does it use functions?)
SELECT 
  'CHECK_6' as check_num,
  'View Definition' as check_name,
  CASE 
    WHEN pg_get_viewdef('public.public_fighter_profiles_view'::regclass, true) LIKE '%is_admin%' THEN '❌ USES is_admin FUNCTION'
    WHEN pg_get_viewdef('public.public_fighter_profiles_view'::regclass, true) LIKE '%SECURITY DEFINER%' THEN '❌ CONTAINS SECURITY DEFINER TEXT'
    ELSE '✅ USES DIRECT JOINS ONLY'
  END as result;

-- Check 7: Current user (who is running this?)
SELECT 
  'CHECK_7' as check_num,
  'Current User' as check_name,
  current_user as user_name,
  CASE 
    WHEN current_user IN ('postgres', 'supabase_admin', 'supabase_storage_admin') THEN '⚠️  RUNNING AS SUPERUSER'
    ELSE '✅ RUNNING AS NON-SUPERUSER'
  END as result;

-- Check 8: Can we change owner?
SELECT 
  'CHECK_8' as check_num,
  'Can Change Owner' as check_name,
  CASE 
    WHEN current_user IN ('postgres', 'supabase_admin') THEN '✅ YES - HAVE PERMISSION'
    ELSE '⚠️  MAY NOT HAVE PERMISSION'
  END as result;

-- ============================================================================
-- SUMMARY: What the scanner is likely detecting
-- ============================================================================
DO $$
DECLARE
  view_owner TEXT;
  has_security_definer_deps BOOLEAN;
  current_user_name TEXT;
BEGIN
  -- Get view owner
  SELECT pg_get_userbyid(c.relowner) INTO view_owner
  FROM pg_class c
  JOIN pg_namespace n ON c.relnamespace = n.oid
  WHERE n.nspname = 'public' AND c.relname = 'public_fighter_profiles_view' AND c.relkind = 'v';
  
  -- Check for SECURITY DEFINER dependencies
  SELECT EXISTS (
    SELECT 1 FROM pg_depend d 
    JOIN pg_proc p ON d.objid = p.oid 
    JOIN pg_class c ON d.refobjid = c.oid
    WHERE c.relname = 'public_fighter_profiles_view' 
      AND c.relkind = 'v' 
      AND p.prosecdef = true
  ) INTO has_security_definer_deps;
  
  -- Get current user
  SELECT current_user INTO current_user_name;
  
  RAISE NOTICE '';
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '                    DIAGNOSIS SUMMARY';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '';
  RAISE NOTICE 'View Owner: %', COALESCE(view_owner, 'NOT FOUND');
  RAISE NOTICE 'Has SECURITY DEFINER Dependencies: %', has_security_definer_deps;
  RAISE NOTICE 'Current User: %', current_user_name;
  RAISE NOTICE '';
  
  IF view_owner IN ('postgres', 'supabase_admin', 'supabase_storage_admin') THEN
    RAISE WARNING '❌ PROBLEM IDENTIFIED: View is owned by superuser "%"', view_owner;
    RAISE NOTICE '';
    RAISE NOTICE 'SOLUTION: Change view owner to non-superuser role (authenticated or anon)';
    RAISE NOTICE 'The scanner flags views owned by superusers as SECURITY DEFINER.';
  ELSIF has_security_definer_deps THEN
    RAISE WARNING '❌ PROBLEM IDENTIFIED: View depends on SECURITY DEFINER functions';
    RAISE NOTICE '';
    RAISE NOTICE 'SOLUTION: Remove all SECURITY DEFINER function dependencies';
  ELSE
    RAISE NOTICE '✅ View owner is non-superuser and has no SECURITY DEFINER dependencies';
    RAISE NOTICE '';
    RAISE NOTICE 'If scanner still flags it, may need to wait for cache refresh (5-10 min)';
  END IF;
  
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
END $$;

