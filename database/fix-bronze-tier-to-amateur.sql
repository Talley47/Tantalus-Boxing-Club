-- Fix fighters with 'bronze' tier to 'amateur'
-- This script updates existing fighters who were incorrectly set to 'bronze' tier
-- Run this in Supabase SQL Editor

-- Update all fighters with 'bronze' tier to 'amateur'
-- Only update fighters who have 0 points and 0 wins (new fighters)
UPDATE fighter_profiles
SET tier = 'amateur'
WHERE tier = 'bronze'
  AND points = 0
  AND wins = 0
  AND losses = 0
  AND draws = 0;

-- Also update any fighters with 'bronze' tier regardless of stats
-- (in case there are any edge cases)
UPDATE fighter_profiles
SET tier = 'amateur'
WHERE tier = 'bronze';

-- Verify the update
SELECT 
  id,
  name,
  handle,
  tier,
  points,
  wins,
  losses,
  draws,
  created_at
FROM fighter_profiles
WHERE tier = 'bronze'
ORDER BY created_at DESC;

-- If the above query returns 0 rows, all fighters have been updated successfully

