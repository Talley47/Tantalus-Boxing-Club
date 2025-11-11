-- Diagnostic script to check fighter_profiles access issues
-- Run this in Supabase SQL Editor

-- 1. Check if table exists and count fighters
DO $$
DECLARE
    fighter_count INTEGER;
    has_table BOOLEAN;
BEGIN
    -- Check if table exists
    SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'fighter_profiles'
    ) INTO has_table;
    
    IF has_table THEN
        SELECT COUNT(*) INTO fighter_count FROM fighter_profiles;
        RAISE NOTICE '═══════════════════════════════════════';
        RAISE NOTICE 'Fighter Profiles Diagnostic';
        RAISE NOTICE '═══════════════════════════════════════';
        RAISE NOTICE 'Table exists: YES';
        RAISE NOTICE 'Total fighters: %', fighter_count;
        RAISE NOTICE '═══════════════════════════════════════';
        
        IF fighter_count = 0 THEN
            RAISE WARNING '⚠ Table is EMPTY - No fighter profiles exist';
        ELSE
            RAISE NOTICE '✓ Data exists - Issue is likely RLS policies';
        END IF;
    ELSE
        RAISE WARNING '⚠ Table fighter_profiles does NOT exist!';
    END IF;
END $$;

-- 2. Check RLS status
SELECT 
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename = 'fighter_profiles';

-- 3. List all RLS policies on fighter_profiles
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd as command,
    qual as using_expression,
    with_check as with_check_expression
FROM pg_policies 
WHERE tablename = 'fighter_profiles'
ORDER BY policyname;

-- 4. Check if there's a public read policy
DO $$
DECLARE
    has_public_read BOOLEAN;
    has_authenticated_read BOOLEAN;
BEGIN
    -- Check for public read policy
    SELECT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'fighter_profiles' 
        AND cmd = 'SELECT'
        AND (qual LIKE '%true%' OR qual IS NULL)
    ) INTO has_public_read;
    
    -- Check for authenticated read policy
    SELECT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'fighter_profiles' 
        AND cmd = 'SELECT'
        AND (qual LIKE '%auth.uid()%' OR qual LIKE '%authenticated%')
    ) INTO has_authenticated_read;
    
    RAISE NOTICE '═══════════════════════════════════════';
    RAISE NOTICE 'RLS Policy Check';
    RAISE NOTICE '═══════════════════════════════════════';
    
    IF has_public_read THEN
        RAISE NOTICE '✓ Public read policy exists';
    ELSE
        RAISE WARNING '⚠ No public read policy found';
    END IF;
    
    IF has_authenticated_read THEN
        RAISE NOTICE '✓ Authenticated read policy exists';
    ELSE
        RAISE WARNING '⚠ No authenticated read policy found';
    END IF;
    
    IF NOT has_public_read AND NOT has_authenticated_read THEN
        RAISE WARNING '⚠ NO READ POLICIES FOUND - This will block all queries!';
    END IF;
    
    RAISE NOTICE '═══════════════════════════════════════';
END $$;

-- 5. Show sample fighters (if any exist)
SELECT 
    id,
    user_id,
    name,
    handle,
    tier,
    points,
    weight_class,
    wins,
    losses,
    draws
FROM fighter_profiles
ORDER BY points DESC
LIMIT 5;

-- 6. Fix script - Create public read policy if missing
DO $$
BEGIN
    -- Check if a public read policy exists
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'fighter_profiles' 
        AND policyname = 'Public can view all fighter profiles'
    ) THEN
        RAISE NOTICE '═══════════════════════════════════════';
        RAISE NOTICE 'Creating public read policy...';
        RAISE NOTICE '═══════════════════════════════════════';
        
        -- Drop any existing policies first
        DROP POLICY IF EXISTS "Public can view all fighter profiles" ON fighter_profiles;
        DROP POLICY IF EXISTS "Anyone can view fighter profiles" ON fighter_profiles;
        DROP POLICY IF EXISTS "Public read access" ON fighter_profiles;
        
        -- Create new public read policy
        CREATE POLICY "Public can view all fighter profiles" ON fighter_profiles
            FOR SELECT
            USING (true);  -- Allow anyone to read
        
        RAISE NOTICE '✓ Created public read policy';
        RAISE NOTICE '═══════════════════════════════════════';
    ELSE
        RAISE NOTICE '✓ Public read policy already exists';
    END IF;
END $$;

-- 7. Final check - try to query as if from the app
SELECT 
    user_id,
    name,
    handle,
    tier,
    points,
    weight_class,
    wins,
    losses,
    draws
FROM fighter_profiles
WHERE user_id IS NOT NULL
ORDER BY points DESC
LIMIT 5;

