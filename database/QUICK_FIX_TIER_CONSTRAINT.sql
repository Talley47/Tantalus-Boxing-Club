-- QUICK FIX: Tier Constraint Violation
-- Copy and paste this ENTIRE script into Supabase SQL Editor
-- Do NOT copy the browser error message - only copy this SQL

-- Step 1: Fix any invalid tier values in the database
UPDATE fighter_profiles 
SET tier = 'Amateur' 
WHERE tier IS NULL 
   OR LOWER(COALESCE(tier, '')) IN ('', 'bronze', 'amateur');

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

-- Step 2: Drop the old constraint
ALTER TABLE fighter_profiles 
DROP CONSTRAINT IF EXISTS fighter_profiles_tier_check CASCADE;

-- Step 3: Recreate the constraint with correct values
ALTER TABLE fighter_profiles
ADD CONSTRAINT fighter_profiles_tier_check 
CHECK (tier IS NULL OR tier IN ('Amateur', 'Semi-Pro', 'Pro', 'Contender', 'Elite'));

-- Step 4: Set default tier
ALTER TABLE fighter_profiles 
ALTER COLUMN tier SET DEFAULT 'Amateur';

-- Step 5: Update any remaining NULL tiers
UPDATE fighter_profiles 
SET tier = 'Amateur' 
WHERE tier IS NULL;

-- Step 6: Verify the fix
SELECT 
    tier,
    COUNT(*) as count
FROM fighter_profiles
GROUP BY tier
ORDER BY tier;

-- If you see any tier values other than: Amateur, Semi-Pro, Pro, Contender, Elite
-- Those need to be fixed manually

