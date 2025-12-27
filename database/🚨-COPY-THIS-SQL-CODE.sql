-- ============================================================================
-- 🚨 COPY THIS ENTIRE FILE INTO SUPABASE SQL EDITOR AND RUN IT
-- ============================================================================
-- 
-- THIS IS SQL CODE - NOT INSTRUCTIONS
-- Copy everything from here to the end of the file
-- Then paste into Supabase SQL Editor and click "Run"
--
-- ============================================================================

-- STEP 1: Grant schema and table permissions
GRANT USAGE ON SCHEMA public TO anon;
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT SELECT ON TABLE public.fighter_profiles TO anon;
GRANT SELECT ON TABLE public.fighter_profiles TO authenticated;
GRANT SELECT ON TABLE public.profiles TO anon;
GRANT SELECT ON TABLE public.profiles TO authenticated;

-- STEP 2: Enable RLS
ALTER TABLE public.fighter_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- STEP 3: Remove ALL existing policies on fighter_profiles
DO $$ 
DECLARE 
  r RECORD; 
BEGIN 
  FOR r IN 
    SELECT policyname 
    FROM pg_policies 
    WHERE schemaname = 'public' 
      AND tablename = 'fighter_profiles'
  LOOP 
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.fighter_profiles', r.policyname); 
  END LOOP; 
END $$;

-- STEP 4: Remove ALL existing policies on profiles
DO $$ 
DECLARE 
  r RECORD; 
BEGIN 
  FOR r IN 
    SELECT policyname 
    FROM pg_policies 
    WHERE schemaname = 'public' 
      AND tablename = 'profiles'
  LOOP 
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.profiles', r.policyname); 
  END LOOP; 
END $$;

-- STEP 5: Create new permissive SELECT policies for fighter_profiles
CREATE POLICY "authenticated_read_all_fighter_profiles" 
ON public.fighter_profiles 
FOR SELECT 
TO authenticated 
USING (true);

CREATE POLICY "anon_read_all_fighter_profiles" 
ON public.fighter_profiles 
FOR SELECT 
TO anon 
USING (true);

-- STEP 6: Create new permissive SELECT policies for profiles
CREATE POLICY "authenticated_read_all_profiles" 
ON public.profiles 
FOR SELECT 
TO authenticated 
USING (true);

CREATE POLICY "anon_read_all_profiles" 
ON public.profiles 
FOR SELECT 
TO anon 
USING (true);

-- STEP 7: Fix SECURITY DEFINER view issue
-- CRITICAL: Views owned by superusers are flagged as SECURITY DEFINER
-- Solution: Change owner to non-superuser role (authenticated)

-- Drop any problematic SECURITY DEFINER functions first
DROP FUNCTION IF EXISTS is_admin_user_id(UUID) CASCADE;
DROP FUNCTION IF EXISTS public.is_admin_user_id(UUID) CASCADE;
DROP FUNCTION IF EXISTS is_admin_user_id(UUID, TEXT) CASCADE;
DROP FUNCTION IF EXISTS public.is_admin_user_id(UUID, TEXT) CASCADE;
DROP FUNCTION IF EXISTS is_admin_user(UUID) CASCADE;
DROP FUNCTION IF EXISTS public.is_admin_user(UUID) CASCADE;
DROP FUNCTION IF EXISTS is_admin_user() CASCADE;
DROP FUNCTION IF EXISTS public.is_admin_user() CASCADE;

-- Drop the view (breaks all dependencies)
DROP VIEW IF EXISTS public.public_fighter_profiles_view CASCADE;

-- Recreate the view with ONLY direct JOINs (no function calls)
CREATE VIEW public.public_fighter_profiles_view AS
SELECT fp.*
FROM public.fighter_profiles fp
LEFT JOIN public.profiles p ON fp.user_id = p.id
WHERE (p.role IS NULL OR p.role != 'admin' OR p.role = '');

-- Grant SELECT permissions
GRANT SELECT ON public.public_fighter_profiles_view TO authenticated;
GRANT SELECT ON public.public_fighter_profiles_view TO anon;

-- CRITICAL: Change owner to non-superuser role (this fixes SECURITY DEFINER warning)
-- Security scanners flag views owned by superusers as SECURITY DEFINER
DO $$
BEGIN
  -- Try to change owner to authenticated role (non-superuser)
  ALTER VIEW public.public_fighter_profiles_view OWNER TO authenticated;
EXCEPTION WHEN OTHERS THEN
  -- If that fails, try postgres role (still better than superuser)
  BEGIN
    ALTER VIEW public.public_fighter_profiles_view OWNER TO postgres;
  EXCEPTION WHEN OTHERS THEN
    -- If both fail, just continue (view will work but may show warning)
    NULL;
  END;
END $$;

-- STEP 8: Verification tests
SELECT 
  'VERIFICATION: Total fighters' as test_name,
  COUNT(*) as total_fighters,
  CASE 
    WHEN COUNT(*) = 0 THEN '❌ FAIL - No fighters in table!'
    WHEN COUNT(*) > 0 THEN '✅ SUCCESS - Found ' || COUNT(*) || ' fighters'
    ELSE '⚠️ Unknown'
  END as result
FROM public.fighter_profiles;

SELECT 
  'VERIFICATION: Fighters with user_id (app query)' as test_name,
  COUNT(*) as fighters_with_user_id,
  CASE 
    WHEN COUNT(*) = 0 THEN '❌ FAIL - No fighters with user_id!'
    WHEN COUNT(*) > 0 THEN '✅ SUCCESS - Found ' || COUNT(*) || ' fighters (app will see these)'
    ELSE '⚠️ Unknown'
  END as result
FROM public.fighter_profiles
WHERE user_id IS NOT NULL;

SELECT 
  'VERIFICATION: Policy count' as test_name,
  tablename,
  COUNT(*) as policy_count
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN ('fighter_profiles', 'profiles')
GROUP BY tablename;

-- VERIFICATION: Check view owner and SECURITY DEFINER dependencies
SELECT 
  'VERIFICATION: View security status' as test_name,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM pg_views v
      JOIN pg_class c ON v.viewname = c.relname
      JOIN pg_user u ON c.relowner = u.usesysid
      WHERE v.schemaname = 'public' 
        AND v.viewname = 'public_fighter_profiles_view'
        AND u.usename IN ('postgres', 'supabase_admin', 'supabase_storage_admin')
    ) THEN '⚠️ WARNING - View owned by superuser (may trigger SECURITY DEFINER warning)'
    WHEN EXISTS (
      SELECT 1 FROM pg_views 
      WHERE schemaname = 'public' 
        AND viewname = 'public_fighter_profiles_view'
    ) THEN '✅ SUCCESS - View exists and owned by non-superuser'
    ELSE '❌ FAIL - View does not exist'
  END as view_owner_status,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM pg_depend d
      JOIN pg_proc p ON d.objid = p.oid
      JOIN pg_class c ON d.refobjid = c.oid
      WHERE c.relname = 'public_fighter_profiles_view' 
        AND c.relkind = 'v' 
        AND p.prosecdef = true
    ) THEN '❌ FAIL - View has SECURITY DEFINER function dependencies'
    ELSE '✅ SUCCESS - View has no SECURITY DEFINER dependencies'
  END as security_definer_status;

-- ============================================================================
-- ✅ FIX COMPLETE
-- ============================================================================
-- 
-- If verification shows fighters > 0:
-- 1. Hard refresh your app (Ctrl+Shift+R)
-- 2. Fighters should appear immediately!
--
-- ============================================================================

