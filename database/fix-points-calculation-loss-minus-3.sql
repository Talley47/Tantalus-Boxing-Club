-- Fix Points Calculation: Ensure Loss = -3 (not -2)
-- This script ensures the database trigger correctly calculates Loss as -3 points
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
-- 2. Verify the trigger function uses calculate_fight_points
-- ============================================
-- The trigger should already be using calculate_fight_points function
-- This ensures consistency - the function will always return -3 for Loss

-- ============================================
-- 3. Test the function to verify it works correctly
-- ============================================
-- SELECT calculate_fight_points('Win', 'KO') as win_ko;      -- Should return 8 (5 + 3)
-- SELECT calculate_fight_points('Win', 'Decision') as win_dec; -- Should return 5
-- SELECT calculate_fight_points('Loss', 'KO') as loss_ko;     -- Should return -3 (not -2)
-- SELECT calculate_fight_points('Loss', 'Decision') as loss_dec; -- Should return -3 (not -2)
-- SELECT calculate_fight_points('Draw', 'Decision') as draw;   -- Should return 0

