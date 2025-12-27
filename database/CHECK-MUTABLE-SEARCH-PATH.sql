-- ============================================================================
-- CHECK: Functions with Mutable Search Path
-- ============================================================================
-- This script finds all functions that don't have a fixed search_path
-- ============================================================================

SELECT 
  n.nspname as schema_name,
  p.proname as function_name,
  pg_get_function_arguments(p.oid) as arguments,
  CASE 
    WHEN p.proconfig IS NULL THEN '❌ NO search_path SET'
    WHEN array_to_string(p.proconfig, ', ') LIKE '%search_path%' THEN '✅ search_path SET'
    ELSE '⚠️ UNKNOWN'
  END as search_path_status,
  p.proconfig as current_config
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname NOT IN ('pg_catalog', 'information_schema', 'pg_toast')
  AND (
    -- Functions without search_path set
    p.proconfig IS NULL 
    OR NOT (array_to_string(p.proconfig, ', ') LIKE '%search_path%')
  )
ORDER BY n.nspname, p.proname;

-- Specifically check for next_auth.uid
SELECT 
  'next_auth.uid Check' as check_name,
  CASE 
    WHEN EXISTS (
      SELECT 1 
      FROM pg_proc p
      JOIN pg_namespace n ON p.pronamespace = n.oid
      WHERE n.nspname = 'next_auth'
        AND p.proname = 'uid'
    ) THEN '✅ Function exists'
    ELSE '❌ Function not found'
  END as function_exists,
  CASE 
    WHEN EXISTS (
      SELECT 1 
      FROM pg_proc p
      JOIN pg_namespace n ON p.pronamespace = n.oid
      WHERE n.nspname = 'next_auth'
        AND p.proname = 'uid'
        AND p.proconfig IS NOT NULL
        AND array_to_string(p.proconfig, ', ') LIKE '%search_path%'
    ) THEN '✅ search_path is SET'
    WHEN EXISTS (
      SELECT 1 
      FROM pg_proc p
      JOIN pg_namespace n ON p.pronamespace = n.oid
      WHERE n.nspname = 'next_auth'
        AND p.proname = 'uid'
    ) THEN '❌ search_path NOT SET'
    ELSE 'N/A'
  END as search_path_status;

