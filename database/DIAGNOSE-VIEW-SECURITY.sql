-- ============================================================================
-- DIAGNOSE: Check why public_fighter_profiles_view is flagged as SECURITY DEFINER
-- ============================================================================
-- Run this FIRST to see what's causing the warning
-- ============================================================================

-- Check 1: Does the view exist and what's its definition?
SELECT 
    'View Definition' as check_type,
    pg_get_viewdef('public.public_fighter_profiles_view'::regclass, true) as result;

-- Check 2: What functions does the view depend on?
SELECT 
    'View Dependencies' as check_type,
    p.proname as function_name,
    pg_get_function_identity_arguments(p.oid) as function_args,
    CASE WHEN p.prosecdef THEN 'YES - SECURITY DEFINER' ELSE 'NO - SECURITY INVOKER' END as is_security_definer
FROM pg_depend d
JOIN pg_proc p ON d.objid = p.oid
JOIN pg_class c ON d.refobjid = c.oid
WHERE c.relname = 'public_fighter_profiles_view'
  AND c.relkind = 'v'
  AND d.deptype = 'n';

-- Check 3: Who owns the view?
SELECT 
    'View Owner' as check_type,
    c.relname as view_name,
    r.rolname as owner_name,
    CASE WHEN r.rolsuper THEN 'YES - SUPERUSER' ELSE 'NO - REGULAR USER' END as is_superuser
FROM pg_class c
JOIN pg_roles r ON c.relowner = r.oid
WHERE c.relname = 'public_fighter_profiles_view'
  AND c.relkind = 'v';

-- Check 4: Are there any SECURITY DEFINER functions in public schema?
SELECT 
    'SECURITY DEFINER Functions' as check_type,
    p.proname as function_name,
    pg_get_function_identity_arguments(p.oid) as function_args,
    p.oid::regprocedure as full_signature
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
  AND p.prosecdef = true;
