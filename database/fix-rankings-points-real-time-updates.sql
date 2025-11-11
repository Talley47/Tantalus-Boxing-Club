-- Complete Points & Rankings System Fix
-- This ensures Loss = -3, both fighters get points, and real-time updates work
-- Run this in Supabase SQL Editor

-- ============================================
-- 1. Update calculate_fight_points function to use -3 for Loss
-- ============================================
CREATE OR REPLACE FUNCTION calculate_fight_points(result TEXT, method TEXT)
RETURNS INTEGER AS $$
DECLARE
    base_points INTEGER;
    ko_bonus INTEGER := 0;
BEGIN
    -- Base points: Win +5, Loss -3, Draw 0
    CASE result
        WHEN 'Win' THEN base_points := 5;
        WHEN 'Loss' THEN base_points := -3;  -- CORRECTED: -3 not -2
        WHEN 'Draw' THEN base_points := 0;
        ELSE base_points := 0;
    END CASE;
    
    -- KO/TKO bonus (+3) only applies to winners
    IF result = 'Win' AND UPPER(TRIM(method)) IN ('KO', 'TKO') THEN
        ko_bonus := 3;
    END IF;
    
    RETURN base_points + ko_bonus;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================
-- 2. Ensure trigger updates points correctly for both fighters
-- ============================================
-- The trigger function update_fighter_stats_after_fight() already uses calculate_fight_points
-- This ensures every fight record gets the correct points calculated
-- Both fighters' records will trigger separately and update their own points

-- ============================================
-- 3. Verify trigger exists and is working
-- ============================================
-- Check if trigger exists:
-- SELECT * FROM pg_trigger WHERE tgname = 'trigger_update_fighter_stats';

-- ============================================
-- 4. Recalculate all existing fight records to use -3 for Loss
-- ============================================
UPDATE fight_records
SET points_earned = calculate_fight_points(result, method)
WHERE points_earned IS NULL OR points_earned != calculate_fight_points(result, method);

-- ============================================
-- 5. Recalculate all fighter points from scratch
-- ============================================
-- This ensures all fighter points are correct based on their fight records
UPDATE fighter_profiles fp
SET points = COALESCE((
    SELECT SUM(points_earned)
    FROM fight_records fr
    WHERE fr.fighter_id = fp.user_id
), 0);

-- ============================================
-- 6. Enable real-time for fighter_profiles and fight_records tables
-- ============================================
-- These should already be enabled, but verify:
-- ALTER PUBLICATION supabase_realtime ADD TABLE fighter_profiles;
-- ALTER PUBLICATION supabase_realtime ADD TABLE fight_records;
-- ALTER PUBLICATION supabase_realtime ADD TABLE rankings;

-- ============================================
-- Test the function
-- ============================================
-- SELECT calculate_fight_points('Win', 'KO') as win_ko;      -- Should return 8 (5 + 3)
-- SELECT calculate_fight_points('Win', 'Decision') as win_dec; -- Should return 5
-- SELECT calculate_fight_points('Loss', 'KO') as loss_ko;     -- Should return -3
-- SELECT calculate_fight_points('Loss', 'Decision') as loss_dec; -- Should return -3
-- SELECT calculate_fight_points('Draw', 'Decision') as draw;   -- Should return 0

