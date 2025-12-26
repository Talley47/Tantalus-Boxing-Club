-- ============================================================================
-- DIAGNOSE: SECURITY DEFINER View Issue
-- ============================================================================
-- This script diagnoses why public.public_fighter_profiles_view is flagged
-- as SECURITY DEFINER by the security scanner.
-- ============================================================================

-- Check 1: View exists and basic info
SELECT 
  'VIEW_INFO' as check_type,
  schemaname,
  viewname,
  viewowner,
  definition
FROM pg_views
WHERE schemaname = 'public' 
  AND viewname = 'public_fighter_profiles_view';

-- Check 2: View owner (from pg_class)
SELECT 
  'VIEW_OWNER' as check_type,
  pg_get_userbyid(c.relowner) as owner_name,
  CASE 
    WHEN pg_get_userbyid(c.relowner) IN ('postgres', 'supabase_admin', 'supabase_storage_admin', 'supabase_read_only_user') 
      THEN '❌ SUPERUSER - This will be flagged!'
    WHEN pg_get_userbyid(c.relowner) IN ('authenticated', 'anon') 
      THEN '✅ NON-SUPERUSER - Should be OK'
    ELSE '⚠️  UNKNOWN ROLE: ' || pg_get_userbyid(c.relowner)
  END as owner_status
FROM pg_class c
JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE n.nspname = 'public' 
  AND c.relname = 'public_fighter_profiles_view' 
  AND c.relkind = 'v';

-- Check 3: SECURITY DEFINER function dependencies
SELECT 
  'SECURITY_DEFINER_DEPS' as check_type,
  p.proname as function_name,
  p.oid::regprocedure as function_signature,
  CASE WHEN p.prosecdef THEN '❌ SECURITY DEFINER' ELSE '✅ SECURITY INVOKER' END as security_type
FROM pg_depend d
JOIN pg_proc p ON d.objid = p.oid
JOIN pg_class c ON d.refobjid = c.oid
JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE n.nspname = 'public'
  AND c.relname = 'public_fighter_profiles_view'
  AND c.relkind = 'v'
  AND p.prosecdef = true;

-- Check 4: All SECURITY DEFINER functions in public schema
SELECT 
  'ALL_SECURITY_DEFINER_FUNCS' as check_type,
  p.proname as function_name,
  p.oid::regprocedure as function_signature,
  '❌ SECURITY DEFINER' as security_type
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public' 
  AND p.prosecdef = true
ORDER BY p.proname;

-- Check 5: View definition (check for function calls)
SELECT 
  'VIEW_DEFINITION' as check_type,
  pg_get_viewdef('public.public_fighter_profiles_view'::regclass, true) as view_definition;

-- Check 6: View privileges
SELECT 
  'VIEW_PRIVILEGES' as check_type,
  grantee,
  privilege_type
FROM information_schema.table_privileges
WHERE table_schema = 'public'
  AND table_name = 'public_fighter_profiles_view'
ORDER BY grantee, privilege_type;

