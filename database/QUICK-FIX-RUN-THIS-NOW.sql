-- =====================================================
-- QUICK FIX - Run this RIGHT NOW in Supabase SQL Editor
-- This will fix the RLS issue immediately
-- =====================================================

-- Step 1: Drop ALL existing policies (they're blocking access)
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
END $$;

-- Step 2: Create a simple policy that allows ALL authenticated users to see ALL rows
CREATE POLICY "Authenticated users can view all fighter profiles" 
ON fighter_profiles
FOR SELECT
TO authenticated
USING (true);

-- Step 3: Also allow anonymous users (for public pages)
CREATE POLICY "Anonymous users can view all fighter profiles" 
ON fighter_profiles
FOR SELECT
TO anon
USING (true);

-- Step 4: Verify it worked
SELECT 
    '✅ Policies Created' as status,
    policyname,
    roles,
    cmd
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename = 'fighter_profiles'
ORDER BY policyname;

-- Done! Now refresh your app and fighters should appear.

