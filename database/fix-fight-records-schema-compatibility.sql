-- Fix fight_records table schema compatibility issues
-- Ensures all optional columns exist and round can be nullable
-- Run this in Supabase SQL Editor

-- Make round nullable if it's currently NOT NULL
DO $$
BEGIN
    -- Check if round column exists and is NOT NULL
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'fight_records' 
        AND column_name = 'round'
        AND is_nullable = 'NO'
    ) THEN
        ALTER TABLE fight_records ALTER COLUMN round DROP NOT NULL;
        RAISE NOTICE 'Made round column nullable';
    END IF;
END $$;

-- Add is_tournament_win column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'fight_records' 
        AND column_name = 'is_tournament_win'
    ) THEN
        ALTER TABLE fight_records ADD COLUMN is_tournament_win BOOLEAN DEFAULT FALSE;
        CREATE INDEX IF NOT EXISTS idx_fight_records_tournament_win ON fight_records(is_tournament_win) WHERE is_tournament_win = true;
        RAISE NOTICE 'Added is_tournament_win column';
    END IF;
END $$;

-- Ensure points_earned has a default value
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'fight_records' 
        AND column_name = 'points_earned'
        AND column_default IS NULL
    ) THEN
        ALTER TABLE fight_records ALTER COLUMN points_earned SET DEFAULT 0;
        RAISE NOTICE 'Set default value for points_earned';
    END IF;
END $$;

-- Verify the table structure
DO $$
DECLARE
    col_count INTEGER;
    col RECORD;
BEGIN
    SELECT COUNT(*) INTO col_count
    FROM information_schema.columns
    WHERE table_name = 'fight_records';
    
    RAISE NOTICE 'fight_records table has % columns', col_count;
    RAISE NOTICE '';
    RAISE NOTICE 'Current fight_records columns:';
    FOR col IN 
        SELECT column_name, data_type, is_nullable, column_default
        FROM information_schema.columns
        WHERE table_name = 'fight_records'
        ORDER BY ordinal_position
    LOOP
        RAISE NOTICE '  - % (%) % DEFAULT %', 
            col.column_name, 
            col.data_type, 
            CASE WHEN col.is_nullable = 'YES' THEN 'NULL' ELSE 'NOT NULL' END,
            COALESCE(col.column_default, 'none');
    END LOOP;
    
    RAISE NOTICE '';
    RAISE NOTICE '✅ Fight records schema compatibility fixes applied!';
END $$;

