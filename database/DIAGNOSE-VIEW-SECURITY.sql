-- ============================================================================
-- DIAGNOSE: Why is public_fighter_profiles_view flagged as SECURITY DEFINER?
-- ============================================================================
-- Run this to see exactly what the security scanner is detecting
-- ============================================================================

-- Check 1: View definition and owner
SELECT 
  'VIEW_INFO' as check_type,
  schemaname,
  viewname,
  viewowner,
  definition
FROM pg_views
WHERE schemaname = 'public' AND viewname = 'public_fighter_profiles_view';

-- Check 2: View owner privileges (superuser = potential issue)
SELECT 
  'VIEW_OWNER_PRIVILEGES' as check_type,
  r.rolname as owner_name,
  r.rolsuper as is_superuser,
  r.rolcreaterole as can_create_roles,
  CASE WHEN r.rolsuper THEN '⚠️ SUPERUSER - This might trigger scanner warning' 
       ELSE '✅ Regular user' END as status
FROM pg_views v
JOIN pg_roles r ON v.viewowner = r.rolname
WHERE v.schemaname = 'public' AND v.viewname = 'public_fighter_profiles_view';

-- Check 3: All functions the view depends on
SELECT 
  'VIEW_DEPENDENCIES' as check_type,
  p.proname as function_name,
  pg_get_function_identity_arguments(p.oid) as function_args,
  p.prosecdef as is_security_definer,
  CASE WHEN p.prosecdef THEN '❌ SECURITY DEFINER - THIS IS THE PROBLEM!' 
       ELSE '✅ SECURITY INVOKER' END as security_type,
  n.nspname as schema_name
FROM pg_depend d
JOIN pg_proc p ON d.objid = p.oid
JOIN pg_class c ON d.refobjid = c.oid
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE c.relname = 'public_fighter_profiles_view'
  AND c.relkind = 'v'
ORDER BY p.prosecdef DESC, p.proname;

-- Check 4: All SECURITY DEFINER functions in public schema
SELECT 
  'ALL_SECURITY_DEFINER_FUNCTIONS' as check_type,
  p.proname as function_name,
  pg_get_function_identity_arguments(p.oid) as function_args,
  p.oid::regprocedure as full_signature,
  n.nspname as schema_name
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
  AND p.prosecdef = true
ORDER BY p.proname;

-- Check 5: View definition text search for SECURITY DEFINER references
SELECT 
  'VIEW_DEFINITION_SEARCH' as check_type,
  CASE 
    WHEN pg_get_viewdef('public.public_fighter_profiles_view', true) LIKE '%SECURITY DEFINER%' 
      THEN '❌ FOUND: SECURITY DEFINER in definition'
    WHEN pg_get_viewdef('public.public_fighter_profiles_view', true) LIKE '%is_admin_user_id%'
      THEN '❌ FOUND: is_admin_user_id function reference'
    ELSE '✅ No obvious SECURITY DEFINER references'
  END as status,
  pg_get_viewdef('public.public_fighter_profiles_view', true) as view_definition;

-- Check 6: Check if view was created with any special attributes
SELECT 
  'VIEW_ATTRIBUTES' as check_type,
  c.relname as view_name,
  c.relowner::regrole as owner,
  c.relkind as relation_type,
  -- Check if there are any special attributes stored
  (SELECT string_agg(attname, ', ') 
   FROM pg_attribute 
   WHERE attrelid = c.oid AND attnum > 0) as attributes
FROM pg_class c
JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE n.nspname = 'public' 
  AND c.relname = 'public_fighter_profiles_view'
  AND c.relkind = 'v';

-- ============================================================================
-- SUMMARY
-- ============================================================================
-- If you see SECURITY DEFINER functions in the dependencies, that's the issue.
-- If the view owner is a superuser, that might also trigger the warning.
-- ============================================================================

