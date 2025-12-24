-- ============================================================================
-- VERIFY: Check if public_fighter_profiles_view SECURITY DEFINER issue is fixed
-- ============================================================================
-- Run this AFTER running MINIMAL-VIEW-FIX.sql to verify the fix worked
-- ============================================================================

-- Check 1: Does the view exist?
SELECT 
  '1. View Exists' as check_step,
  CASE WHEN EXISTS (
    SELECT 1 FROM pg_views 
    WHERE schemaname = 'public' AND viewname = 'public_fighter_profiles_view'
  )
    THEN '✅ YES'
    ELSE '❌ NO - View does not exist'
  END as result;

-- Check 2: Does the view have SECURITY DEFINER function dependencies?
SELECT 
  '2. SECURITY DEFINER Dependencies' as check_step,
  CASE WHEN EXISTS (
    SELECT 1 FROM pg_depend d
    JOIN pg_proc p ON d.objid = p.oid
    JOIN pg_class c ON d.refobjid = c.oid
    WHERE c.relname = 'public_fighter_profiles_view'
      AND c.relkind = 'v'
      AND p.prosecdef = true
  )
    THEN '❌ YES - View still has SECURITY DEFINER dependencies!'
    ELSE '✅ NO - View has no SECURITY DEFINER dependencies'
  END as result;

-- Check 3: What functions does the view depend on?
SELECT 
  '3. View Function Dependencies' as check_step,
  COALESCE(
    string_agg(
      p.oid::regprocedure::text || 
      CASE WHEN p.prosecdef THEN ' (SECURITY DEFINER ⚠️)' ELSE ' (SECURITY INVOKER ✅)' END,
      ', '
    ),
    '✅ None - View has no function dependencies'
  ) as result
FROM pg_depend d
JOIN pg_proc p ON d.objid = p.oid
JOIN pg_class c ON d.refobjid = c.oid
WHERE c.relname = 'public_fighter_profiles_view'
  AND c.relkind = 'v';

-- Check 4: Who owns the view?
SELECT 
  '4. View Owner' as check_step,
  v.viewowner as owner_name,
  CASE WHEN r.rolsuper THEN '⚠️ SUPERUSER - May trigger scanner warning'
       ELSE '✅ Regular user'
  END as owner_status
FROM pg_views v
JOIN pg_roles r ON v.viewowner = r.rolname
WHERE v.schemaname = 'public' AND v.viewname = 'public_fighter_profiles_view';

-- Check 5: View definition (should not contain function calls)
SELECT 
  '5. View Definition Check' as check_step,
  CASE 
    WHEN pg_get_viewdef('public.public_fighter_profiles_view', true) LIKE '%is_admin_user_id%'
      THEN '❌ Contains is_admin_user_id function call'
    WHEN pg_get_viewdef('public.public_fighter_profiles_view', true) LIKE '%SECURITY DEFINER%'
      THEN '❌ Contains SECURITY DEFINER reference'
    ELSE '✅ Clean - Only direct table references'
  END as result;

-- Check 6: Are there any SECURITY DEFINER functions in public schema?
SELECT 
  '6. SECURITY DEFINER Functions in Public Schema' as check_step,
  CASE WHEN COUNT(*) = 0 
    THEN '✅ None found'
    ELSE '⚠️ Found ' || COUNT(*) || ' SECURITY DEFINER function(s)'
  END as result,
  COALESCE(string_agg(p.oid::regprocedure::text, ', '), '') as function_list
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
  AND p.prosecdef = true;

-- ============================================================================
-- SUMMARY
-- ============================================================================
-- If all checks show ✅, the view should pass security scanner checks.
-- If you still see warnings:
-- 1. Wait 5-10 minutes (scanner cache may need to refresh)
-- 2. Re-run the security scanner
-- 3. Check scanner-specific requirements
-- ============================================================================

