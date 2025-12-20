-- =====================================================
-- COMPREHENSIVE CHECK AND FIX FOR FIGHTER_PROFILES RLS
-- Run this ENTIRE script in Supabase SQL Editor
-- =====================================================

-- STEP 1: Check if RLS is enabled
SELECT 
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename = 'fighter_profiles';

-- STEP 2: List all existing policies
SELECT 
    policyname,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename = 'fighter_profiles'
ORDER BY policyname;

-- STEP 3: Check data count (as postgres superuser - bypasses RLS)
SET ROLE postgres;
SELECT COUNT(*) as total_rows FROM fighter_profiles;
SELECT COUNT(*) as rows_with_user_id FROM fighter_profiles WHERE user_id IS NOT NULL;
RESET ROLE;

-- STEP 4: Drop ALL existing policies (clean slate)
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
        RAISE NOTICE '✅ Dropped policy: %', r.policyname;
    END LOOP;
    
    IF NOT FOUND THEN
        RAISE NOTICE 'ℹ️ No existing policies to drop';
    END IF;
END $$;

-- STEP 5: Ensure RLS is enabled
ALTER TABLE fighter_profiles ENABLE ROW LEVEL SECURITY;

-- STEP 6: Create permissive policies for both roles
CREATE POLICY "Authenticated users can view all fighter profiles" 
ON fighter_profiles
FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Anonymous users can view all fighter profiles" 
ON fighter_profiles
FOR SELECT
TO anon
USING (true);

-- STEP 7: Verify the fix worked
SELECT 
    '✅ VERIFICATION' as status,
    policyname,
    roles,
    cmd
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename = 'fighter_profiles'
ORDER BY policyname;

-- STEP 8: Test query as authenticated user (simulate what your app does)
SET ROLE authenticated;
SELECT COUNT(*) as visible_rows_as_authenticated FROM fighter_profiles;
SELECT user_id, name, handle FROM fighter_profiles LIMIT 3;
RESET ROLE;

-- Done! If you see rows in step 8, the fix worked.
-- Now refresh your app and fighters should appear.

