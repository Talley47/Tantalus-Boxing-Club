-- Simple Fix for Tier Constraint
-- Run this in Supabase SQL Editor

-- Step 1: See what the constraint currently expects
SELECT 
    conname,
    pg_get_constraintdef(oid) as definition
FROM pg_constraint
WHERE conrelid = 'fighter_profiles'::regclass
AND conname = 'fighter_profiles_tier_check';

-- Step 2: Drop the constraint
ALTER TABLE fighter_profiles DROP CONSTRAINT IF EXISTS fighter_profiles_tier_check CASCADE;

-- Step 3: Update existing data
UPDATE fighter_profiles SET tier = 'Amateur' WHERE tier IS NULL OR LOWER(COALESCE(tier, '')) IN ('', 'bronze', 'amateur');
UPDATE fighter_profiles SET tier = 'Semi-Pro' WHERE LOWER(tier) IN ('semi-pro', 'semi_pro', 'silver');
UPDATE fighter_profiles SET tier = 'Pro' WHERE LOWER(tier) IN ('pro', 'gold');
UPDATE fighter_profiles SET tier = 'Contender' WHERE LOWER(tier) IN ('contender', 'platinum');
UPDATE fighter_profiles SET tier = 'Elite' WHERE LOWER(tier) IN ('elite', 'diamond', 'champion');

-- Step 4: Set default
ALTER TABLE fighter_profiles ALTER COLUMN tier SET DEFAULT 'Amateur';

-- Step 5: Create new constraint
ALTER TABLE fighter_profiles
ADD CONSTRAINT fighter_profiles_tier_check 
CHECK (tier IN ('Amateur', 'Semi-Pro', 'Pro', 'Contender', 'Elite'));

-- Step 6: Verify
SELECT 
    conname,
    pg_get_constraintdef(oid) as definition
FROM pg_constraint
WHERE conrelid = 'fighter_profiles'::regclass
AND conname = 'fighter_profiles_tier_check';

