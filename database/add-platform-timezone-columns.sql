-- Add platform and timezone columns to fighter_profiles table
-- These fields are collected during registration and should be part of fighter physical information
-- Run this in Supabase SQL Editor

-- Add platform column (optional, with constraint for valid values)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'fighter_profiles' 
        AND column_name = 'platform'
    ) THEN
        ALTER TABLE public.fighter_profiles
        ADD COLUMN platform VARCHAR(10) CHECK (platform IN ('PSN', 'Xbox', 'PC'));
        
        COMMENT ON COLUMN public.fighter_profiles.platform IS 'Gaming platform: PSN, Xbox, or PC';
    END IF;
END $$;

-- Add timezone column (optional)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'fighter_profiles' 
        AND column_name = 'timezone'
    ) THEN
        ALTER TABLE public.fighter_profiles
        ADD COLUMN timezone VARCHAR(50);
        
        COMMENT ON COLUMN public.fighter_profiles.timezone IS 'Fighter timezone (e.g., America/New_York, UTC)';
    END IF;
END $$;

-- Verify columns were added
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
AND table_name = 'fighter_profiles'
AND column_name IN ('platform', 'timezone')
ORDER BY column_name;

