-- Add knockouts column to fighter_profiles table
-- Run this in your Supabase SQL Editor

-- Add knockouts column if it doesn't exist
ALTER TABLE fighter_profiles 
ADD COLUMN IF NOT EXISTS knockouts INTEGER DEFAULT 0;

-- Update existing records to have 0 knockouts if NULL
UPDATE fighter_profiles 
SET knockouts = 0 
WHERE knockouts IS NULL;

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✅ knockouts column added to fighter_profiles table';
END $$;

