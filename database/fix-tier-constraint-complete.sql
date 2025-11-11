-- Complete Fix for Tier Constraint Mismatch
-- This script comprehensively fixes all tier-related issues
-- Run this in Supabase SQL Editor

-- ============================================
-- STEP 1: Find and Drop ALL Tier Constraints
-- ============================================
DO $$
DECLARE
    constraint_rec RECORD;
    dropped_count INTEGER := 0;
BEGIN
    RAISE NOTICE 'Step 1: Finding and dropping all tier constraints...';
    
    -- Find all check constraints on fighter_profiles that mention tier
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
        BEGIN
            EXECUTE 'ALTER TABLE fighter_profiles DROP CONSTRAINT ' || quote_ident(constraint_rec.conname) || ' CASCADE';
            RAISE NOTICE '  Dropped constraint: %', constraint_rec.conname;
            dropped_count := dropped_count + 1;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE '  Could not drop %: %', constraint_rec.conname, SQLERRM;
        END;
    END LOOP;
    
    IF dropped_count = 0 THEN
        RAISE NOTICE '  No tier constraints found to drop';
    ELSE
        RAISE NOTICE '  Total constraints dropped: %', dropped_count;
    END IF;
END $$;

-- ============================================
-- STEP 2: Ensure calculate_tier function exists
-- ============================================
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

-- ============================================
-- STEP 3: Fix ALL Existing Data
-- ============================================
DO $$
DECLARE
    updated_count INTEGER;
    invalid_count INTEGER;
BEGIN
    RAISE NOTICE 'Step 3: Updating existing fighter profiles...';
    
    -- Update all invalid tier values to valid ones
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
    WHERE tier IS NOT NULL 
    AND tier NOT IN ('Amateur', 'Semi-Pro', 'Pro', 'Contender', 'Elite');
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    RAISE NOTICE '  Updated % rows with invalid tier values', updated_count;
    
    -- Update NULL tiers
    UPDATE fighter_profiles
    SET tier = calculate_tier(COALESCE(points, 0))
    WHERE tier IS NULL;
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    IF updated_count > 0 THEN
        RAISE NOTICE '  Updated % rows with NULL tier values', updated_count;
    END IF;
    
    -- Verify no invalid tiers remain
    SELECT COUNT(*) INTO invalid_count
    FROM fighter_profiles
    WHERE tier IS NOT NULL 
    AND tier NOT IN ('Amateur', 'Semi-Pro', 'Pro', 'Contender', 'Elite');
    
    IF invalid_count > 0 THEN
        RAISE WARNING '  ⚠️ Still have % rows with invalid tier values!', invalid_count;
        -- Force update any remaining invalid values
        UPDATE fighter_profiles
        SET tier = 'Amateur'
        WHERE tier IS NOT NULL 
        AND tier NOT IN ('Amateur', 'Semi-Pro', 'Pro', 'Contender', 'Elite');
        RAISE NOTICE '  Force-updated remaining invalid tiers to Amateur';
    END IF;
END $$;

-- ============================================
-- STEP 4: Update Table Default
-- ============================================
DO $$
BEGIN
    ALTER TABLE fighter_profiles 
    ALTER COLUMN tier SET DEFAULT 'Amateur';
    RAISE NOTICE 'Step 4: Set default tier to Amateur';
END $$;

-- ============================================
-- STEP 5: Add New Constraint (NO CHECK constraint initially)
-- ============================================
-- First, try without CHECK to see if data is valid
DO $$
BEGIN
    -- Add constraint WITHOUT validating existing data first (PostgreSQL allows this)
    ALTER TABLE fighter_profiles
    ADD CONSTRAINT fighter_profiles_tier_check 
    CHECK (tier IS NULL OR tier IN ('Amateur', 'Semi-Pro', 'Pro', 'Contender', 'Elite'))
    NOT VALID;
    
    -- Now validate it (this will fail if any rows are invalid)
    ALTER TABLE fighter_profiles
    VALIDATE CONSTRAINT fighter_profiles_tier_check;
    
    RAISE NOTICE 'Step 5: ✅ Successfully added tier constraint';
