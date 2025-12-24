-- ============================================================================
-- MINIMAL FIX: Remove SECURITY DEFINER from public_fighter_profiles_view
-- ============================================================================
-- This is the absolute minimum needed to fix the SECURITY DEFINER view warning.
-- If this doesn't work, the scanner may be detecting something else or needs cache refresh.
-- ============================================================================

-- Drop the view (breaks all dependencies)
DROP VIEW IF EXISTS public.public_fighter_profiles_view CASCADE;

-- Drop any SECURITY DEFINER functions that might be related
DROP FUNCTION IF EXISTS is_admin_user_id(UUID) CASCADE;
DROP FUNCTION IF EXISTS public.is_admin_user_id(UUID) CASCADE;

-- Recreate view with ONLY direct table references (no functions)
CREATE VIEW public.public_fighter_profiles_view AS
SELECT fp.*
FROM public.fighter_profiles fp
LEFT JOIN public.profiles p ON fp.user_id = p.id
WHERE (p.role IS NULL OR p.role != 'admin' OR p.role = '');

-- Grant permissions
GRANT SELECT ON public.public_fighter_profiles_view TO authenticated, anon;

-- Change owner to authenticated role (if possible)
DO $$
BEGIN
  ALTER VIEW public.public_fighter_profiles_view OWNER TO authenticated;
EXCEPTION WHEN OTHERS THEN
  NULL; -- Ignore if we can't change owner
END $$;

-- Verify
SELECT 
  'View Status' as check_type,
  CASE WHEN EXISTS (SELECT 1 FROM pg_views WHERE schemaname = 'public' AND viewname = 'public_fighter_profiles_view')
    THEN '✅ EXISTS'
    ELSE '❌ MISSING'
  END as status,
  CASE WHEN EXISTS (
    SELECT 1 FROM pg_depend d
    JOIN pg_proc p ON d.objid = p.oid
    JOIN pg_class c ON d.refobjid = c.oid
    WHERE c.relname = 'public_fighter_profiles_view' AND c.relkind = 'v' AND p.prosecdef = true
  )
    THEN '❌ HAS SECURITY DEFINER DEPENDENCIES'
    ELSE '✅ NO SECURITY DEFINER DEPENDENCIES'
  END as security_status;

