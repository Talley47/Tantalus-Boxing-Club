-- Fix: Tier Constraint Violation Error
-- Error: "new row for relation "fighter_profiles" violates check constraint "fighter_profiles_tier_check""
-- 
-- The constraint expects: 'Amateur', 'Semi-Pro', 'Pro', 'Contender', 'Elite'
-- But code might be trying to set: 'bronze', 'silver', 'gold', etc. or lowercase versions
--
-- Run this in Supabase SQL Editor

-- Step 1: Check current constraint definition
SELECT 
    conname,
    pg_get_constraintdef(oid) as definition
FROM pg_constraint
WHERE conrelid = 'fighter_profiles'::regclass
AND conname = 'fighter_profiles_tier_check';

-- Step 2: Check for invalid tier values in the database
SELECT 
    tier,
    COUNT(*) as count
FROM fighter_profiles
WHERE tier IS NOT NULL
  AND tier NOT IN ('Amateur', 'Semi-Pro', 'Pro', 'Contender', 'Elite')
GROUP BY tier;

-- Step 3: Fix any invalid tier values
UPDATE fighter_profiles 
SET tier = 'Amateur' 
WHERE tier IS NULL 
   OR LOWER(COALESCE(tier, '')) IN ('', 'bronze', 'amateur', 'amateur');

UPDATE fighter_profiles 
SET tier = 'Semi-Pro' 
WHERE LOWER(tier) IN ('semi-pro', 'semi_pro', 'silver', 'semi pro');

UPDATE fighter_profiles 
SET tier = 'Pro' 
WHERE LOWER(tier) IN ('pro', 'gold');

UPDATE fighter_profiles 
SET tier = 'Contender' 
WHERE LOWER(tier) IN ('contender', 'platinum');

UPDATE fighter_profiles 
SET tier = 'Elite' 
WHERE LOWER(tier) IN ('elite', 'diamond', 'champion');

-- Step 4: Ensure constraint allows NULL (in case tier is optional)
-- First, drop existing constraint
ALTER TABLE fighter_profiles DROP CONSTRAINT IF EXISTS fighter_profiles_tier_check CASCADE;

-- Step 5: Recreate constraint with proper values and NULL support
ALTER TABLE fighter_profiles
ADD CONSTRAINT fighter_profiles_tier_check 
CHECK (tier IS NULL OR tier IN ('Amateur', 'Semi-Pro', 'Pro', 'Contender', 'Elite'));

-- Step 6: Set default tier if not set
ALTER TABLE fighter_profiles ALTER COLUMN tier SET DEFAULT 'Amateur';

-- Step 7: Update any remaining NULL tiers to default
UPDATE fighter_profiles 
SET tier = 'Amateur' 
WHERE tier IS NULL;

-- Step 8: Verify constraint
SELECT 
    conname,
    pg_get_constraintdef(oid) as definition
FROM pg_constraint
WHERE conrelid = 'fighter_profiles'::regclass
AND conname = 'fighter_profiles_tier_check';

-- Step 9: Verify all tier values are valid
SELECT 
    tier,
    COUNT(*) as count
FROM fighter_profiles
GROUP BY tier
ORDER BY tier;

-- Step 10: Check for any remaining invalid values
SELECT 
    id,
    name,
    tier
FROM fighter_profiles
WHERE tier IS NOT NULL
  AND tier NOT IN ('Amateur', 'Semi-Pro', 'Pro', 'Contender', 'Elite');

-- If Step 10 returns any rows, those need to be fixed manually

COMMENT ON CONSTRAINT fighter_profiles_tier_check ON fighter_profiles IS 
'Ensures tier is one of: Amateur, Semi-Pro, Pro, Contender, Elite. NULL values are allowed but will default to Amateur.';

