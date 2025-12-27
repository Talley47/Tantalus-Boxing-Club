-- ============================================================================
-- FIX: All Functions with Mutable Search Path
-- ============================================================================
-- This fixes ALL functions that don't have a fixed search_path
-- Copy ALL of this into Supabase SQL Editor and run it
-- ============================================================================

-- Step 1: Find all functions without search_path set
SELECT 
  'Functions needing fix' as status,
  n.nspname as schema_name,
  p.proname as function_name,
  pg_get_function_arguments(p.oid) as arguments
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname IN ('public', 'next_auth')
  AND (
    p.proconfig IS NULL 
    OR NOT (array_to_string(p.proconfig, ', ') LIKE '%search_path%')
  )
ORDER BY n.nspname, p.proname;

-- Step 2: Fix all functions automatically
DO $$
DECLARE
  func_record RECORD;
  sql_stmt TEXT;
BEGIN
  -- Loop through all functions in public and next_auth schemas without search_path
  FOR func_record IN
    SELECT 
      n.nspname as schema_name,
      p.proname as func_name,
      pg_get_function_arguments(p.oid) as func_args
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname IN ('public', 'next_auth')
      AND (
        p.proconfig IS NULL 
        OR NOT (array_to_string(p.proconfig, ', ') LIKE '%search_path%')
      )
  LOOP
    -- Build the ALTER FUNCTION statement
    IF func_record.func_args = '' THEN
      sql_stmt := format('ALTER FUNCTION %I.%I() SET search_path = pg_catalog, public, auth', 
                         func_record.schema_name, func_record.func_name);
    ELSE
      sql_stmt := format('ALTER FUNCTION %I.%I(%s) SET search_path = pg_catalog, public, auth', 
                         func_record.schema_name, func_record.func_name, func_record.func_args);
    END IF;
    
    -- Execute the ALTER FUNCTION statement
    BEGIN
      EXECUTE sql_stmt;
      RAISE NOTICE '✅ Fixed search_path for %.%', func_record.schema_name, func_record.func_name;
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING '⚠️ Failed to fix %.%: %', func_record.schema_name, func_record.func_name, SQLERRM;
    END;
  END LOOP;
END $$;

-- Step 3: Verify all fixes
SELECT 
  'Verification' as status,
  n.nspname as schema_name,
  p.proname as function_name,
  pg_get_function_arguments(p.oid) as arguments,
  CASE 
    WHEN p.proconfig IS NOT NULL 
      AND array_to_string(p.proconfig, ', ') LIKE '%search_path%' 
    THEN '✅ FIXED'
    ELSE '❌ STILL NOT FIXED'
  END as search_path_status
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname IN ('public', 'next_auth')
ORDER BY n.nspname, p.proname;

