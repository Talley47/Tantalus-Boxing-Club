-- =====================================================
-- IMMEDIATE FIX: Fix fighter_profiles RLS Policy
-- Run this in Supabase SQL Editor RIGHT NOW
-- =====================================================

-- Step 1: Check current state
SELECT 
    'Current RLS Status' as check_type,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename = 'fighter_profiles';

-- Step 2: List all existing policies
SELECT 
    'Existing Policies' as check_type,
    policyname,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename = 'fighter_profiles';

-- Step 3: Check if data exists (as postgres superuser)
SET ROLE postgres;
SELECT 
    'Data Check' as check_type,
    COUNT(*) as total_rows,
    COUNT(user_id) as rows_with_user_id,
    COUNT(*) FILTER (WHERE user_id IS NULL) as rows_with_null_user_id
FROM fighter_profiles;
RESET ROLE;

-- Step 4: Enable RLS (if not already enabled)
ALTER TABLE fighter_profiles ENABLE ROW LEVEL SECURITY;

-- Step 5: Drop ALL existing policies on fighter_profiles
-- (This ensures we start fresh)
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
        EXECUTE format('DROP POLICY IF EXISTS %I ON fighter_profiles', r.policyname);
        RAISE NOTICE 'Dropped policy: %', r.policyname;
    END LOOP;
END $$;

-- Step 6: Create a simple, permissive SELECT policy for authenticated users
CREATE POLICY "Authenticated users can view all fighter profiles" 
ON fighter_profiles
FOR SELECT
TO authenticated
USING (true);

-- Step 7: Also allow anon users (if needed for public pages)
CREATE POLICY "Anonymous users can view all fighter profiles" 
ON fighter_profiles
FOR SELECT
TO anon
USING (true);

-- Step 8: Verify the policies were created
SELECT 
    'New Policies' as check_type,
    policyname,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename = 'fighter_profiles'
ORDER BY policyname;

-- Step 9: Test query as authenticated user
SET ROLE authenticated;
SELECT 
    'Test Query Result' as check_type,
    COUNT(*) as visible_rows
FROM fighter_profiles;
SELECT user_id, name, handle 
FROM fighter_profiles 
WHERE user_id IS NOT NULL
LIMIT 5;
RESET ROLE;

-- =====================================================
-- If you still see 0 rows after running this:
-- 1. The table might be empty - check with: SELECT COUNT(*) FROM fighter_profiles;
-- 2. All fighters might have user_id = NULL - check with: SELECT COUNT(*) FROM fighter_profiles WHERE user_id IS NULL;
-- 3. There might be a database-level view or function filtering data
-- =====================================================

