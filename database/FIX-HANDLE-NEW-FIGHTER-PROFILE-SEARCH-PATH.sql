-- ============================================================================
-- FIX: public.handle_new_fighter_profile Function Search Path Mutable
-- ============================================================================
-- This fixes the security warning about handle_new_fighter_profile having a mutable search_path
-- Copy ALL of this into Supabase SQL Editor and run it
-- ============================================================================

-- Step 1: Check current state - find all functions with similar names
SELECT 
  'Before Fix' as status,
  n.nspname as schema_name,
  p.proname as function_name,
  pg_get_function_arguments(p.oid) as arguments,
  CASE 
    WHEN p.proconfig IS NULL THEN '❌ NO search_path SET'
    WHEN array_to_string(p.proconfig, ', ') LIKE '%search_path%' THEN '✅ search_path SET'
    ELSE '❌ NOT SET'
  END as search_path_status,
  p.proconfig as current_config
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
  AND p.proname LIKE '%handle_new_fighter_profile%'
ORDER BY p.proname;

-- Step 2: Fix handle_new_fighter_profile (if it exists without _from_auth suffix)
DO $$
DECLARE
  func_record RECORD;
BEGIN
  -- Find the function with exact name handle_new_fighter_profile
  FOR func_record IN
    SELECT 
      p.oid,
      p.proname,
      pg_get_function_arguments(p.oid) as args
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public'
      AND p.proname = 'handle_new_fighter_profile'
  LOOP
    -- Set search_path based on function signature
    -- For functions with no arguments
    IF func_record.args = '' THEN
      EXECUTE format('ALTER FUNCTION public.handle_new_fighter_profile() SET search_path = pg_catalog, public, auth');
      RAISE NOTICE '✅ Fixed search_path for public.handle_new_fighter_profile()';
    ELSE
      -- For functions with arguments, we need to use the full signature
      EXECUTE format('ALTER FUNCTION public.handle_new_fighter_profile(%s) SET search_path = pg_catalog, public, auth', func_record.args);
      RAISE NOTICE '✅ Fixed search_path for public.handle_new_fighter_profile(%)', func_record.args;
    END IF;
  END LOOP;
  
  IF NOT FOUND THEN
    RAISE NOTICE '⚠️ Function public.handle_new_fighter_profile not found - may have been renamed or removed';
  END IF;
END $$;

-- Step 3: Also ensure handle_new_fighter_profile_from_auth has search_path set
-- (This one should already have it, but let's make sure)
DO $$
DECLARE
  func_record RECORD;
BEGIN
  FOR func_record IN
    SELECT 
      p.oid,
      p.proname,
      pg_get_function_arguments(p.oid) as args
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public'
      AND p.proname = 'handle_new_fighter_profile_from_auth'
      AND (
        p.proconfig IS NULL 
        OR NOT (array_to_string(p.proconfig, ', ') LIKE '%search_path%')
      )
  LOOP
    IF func_record.args = '' THEN
      EXECUTE format('ALTER FUNCTION public.handle_new_fighter_profile_from_auth() SET search_path = pg_catalog, public, auth');
      RAISE NOTICE '✅ Fixed search_path for public.handle_new_fighter_profile_from_auth()';
    ELSE
      EXECUTE format('ALTER FUNCTION public.handle_new_fighter_profile_from_auth(%s) SET search_path = pg_catalog, public, auth', func_record.args);
      RAISE NOTICE '✅ Fixed search_path for public.handle_new_fighter_profile_from_auth(%)', func_record.args;
    END IF;
  END LOOP;
END $$;

-- Step 4: Verify the fix
SELECT 
  'After Fix' as status,
  n.nspname as schema_name,
  p.proname as function_name,
  pg_get_function_arguments(p.oid) as arguments,
  CASE 
    WHEN p.proconfig IS NOT NULL 
      AND array_to_string(p.proconfig, ', ') LIKE '%search_path%' 
    THEN '✅ FIXED - search_path is now SET'
    ELSE '❌ NOT FIXED - search_path still not set'
  END as search_path_status,
  p.proconfig as current_config
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
  AND p.proname LIKE '%handle_new_fighter_profile%'
ORDER BY p.proname;

