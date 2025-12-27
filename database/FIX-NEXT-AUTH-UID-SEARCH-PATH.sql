-- ============================================================================
-- FIX: next_auth.uid Function Search Path Mutable
-- ============================================================================
-- This fixes the security warning about next_auth.uid having a mutable search_path
-- Copy ALL of this into Supabase SQL Editor and run it
-- ============================================================================

-- Step 1: Check current state
SELECT 
  'Before Fix' as status,
  n.nspname as schema_name,
  p.proname as function_name,
  CASE 
    WHEN p.proconfig IS NULL THEN '❌ NO search_path SET'
    WHEN array_to_string(p.proconfig, ', ') LIKE '%search_path%' THEN '✅ search_path SET'
    ELSE '❌ NOT SET'
  END as search_path_status
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'next_auth'
  AND p.proname = 'uid';

-- Step 2: Fix the function
DO $$
BEGIN
  -- Check if next_auth.uid function exists
  IF EXISTS (
    SELECT 1 
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'next_auth'
      AND p.proname = 'uid'
  ) THEN
    -- Set a fixed search_path for the function
    -- Using pg_catalog, public ensures safe schema resolution
    -- This prevents SQL injection via search_path manipulation
    ALTER FUNCTION next_auth.uid() SET search_path = pg_catalog, public;
    
    RAISE NOTICE '✅ Fixed search_path for next_auth.uid() function';
  ELSE
    RAISE WARNING '⚠️ Function next_auth.uid() not found - may have been removed or renamed';
  END IF;
END $$;

-- Step 3: Verify the fix
SELECT 
  'After Fix' as status,
  n.nspname as schema_name,
  p.proname as function_name,
  CASE 
    WHEN p.proconfig IS NOT NULL 
      AND array_to_string(p.proconfig, ', ') LIKE '%search_path%' 
    THEN '✅ FIXED - search_path is now SET'
    ELSE '❌ NOT FIXED - search_path still not set'
  END as search_path_status,
  p.proconfig as current_config
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'next_auth'
  AND p.proname = 'uid';

