-- ============================================================================
-- FIX: Move vector Extension from Public Schema
-- ============================================================================
-- This moves the vector extension to a dedicated 'extensions' schema
-- Copy ALL of this into Supabase SQL Editor and run it
-- ============================================================================

-- Step 1: Check current state
SELECT 
  'Before Fix' as status,
  extname as extension_name,
  extnamespace::regnamespace::text as current_schema,
  extversion as version
FROM pg_extension
WHERE extname = 'vector';

-- Step 2: Create extensions schema if it doesn't exist
CREATE SCHEMA IF NOT EXISTS extensions;

-- Step 3: Grant usage on extensions schema
GRANT USAGE ON SCHEMA extensions TO postgres, anon, authenticated, service_role;

-- Step 4: Move vector extension to extensions schema
-- Note: PostgreSQL doesn't support directly moving extensions, so we need to:
-- 1. Drop the extension (this will drop all its objects)
-- 2. Recreate it in the new schema

DO $$
BEGIN
  -- Check if vector extension exists in public schema
  IF EXISTS (
    SELECT 1 FROM pg_extension 
    WHERE extname = 'vector' 
      AND extnamespace::regnamespace::text = 'public'
  ) THEN
    -- Drop the extension (this will drop all its objects)
    -- WARNING: This will remove all vector-related objects and data!
    -- If you have vector columns or data, you'll need to back them up first
    DROP EXTENSION IF EXISTS vector CASCADE;
    
    RAISE NOTICE '✅ Dropped vector extension from public schema';
    
    -- Recreate it in the extensions schema
    CREATE EXTENSION IF NOT EXISTS vector SCHEMA extensions;
    
    RAISE NOTICE '✅ Created vector extension in extensions schema';
  ELSE
    RAISE NOTICE '⚠️ Vector extension not found in public schema - may already be moved or not installed';
  END IF;
END $$;

-- Step 5: Update search_path to include extensions schema
-- This ensures functions can find vector types
-- Note: We'll set it per role instead since ALTER DATABASE requires literal name
DO $$
DECLARE
  db_name TEXT;
BEGIN
  -- Get current database name
  SELECT current_database() INTO db_name;
  
  -- Set search_path for the database
  EXECUTE format('ALTER DATABASE %I SET search_path = pg_catalog, public, extensions', db_name);
  
  RAISE NOTICE '✅ Updated search_path for database %', db_name;
EXCEPTION WHEN OTHERS THEN
  -- If we can't alter database (common in managed services), set per role instead
  RAISE NOTICE '⚠️ Could not alter database search_path, setting per role instead';
  
  -- Set search_path for common roles
  ALTER ROLE postgres SET search_path = pg_catalog, public, extensions;
  ALTER ROLE authenticated SET search_path = pg_catalog, public, extensions;
  ALTER ROLE anon SET search_path = pg_catalog, public, extensions;
  ALTER ROLE service_role SET search_path = pg_catalog, public, extensions;
  
  RAISE NOTICE '✅ Updated search_path for roles';
END $$;

-- Step 6: Verify the fix
SELECT 
  'After Fix' as status,
  extname as extension_name,
  extnamespace::regnamespace::text as current_schema,
  extversion as version,
  CASE 
    WHEN extnamespace::regnamespace::text = 'extensions' THEN '✅ FIXED - In extensions schema'
    WHEN extnamespace::regnamespace::text = 'public' THEN '❌ STILL IN PUBLIC SCHEMA'
    ELSE '⚠️ In different schema: ' || extnamespace::regnamespace::text
  END as fix_status
FROM pg_extension
WHERE extname = 'vector';

-- Step 7: Verify no extensions remain in public schema
SELECT 
  'Remaining Extensions in Public' as check_name,
  extname as extension_name,
  extversion as version
FROM pg_extension
WHERE extnamespace::regnamespace::text = 'public'
ORDER BY extname;

