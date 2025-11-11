-- Enable real-time on all tables that need real-time updates
-- Run this in Supabase SQL Editor
-- This ensures that Supabase Realtime can send updates when data changes
-- This script is idempotent - it safely handles tables that are already enabled

-- Helper function to safely add table to publication
DO $$
DECLARE
    tbl_name TEXT;
    tables_to_enable TEXT[] := ARRAY[
        'fighter_profiles',
        'fight_records',
        'scheduled_fights',
        'tournaments',
        'training_camp_invitations',
        'callout_requests',
        'news_announcements',
        'fight_url_submissions'
    ];
BEGIN
    FOREACH tbl_name IN ARRAY tables_to_enable
    LOOP
        -- Check if table exists
        IF EXISTS (
            SELECT 1 FROM information_schema.tables 
            WHERE table_schema = 'public' 
            AND table_name = tbl_name
        ) THEN
            -- Check if table is already in publication
            IF NOT EXISTS (
                SELECT 1 FROM pg_publication_tables
                WHERE pubname = 'supabase_realtime'
                AND schemaname = 'public'
                AND tablename = tbl_name
            ) THEN
                -- Add table to publication
                EXECUTE format('ALTER PUBLICATION supabase_realtime ADD TABLE public.%I', tbl_name);
                RAISE NOTICE 'Real-time enabled on %', tbl_name;
            ELSE
                RAISE NOTICE 'Real-time already enabled on %', tbl_name;
            END IF;
        ELSE
            RAISE NOTICE 'Table % does not exist - skipping', tbl_name;
        END IF;
    END LOOP;
END $$;

-- Enable real-time on rankings (if it's a table, not a view)
-- Note: If rankings is a view, real-time will work on the underlying tables
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'rankings'
        AND table_type = 'BASE TABLE'
    ) THEN
        -- Check if rankings is already in publication
        IF NOT EXISTS (
            SELECT 1 FROM pg_publication_tables
            WHERE pubname = 'supabase_realtime'
            AND schemaname = 'public'
            AND tablename = 'rankings'
        ) THEN
            ALTER PUBLICATION supabase_realtime ADD TABLE public.rankings;
            RAISE NOTICE 'Real-time enabled on rankings table';
        ELSE
            RAISE NOTICE 'Real-time already enabled on rankings table';
        END IF;
    ELSE
        RAISE NOTICE 'rankings is a view - real-time will work on underlying tables (fighter_profiles, fight_records)';
    END IF;
END $$;

-- Verify which tables are enabled for real-time
SELECT 
    schemaname,
    tablename
FROM pg_publication_tables
WHERE pubname = 'supabase_realtime'
ORDER BY tablename;

-- Note: If you get an error that a table doesn't exist, that's okay - 
-- it means that table hasn't been created yet or has a different name.
-- The important tables for real-time updates are:
-- - fighter_profiles (points, tier, weight_class changes)
-- - fight_records (new records added)
-- - scheduled_fights (status changes)

COMMENT ON PUBLICATION supabase_realtime IS 'Real-time enabled for fighter_profiles, fight_records, scheduled_fights, and other tables that need live updates';

