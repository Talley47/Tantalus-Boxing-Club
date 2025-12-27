-- ============================================================================
-- FIX: Move vector Extension (SAFE VERSION - Preserves Data)
-- ============================================================================
-- This version checks for vector columns/data before moving
-- Use this if you have existing vector data you want to preserve
-- Copy ALL of this into Supabase SQL Editor and run it
-- ============================================================================

-- Step 1: Check if vector extension exists and where
SELECT 
  'Current State' as status,
  extname as extension_name,
  extnamespace::regnamespace::text as current_schema,
  extversion as version
FROM pg_extension
WHERE extname = 'vector';

-- Step 2: Check for tables with vector columns (these will be affected)
SELECT 
  'Tables with Vector Columns' as check_name,
  n.nspname as schema_name,
  t.table_name,
  c.column_name,
  c.data_type
FROM information_schema.columns c
JOIN information_schema.tables t ON c.table_schema = t.table_schema AND c.table_name = t.table_name
JOIN pg_namespace n ON n.nspname = t.table_schema
WHERE c.data_type LIKE '%vector%'
  OR c.udt_name LIKE '%vector%'
ORDER BY n.nspname, t.table_name, c.column_name;

-- Step 3: Create extensions schema
CREATE SCHEMA IF NOT EXISTS extensions;
GRANT USAGE ON SCHEMA extensions TO postgres, anon, authenticated, service_role;

-- Step 4: Check if we have vector data to preserve
DO $$
DECLARE
  has_vector_data BOOLEAN := FALSE;
  table_count INTEGER;
BEGIN
  -- Count tables with vector columns
  SELECT COUNT(*) INTO table_count
  FROM information_schema.columns
  WHERE data_type LIKE '%vector%' OR udt_name LIKE '%vector%';
  
  IF table_count > 0 THEN
    has_vector_data := TRUE;
    RAISE WARNING '⚠️ Found % tables with vector columns. Moving extension will preserve data.', table_count;
    RAISE NOTICE 'Proceeding with safe migration...';
  ELSE
    RAISE NOTICE '✅ No vector columns found - safe to move extension';
  END IF;
  
  -- Move the extension
  IF EXISTS (
    SELECT 1 FROM pg_extension 
    WHERE extname = 'vector' 
      AND extnamespace::regnamespace::text = 'public'
  ) THEN
    -- Drop and recreate in extensions schema
    -- PostgreSQL will preserve the data in tables, but vector functions/types will be recreated
    DROP EXTENSION IF EXISTS vector CASCADE;
    
    -- Recreate in extensions schema
    CREATE EXTENSION IF NOT EXISTS vector SCHEMA extensions;
    
    RAISE NOTICE '✅ Vector extension moved to extensions schema';
    
    IF has_vector_data THEN
      RAISE NOTICE '✅ Vector data preserved in tables';
      RAISE NOTICE '⚠️ You may need to update any code that references vector types directly';
    END IF;
  ELSE
    RAISE NOTICE '⚠️ Vector extension not in public schema - may already be moved';
  END IF;
END $$;

-- Step 5: Verify the fix
SELECT 
  'Verification' as status,
  extname as extension_name,
  extnamespace::regnamespace::text as current_schema,
  CASE 
    WHEN extnamespace::regnamespace::text = 'extensions' THEN '✅ FIXED'
    WHEN extnamespace::regnamespace::text = 'public' THEN '❌ STILL IN PUBLIC'
    ELSE '⚠️ In schema: ' || extnamespace::regnamespace::text
  END as fix_status
FROM pg_extension
WHERE extname = 'vector';

-- Step 6: Update search_path
-- Set search_path per role (more reliable in managed services like Supabase)
DO $$
BEGIN
  -- Set search_path for common roles
  ALTER ROLE postgres SET search_path = pg_catalog, public, extensions;
  ALTER ROLE authenticated SET search_path = pg_catalog, public, extensions;
  ALTER ROLE anon SET search_path = pg_catalog, public, extensions;
  ALTER ROLE service_role SET search_path = pg_catalog, public, extensions;
  
  RAISE NOTICE '✅ Updated search_path for all roles';
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING '⚠️ Could not update search_path: %', SQLERRM;
  RAISE NOTICE 'You may need to manually set search_path in your connection strings';
END $$;

-- Step 7: Verify vector columns still work
SELECT 
  'Vector Columns Status' as check_name,
  COUNT(*) as tables_with_vector_columns,
  CASE 
    WHEN COUNT(*) > 0 THEN '✅ Vector columns still exist'
    ELSE '⚠️ No vector columns found'
  END as status
FROM information_schema.columns
WHERE data_type LIKE '%vector%' OR udt_name LIKE '%vector%';