EXCEPTION
    WHEN check_violation THEN
        RAISE WARNING '❌ Constraint validation failed - there are still invalid tier values';
        RAISE NOTICE 'Attempting to fix remaining invalid values...';
        
        -- Force fix any remaining issues
        UPDATE fighter_profiles
        SET tier = COALESCE(
            CASE 
                WHEN LOWER(tier) IN ('amateur', 'bronze') THEN 'Amateur'
                WHEN LOWER(tier) IN ('semi-pro', 'semi_pro', 'silver') THEN 'Semi-Pro'
                WHEN LOWER(tier) IN ('pro', 'gold') THEN 'Pro'
                WHEN LOWER(tier) IN ('contender', 'platinum') THEN 'Contender'
                WHEN LOWER(tier) IN ('elite', 'diamond', 'champion') THEN 'Elite'
                ELSE 'Amateur'
            END,
            'Amateur'
        )
        WHERE tier IS NOT NULL 
        AND tier NOT IN ('Amateur', 'Semi-Pro', 'Pro', 'Contender', 'Elite');
        
        -- Drop the NOT VALID constraint and try again
        ALTER TABLE fighter_profiles DROP CONSTRAINT IF EXISTS fighter_profiles_tier_check;
        
        -- Try again with VALID
        ALTER TABLE fighter_profiles
        ADD CONSTRAINT fighter_profiles_tier_check 
        CHECK (tier IS NULL OR tier IN ('Amateur', 'Semi-Pro', 'Pro', 'Contender', 'Elite'));
        
        RAISE NOTICE '✅ Constraint added after fixing invalid values';
    WHEN OTHERS THEN
        RAISE NOTICE 'Error: %', SQLERRM;
        -- Fallback: just add it without NOT VALID
        BEGIN
            ALTER TABLE fighter_profiles
            ADD CONSTRAINT fighter_profiles_tier_check 
            CHECK (tier IS NULL OR tier IN ('Amateur', 'Semi-Pro', 'Pro', 'Contender', 'Elite'));
            RAISE NOTICE '✅ Constraint added (fallback method)';
        EXCEPTION
            WHEN duplicate_object THEN
                RAISE NOTICE 'Constraint already exists';
        END;
END $$;

-- ============================================
-- STEP 6: Verify and Report
-- ============================================
DO $$
DECLARE
    total_fighters INTEGER;
    amateur_count INTEGER;
    semi_pro_count INTEGER;
    pro_count INTEGER;
    contender_count INTEGER;
    elite_count INTEGER;
    null_tier_count INTEGER;
    constraint_exists BOOLEAN;
    constraint_def TEXT;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE 'Step 6: Verification...';
    
    -- Check if constraint exists
    SELECT EXISTS(
        SELECT 1 FROM pg_constraint
        WHERE conrelid = 'fighter_profiles'::regclass
        AND conname = 'fighter_profiles_tier_check'
    ) INTO constraint_exists;
    
    IF constraint_exists THEN
        SELECT pg_get_constraintdef(oid) INTO constraint_def
        FROM pg_constraint
        WHERE conrelid = 'fighter_profiles'::regclass
        AND conname = 'fighter_profiles_tier_check';
        RAISE NOTICE '✅ Constraint exists: %', constraint_def;
    ELSE
        RAISE WARNING '❌ Constraint does not exist!';
    END IF;
    
    -- Stats
    SELECT COUNT(*) INTO total_fighters FROM fighter_profiles;
    SELECT COUNT(*) INTO amateur_count FROM fighter_profiles WHERE tier = 'Amateur';
    SELECT COUNT(*) INTO semi_pro_count FROM fighter_profiles WHERE tier = 'Semi-Pro';
    SELECT COUNT(*) INTO pro_count FROM fighter_profiles WHERE tier = 'Pro';
    SELECT COUNT(*) INTO contender_count FROM fighter_profiles WHERE tier = 'Contender';
    SELECT COUNT(*) INTO elite_count FROM fighter_profiles WHERE tier = 'Elite';
    SELECT COUNT(*) INTO null_tier_count FROM fighter_profiles WHERE tier IS NULL;
    
    RAISE NOTICE '';
    RAISE NOTICE 'Tier distribution:';
    RAISE NOTICE '  Total fighters: %', total_fighters;
    RAISE NOTICE '  Amateur: %', amateur_count;
    RAISE NOTICE '  Semi-Pro: %', semi_pro_count;
    RAISE NOTICE '  Pro: %', pro_count;
    RAISE NOTICE '  Contender: %', contender_count;
    RAISE NOTICE '  Elite: %', elite_count;
    RAISE NOTICE '  NULL: %', null_tier_count;
    RAISE NOTICE '';
    RAISE NOTICE '✅ Tier constraint fix complete!';
END $$;

