-- Add win_percentage and ko_percentage columns to fighter_profiles table
-- Run this in your Supabase SQL Editor

-- Add win_percentage column if it doesn't exist
ALTER TABLE fighter_profiles 
ADD COLUMN IF NOT EXISTS win_percentage DECIMAL(5,2) DEFAULT 0.00;

-- Add ko_percentage column if it doesn't exist
ALTER TABLE fighter_profiles 
ADD COLUMN IF NOT EXISTS ko_percentage DECIMAL(5,2) DEFAULT 0.00;

-- Update existing records to calculate percentages if they don't exist
UPDATE fighter_profiles fp
SET 
  win_percentage = CASE 
    WHEN (fp.wins + fp.losses + fp.draws) > 0 
    THEN ROUND((fp.wins::DECIMAL / (fp.wins + fp.losses + fp.draws) * 100)::NUMERIC, 2)
    ELSE 0.00 
  END,
  ko_percentage = CASE 
    WHEN fp.wins > 0 AND fp.knockouts IS NOT NULL
    THEN ROUND((fp.knockouts::DECIMAL / fp.wins * 100)::NUMERIC, 2)
    ELSE 0.00 
  END
WHERE fp.win_percentage IS NULL OR fp.ko_percentage IS NULL;

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✅ win_percentage and ko_percentage columns added to fighter_profiles table';
    RAISE NOTICE '✅ Existing records updated with calculated percentages';
END $$;

