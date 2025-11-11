-- Fix Points Calculation: Loss should be -2, not -3
-- This ensures consistency with the requirements:
-- Win = +5, Loss = -2, Draw = 0, KO/TKO bonus = +3 (only for winners)

-- ============================================
-- 1. Fix calculate_fight_points function
-- ============================================
CREATE OR REPLACE FUNCTION calculate_fight_points(result TEXT, method TEXT)
RETURNS INTEGER AS $$
DECLARE
    base_points INTEGER;
    ko_bonus INTEGER := 0;
BEGIN
    -- Base points: Win +5, Loss -2, Draw 0
    CASE result
        WHEN 'Win' THEN base_points := 5;
        WHEN 'Loss' THEN base_points := -2;  -- FIXED: Changed from -3 to -2
        WHEN 'Draw' THEN base_points := 0;
        ELSE base_points := 0;
    END CASE;
    
    -- KO/TKO bonus (+3) ONLY applies to winners, not losers
    IF result = 'Win' AND UPPER(TRIM(method)) IN ('KO', 'TKO') THEN
        ko_bonus := 3;
    END IF;
    
    RETURN base_points + ko_bonus;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================
-- 2. Verify the function works correctly
-- ============================================
-- Test cases:
-- SELECT calculate_fight_points('Win', 'Decision');  -- Should return 5
-- SELECT calculate_fight_points('Win', 'KO');        -- Should return 8 (5 + 3)
-- SELECT calculate_fight_points('Loss', 'Decision'); -- Should return -2
-- SELECT calculate_fight_points('Loss', 'TKO');      -- Should return -2 (no bonus for losers)
-- SELECT calculate_fight_points('Draw', 'Decision'); -- Should return 0

-- ============================================
-- 3. Update existing fight records with incorrect points
-- ============================================
-- This will recalculate points for all existing fight records
UPDATE fight_records
SET points_earned = calculate_fight_points(result, method)
WHERE points_earned != calculate_fight_points(result, method);

-- ============================================
-- 4. Recalculate all fighter points from scratch
-- ============================================
-- This ensures all fighter points are correct based on their fight records
UPDATE fighter_profiles
SET points = COALESCE((
    SELECT SUM(points_earned)
    FROM fight_records
    WHERE fighter_id = fighter_profiles.user_id
), 0);

-- ============================================
-- 5. Update tiers based on corrected points
-- ============================================
UPDATE fighter_profiles
SET tier = CASE
    WHEN points >= 280 THEN 'Elite'
    WHEN points >= 140 THEN 'Contender'
    WHEN points >= 70 THEN 'Pro'
    WHEN points >= 30 THEN 'Semi-Pro'
    ELSE 'Amateur'
END
WHERE tier IS NOT NULL;

-- ============================================
-- 6. Verify the trigger function uses calculate_fight_points
-- ============================================
-- The trigger should already be using calculate_fight_points, but verify:
-- SELECT pg_get_functiondef(oid) FROM pg_proc WHERE proname = 'update_fighter_stats_after_fight';

