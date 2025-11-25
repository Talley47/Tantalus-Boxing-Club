-- Verify Fighter Sanctions Table Setup
-- Run this to check if the table exists and RLS policies are correct

-- Check if table exists
DO $$
BEGIN
    IF EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'fighter_sanctions'
    ) THEN
        RAISE NOTICE '✅ Table fighter_sanctions exists';
    ELSE
        RAISE WARNING '❌ Table fighter_sanctions does NOT exist!';
        RAISE WARNING '   Run: database/create-fighter-sanctions-table.sql';
    END IF;
END $$;

-- Check RLS is enabled
DO $$
BEGIN
    IF EXISTS (
        SELECT FROM pg_tables 
        WHERE schemaname = 'public' 
        AND tablename = 'fighter_sanctions'
        AND rowsecurity = true
    ) THEN
        RAISE NOTICE '✅ RLS is enabled on fighter_sanctions';
    ELSE
        RAISE WARNING '❌ RLS is NOT enabled on fighter_sanctions!';
    END IF;
END $$;

-- List all policies
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE tablename = 'fighter_sanctions'
ORDER BY policyname;

-- Check indexes
SELECT 
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename = 'fighter_sanctions'
ORDER BY indexname;

-- Test query (should work if everything is set up)
SELECT COUNT(*) as total_sanctions
FROM fighter_sanctions;

-- Success message
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '✅ Verification complete!';
    RAISE NOTICE '   If you see errors above, run: database/create-fighter-sanctions-table.sql';
END $$;

