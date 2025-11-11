-- Fix Tier Constraint Mismatch
-- The calculate_tier function returns 'Amateur', 'Semi-Pro', 'Pro', 'Contender', 'Elite'
-- But the table constraint might have different values
-- This script ensures the constraint matches the function output

-- First, check and drop ALL existing tier constraints
DO $$
DECLARE
    constraint_rec RECORD;
BEGIN
    RAISE NOTICE 'Checking for existing tier constraints...';
    
    -- Find all check constraints on fighter_profiles that might be related to tier
    FOR constraint_rec IN
        SELECT conname, pg_get_constraintdef(oid) as def
        FROM pg_constraint
        WHERE conrelid = 'fighter_profiles'::regclass
        AND contype = 'c'
        AND (
            conname LIKE '%tier%' 
            OR pg_get_constraintdef(oid) LIKE '%tier%'
        )
    LOOP
        RAISE NOTICE 'Found constraint: % = %', constraint_rec.conname, constraint_rec.def;
        EXECUTE 'ALTER TABLE fighter_profiles DROP CONSTRAINT IF EXISTS ' || quote_ident(constraint_rec.conname);
        RAISE NOTICE '  Dropped constraint: %', constraint_rec.conname;
    END LOOP;
    
    IF NOT FOUND THEN
        RAISE NOTICE 'No tier constraints found';
    END IF;
END $$;

-- Ensure calculate_tier function exists (it should from fix-rankings-points-tier-system.sql)
-- If not, create a simple version
CREATE OR REPLACE FUNCTION calculate_tier(points INTEGER)
RETURNS TEXT AS $$
BEGIN
    IF points >= 280 THEN
        RETURN 'Elite';
    ELSIF points >= 140 THEN
        RETURN 'Contender';
    ELSIF points >= 70 THEN
        RETURN 'Pro';
    ELSIF points >= 30 THEN
        RETURN 'Semi-Pro';
    ELSE
        RETURN 'Amateur';
    END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- STEP 1: Update all existing fighter profiles to have valid tier values
-- Map any invalid/lowercase tier values to the correct capitalized format
UPDATE fighter_profiles
SET tier = CASE
    -- Map lowercase or old tier names to correct capitalized values
    WHEN LOWER(tier) IN ('amateur', 'bronze') THEN 'Amateur'
    WHEN LOWER(tier) IN ('semi-pro', 'semi_pro', 'silver') THEN 'Semi-Pro'
    WHEN LOWER(tier) IN ('pro', 'gold') THEN 'Pro'
    WHEN LOWER(tier) IN ('contender', 'platinum') THEN 'Contender'
    WHEN LOWER(tier) IN ('elite', 'diamond', 'champion') THEN 'Elite'
    -- If tier is already correct, keep it
    WHEN tier IN ('Amateur', 'Semi-Pro', 'Pro', 'Contender', 'Elite') THEN tier
    -- For any other invalid values, recalculate based on points
    ELSE calculate_tier(COALESCE(points, 0))
END
WHERE tier IS NOT NULL;

-- Also update any NULL tiers based on points
UPDATE fighter_profiles
SET tier = calculate_tier(COALESCE(points, 0))
WHERE tier IS NULL;

-- STEP 2: Change the default tier value to 'Amateur'
-- This ensures new fighter profiles get the correct default tier
ALTER TABLE fighter_profiles 
ALTER COLUMN tier SET DEFAULT 'Amateur';

-- STEP 3: Drop ALL possible tier constraint names (comprehensive cleanup)
-- Some databases might have different constraint names
DO $$
BEGIN
    ALTER TABLE fighter_profiles DROP CONSTRAINT IF EXISTS fighter_profiles_tier_check;
    ALTER TABLE fighter_profiles DROP CONSTRAINT IF EXISTS fighter_profiles_tier_check_old;
    ALTER TABLE fighter_profiles DROP CONSTRAINT IF EXISTS check_tier;
    ALTER TABLE fighter_profiles DROP CONSTRAINT IF EXISTS tier_check;
    RAISE NOTICE 'Dropped all existing tier constraints';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error dropping constraints (may not exist): %', SQLERRM;
END $$;

-- STEP 4: Add the correct tier constraint matching the calculate_tier function output
-- These values match what calculate_tier returns: 'Amateur', 'Semi-Pro', 'Pro', 'Contender', 'Elite'
ALTER TABLE fighter_profiles
ADD CONSTRAINT fighter_profiles_tier_check 
CHECK (tier IN ('Amateur', 'Semi-Pro', 'Pro', 'Contender', 'Elite'));

-- Verify the constraint was added and show stats
DO $$
DECLARE
    total_fighters INTEGER;
    amateur_count INTEGER;
    semi_pro_count INTEGER;
    pro_count INTEGER;
    contender_count INTEGER;
    elite_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO total_fighters FROM fighter_profiles;
    SELECT COUNT(*) INTO amateur_count FROM fighter_profiles WHERE tier = 'Amateur';
    SELECT COUNT(*) INTO semi_pro_count FROM fighter_profiles WHERE tier = 'Semi-Pro';
    SELECT COUNT(*) INTO pro_count FROM fighter_profiles WHERE tier = 'Pro';
    SELECT COUNT(*) INTO contender_count FROM fighter_profiles WHERE tier = 'Contender';
    SELECT COUNT(*) INTO elite_count FROM fighter_profiles WHERE tier = 'Elite';
    
    RAISE NOTICE '✅ Tier constraint updated to match calculate_tier function output';
    RAISE NOTICE '   Allowed values: Amateur, Semi-Pro, Pro, Contender, Elite';
    RAISE NOTICE '';
    RAISE NOTICE 'Fighter tier distribution:';
    RAISE NOTICE '  Total fighters: %', total_fighters;
    RAISE NOTICE '  Amateur: %', amateur_count;
    RAISE NOTICE '  Semi-Pro: %', semi_pro_count;
    RAISE NOTICE '  Pro: %', pro_count;
    RAISE NOTICE '  Contender: %', contender_count;
    RAISE NOTICE '  Elite: %', elite_count;
END $$;

