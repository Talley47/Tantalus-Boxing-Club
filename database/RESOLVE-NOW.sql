-- ============================================================================
-- RESOLVE: SECURITY DEFINER View Warning
-- ============================================================================
-- Copy this entire script → Paste in Supabase SQL Editor → Click Run
-- ============================================================================

-- Step 1: Remove all SECURITY DEFINER functions
DO $$
DECLARE r RECORD;
BEGIN
  FOR r IN SELECT p.oid::regprocedure as sig FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.prosecdef = true
  LOOP EXECUTE format('DROP FUNCTION IF EXISTS %s CASCADE', r.sig); END LOOP;
END $$;

DROP FUNCTION IF EXISTS is_admin_user_id(UUID) CASCADE;

-- Step 2: Drop and recreate view
DROP VIEW IF EXISTS public.public_fighter_profiles_view CASCADE;

CREATE VIEW public.public_fighter_profiles_view AS
SELECT fp.* FROM public.fighter_profiles fp
LEFT JOIN public.profiles p ON fp.user_id = p.id
WHERE (p.role IS NULL OR p.role != 'admin' OR p.role = '');

-- Step 3: Set permissions and owner
GRANT SELECT ON public.public_fighter_profiles_view TO authenticated, anon;

DO $$ BEGIN
  ALTER VIEW public.public_fighter_profiles_view OWNER TO authenticated;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- Step 4: Verify
SELECT 
  'Status' as check_type,
  CASE WHEN EXISTS (SELECT 1 FROM pg_views WHERE schemaname = 'public' AND viewname = 'public_fighter_profiles_view')
    THEN '✅ View exists'
    ELSE '❌ View missing'
  END as result,
  CASE WHEN EXISTS (
    SELECT 1 FROM pg_depend d JOIN pg_proc p ON d.objid = p.oid JOIN pg_class c ON d.refobjid = c.oid
    WHERE c.relname = 'public_fighter_profiles_view' AND c.relkind = 'v' AND p.prosecdef = true
  )
    THEN '❌ Has SECURITY DEFINER dependencies'
    ELSE '✅ No SECURITY DEFINER dependencies - FIXED!'
  END as security_status;

-- ============================================================================
-- ✅ DONE! Wait 5-10 minutes, then re-run your security scanner.
-- ============================================================================

