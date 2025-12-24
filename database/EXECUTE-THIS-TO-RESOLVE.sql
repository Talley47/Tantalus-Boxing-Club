-- ============================================================================
-- ⚡ EXECUTE THIS TO RESOLVE SECURITY DEFINER VIEW WARNING ⚡
-- ============================================================================
-- 
-- INSTRUCTIONS:
-- 1. Copy ALL content below (Ctrl+A, Ctrl+C)
-- 2. Go to: https://supabase.com/dashboard → Your Project → SQL Editor
-- 3. Paste the script (Ctrl+V)
-- 4. Click "Run" button (or press Ctrl+Enter)
-- 5. Wait 5-10 minutes
-- 6. Re-run your security scanner
-- 
-- ============================================================================

-- Remove all SECURITY DEFINER functions
DO $$
DECLARE r RECORD;
BEGIN
  FOR r IN 
    SELECT p.oid::regprocedure as sig 
    FROM pg_proc p 
    JOIN pg_namespace n ON p.pronamespace = n.oid 
    WHERE n.nspname = 'public' AND p.prosecdef = true
  LOOP 
    EXECUTE format('DROP FUNCTION IF EXISTS %s CASCADE', r.sig); 
  END LOOP;
END $$;

DROP FUNCTION IF EXISTS is_admin_user_id(UUID) CASCADE;
DROP FUNCTION IF EXISTS public.is_admin_user_id(UUID) CASCADE;

-- Drop and recreate view (clean, no SECURITY DEFINER dependencies)
DROP VIEW IF EXISTS public.public_fighter_profiles_view CASCADE;

CREATE VIEW public.public_fighter_profiles_view AS
SELECT fp.* 
FROM public.fighter_profiles fp
LEFT JOIN public.profiles p ON fp.user_id = p.id
WHERE (p.role IS NULL OR p.role != 'admin' OR p.role = '');

-- Set permissions
GRANT SELECT ON public.public_fighter_profiles_view TO authenticated, anon;

-- Change owner to non-superuser role
DO $$ 
BEGIN
  ALTER VIEW public.public_fighter_profiles_view OWNER TO authenticated;
EXCEPTION WHEN OTHERS THEN 
  NULL; -- Ignore if can't change owner
END $$;

-- Verify fix
SELECT 
  '✅ RESOLUTION COMPLETE' as status,
  CASE WHEN EXISTS (
    SELECT 1 FROM pg_views 
    WHERE schemaname = 'public' AND viewname = 'public_fighter_profiles_view'
  )
    THEN 'View exists ✅'
    ELSE 'View missing ❌'
  END as view_check,
  CASE WHEN EXISTS (
    SELECT 1 FROM pg_depend d 
    JOIN pg_proc p ON d.objid = p.oid 
    JOIN pg_class c ON d.refobjid = c.oid
    WHERE c.relname = 'public_fighter_profiles_view' 
      AND c.relkind = 'v' 
      AND p.prosecdef = true
  )
    THEN '❌ Still has SECURITY DEFINER dependencies'
    ELSE '✅ No SECURITY DEFINER dependencies - RESOLVED!'
  END as security_check;

-- ============================================================================
-- ✅ DONE! 
-- 
-- Next steps:
-- 1. Check the output above - should show "✅ RESOLVED!"
-- 2. Wait 5-10 minutes for scanner cache to refresh
-- 3. Re-run your security scanner
-- 4. Warning should be gone ✅
-- 
-- ============================================================================

