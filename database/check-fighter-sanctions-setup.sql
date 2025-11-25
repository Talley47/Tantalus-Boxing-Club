-- Check if fighter_sanctions table exists and is set up correctly
-- Run this in Supabase SQL Editor to diagnose issues

-- Check if table exists
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM information_schema.tables 
            WHERE table_schema = 'public' 
            AND table_name = 'fighter_sanctions'
        ) THEN '✅ Table exists'
        ELSE '❌ Table does NOT exist - Run create-fighter-sanctions-table.sql'
    END AS table_status;

-- Check if RLS is enabled
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM pg_tables 
            WHERE schemaname = 'public' 
            AND tablename = 'fighter_sanctions'
        ) THEN 
            (SELECT 
                CASE 
                    WHEN relrowsecurity THEN '✅ RLS is enabled'
                    ELSE '❌ RLS is NOT enabled'
                END
            FROM pg_class 
            WHERE relname = 'fighter_sanctions')
        ELSE 'N/A - Table does not exist'
    END AS rls_status;

-- Check policies
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

-- Check current data (if table exists)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'fighter_sanctions'
    ) THEN
        RAISE NOTICE 'Current fighter_sanctions count: %', (
            SELECT COUNT(*) FROM public.fighter_sanctions
        );
    ELSE
        RAISE NOTICE 'Table does not exist - cannot check data';
    END IF;
END $$;

