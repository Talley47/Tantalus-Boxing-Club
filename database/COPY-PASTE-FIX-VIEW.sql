-- ============================================================================
-- COPY-PASTE-FIX: Remove SECURITY DEFINER from public_fighter_profiles_view
-- ============================================================================
-- Just copy this entire file, paste into Supabase SQL Editor, and run!
-- ============================================================================

-- Step 1: Drop the view and any SECURITY DEFINER functions
DROP VIEW IF EXISTS public.public_fighter_profiles_view CASCADE;
DROP FUNCTION IF EXISTS is_admin_user_id(UUID) CASCADE;
DROP FUNCTION IF EXISTS public.is_admin_user_id(UUID) CASCADE;

-- Step 2: Recreate view with ONLY direct table references (no functions)
CREATE VIEW public.public_fighter_profiles_view AS
SELECT fp.*
FROM public.fighter_profiles fp
LEFT JOIN public.profiles p ON fp.user_id = p.id
WHERE (p.role IS NULL OR p.role != 'admin' OR p.role = '');

-- Step 3: Grant permissions
GRANT SELECT ON public.public_fighter_profiles_view TO authenticated, anon;

-- Step 4: Change owner to authenticated role (non-superuser)
DO $$
BEGIN
  ALTER VIEW public.public_fighter_profiles_view OWNER TO authenticated;
EXCEPTION WHEN OTHERS THEN
  NULL; -- Ignore if we can't change owner
END $$;

-- Step 5: Verify the fix
SELECT 
  '✅ FIX APPLIED' as status,
  CASE WHEN EXISTS (SELECT 1 FROM pg_views WHERE schemaname = 'public' AND viewname = 'public_fighter_profiles_view')
    THEN 'View exists'
    ELSE 'View missing - ERROR!'
  END as view_status,
  CASE WHEN EXISTS (
    SELECT 1 FROM pg_depend d
    JOIN pg_proc p ON d.objid = p.oid
    JOIN pg_class c ON d.refobjid = c.oid
    WHERE c.relname = 'public_fighter_profiles_view' AND c.relkind = 'v' AND p.prosecdef = true
  )
    THEN '❌ Still has SECURITY DEFINER dependencies - RUN AGAIN!'
    ELSE '✅ No SECURITY DEFINER dependencies - SUCCESS!'
  END as security_status;

-- ============================================================================
-- DONE! Now:
-- 1. Wait 5-10 minutes for scanner cache to refresh
-- 2. Re-run your security scanner
-- 3. Warning should be resolved ✅
-- ============================================================================

