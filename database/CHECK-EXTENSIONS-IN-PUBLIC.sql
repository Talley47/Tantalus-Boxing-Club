-- ============================================================================
-- CHECK: Extensions Installed in Public Schema
-- ============================================================================
-- This script finds all extensions installed in the public schema
-- ============================================================================

-- Check all extensions in public schema
SELECT 
  'Extensions in Public Schema' as check_name,
  extname as extension_name,
  extnamespace::regnamespace as schema_name,
  extversion as version,
  CASE 
    WHEN extnamespace::regnamespace::text = 'public' THEN '❌ IN PUBLIC SCHEMA'
    ELSE '✅ In dedicated schema'
  END as status
FROM pg_extension
WHERE extnamespace::regnamespace::text = 'public'
ORDER BY extname;

-- Check if vector extension exists and where it's installed
SELECT 
  'Vector Extension Check' as check_name,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM pg_extension WHERE extname = 'vector'
    ) THEN '✅ Extension exists'
    ELSE '❌ Extension not found'
  END as extension_exists,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM pg_extension 
      WHERE extname = 'vector' 
        AND extnamespace::regnamespace::text = 'public'
    ) THEN '❌ IN PUBLIC SCHEMA - NEEDS TO BE MOVED'
    WHEN EXISTS (
      SELECT 1 FROM pg_extension 
      WHERE extname = 'vector' 
        AND extnamespace::regnamespace::text != 'public'
    ) THEN '✅ Already in dedicated schema'
    ELSE 'N/A'
  END as schema_status,
  (
    SELECT extnamespace::regnamespace::text 
    FROM pg_extension 
    WHERE extname = 'vector'
    LIMIT 1
  ) as current_schema;

-- List all objects created by vector extension
SELECT 
  'Vector Extension Objects' as check_name,
  n.nspname as schema_name,
  c.relname as object_name,
  CASE c.relkind
    WHEN 'r' THEN 'table'
    WHEN 'v' THEN 'view'
    WHEN 'S' THEN 'sequence'
    WHEN 'f' THEN 'function'
    WHEN 't' THEN 'type'
    ELSE 'other'
  END as object_type
FROM pg_class c
JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE n.nspname IN ('public', 'vector', 'extensions')
  AND (
    c.relname LIKE '%vector%' 
    OR EXISTS (
      SELECT 1 FROM pg_depend d
      JOIN pg_extension e ON d.refobjid = e.oid
      WHERE d.objid = c.oid
        AND e.extname = 'vector'
    )
  )
ORDER BY n.nspname, c.relname;

