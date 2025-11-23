-- Complete Point System Verification & Fix
-- Ensures: Win = +5, Loss = -3, Draw = 0, KO/TKO Bonus = +3
-- Run this in Supabase SQL Editor

-- ============================================
-- 1. VERIFY & FIX POINTS CALCULATION FUNCTION
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
        WHEN 'Loss' THEN base_points := -3;  -- CORRECT: Loss = -3
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
-- 2. TEST POINTS CALCULATION
-- ============================================
DO $$
BEGIN
    -- Test Win + Decision = 5
    IF calculate_fight_points('Win', 'Decision') != 5 THEN
        RAISE EXCEPTION 'FAIL: Win + Decision should be 5, got %', calculate_fight_points('Win', 'Decision');
    END IF;
    
    -- Test Win + KO = 8 (5 + 3)
    IF calculate_fight_points('Win', 'KO') != 8 THEN
        RAISE EXCEPTION 'FAIL: Win + KO should be 8, got %', calculate_fight_points('Win', 'KO');
    END IF;
    
    -- Test Win + TKO = 8 (5 + 3)
    IF calculate_fight_points('Win', 'TKO') != 8 THEN
        RAISE EXCEPTION 'FAIL: Win + TKO should be 8, got %', calculate_fight_points('Win', 'TKO');
    END IF;
    
    -- Test Loss + Decision = -3
    IF calculate_fight_points('Loss', 'Decision') != -3 THEN
        RAISE EXCEPTION 'FAIL: Loss + Decision should be -3, got %', calculate_fight_points('Loss', 'Decision');
    END IF;
    
    -- Test Loss + KO = -3 (no bonus for losers)
    IF calculate_fight_points('Loss', 'KO') != -3 THEN
        RAISE EXCEPTION 'FAIL: Loss + KO should be -3 (no bonus), got %', calculate_fight_points('Loss', 'KO');
    END IF;
    
    -- Test Loss + TKO = -3 (no bonus for losers)
    IF calculate_fight_points('Loss', 'TKO') != -3 THEN
        RAISE EXCEPTION 'FAIL: Loss + TKO should be -3 (no bonus), got %', calculate_fight_points('Loss', 'TKO');
    END IF;
    
    -- Test Draw = 0
    IF calculate_fight_points('Draw', 'Decision') != 0 THEN
        RAISE EXCEPTION 'FAIL: Draw should be 0, got %', calculate_fight_points('Draw', 'Decision');
    END IF;
    
    RAISE NOTICE '✅ All points calculation tests PASSED!';
END $$;

-- ============================================
-- 3. FIX ALL FIGHT RECORDS
-- ============================================
-- Update points_earned for all fight records to match correct calculation
UPDATE fight_records
SET points_earned = calculate_fight_points(result, method)
WHERE points_earned IS NULL OR points_earned != calculate_fight_points(result, method);

-- ============================================
-- 4. RECALCULATE ALL FIGHTER POINTS
-- ============================================
DO $$
DECLARE
    fighter_record RECORD;
    total_points INTEGER := 0;
    total_wins INTEGER := 0;
    total_losses INTEGER := 0;
    total_draws INTEGER := 0;
    total_knockouts INTEGER := 0;
    new_win_percentage DECIMAL(5,2);
    new_ko_percentage DECIMAL(5,2);
    updated_count INTEGER := 0;
BEGIN
    FOR fighter_record IN
        SELECT DISTINCT user_id, name
        FROM fighter_profiles 
        WHERE user_id IS NOT NULL
        ORDER BY name
    LOOP
        -- Recalculate points from all fight records using the correct formula
        SELECT 
            COALESCE(SUM(calculate_fight_points(result, method)), 0)::INTEGER,
            COUNT(*) FILTER (WHERE result = 'Win'),
            COUNT(*) FILTER (WHERE result = 'Loss'),
            COUNT(*) FILTER (WHERE result = 'Draw'),
            COUNT(*) FILTER (WHERE result = 'Win' AND UPPER(TRIM(method)) IN ('KO', 'TKO'))
        INTO total_points, total_wins, total_losses, total_draws, total_knockouts
        FROM fight_records
        WHERE fighter_id = fighter_record.user_id;
        
        -- Calculate percentages
        IF (total_wins + total_losses + total_draws) > 0 THEN
            new_win_percentage := ROUND((total_wins::DECIMAL / (total_wins + total_losses + total_draws) * 100)::NUMERIC, 2);
        ELSE
            new_win_percentage := 0;
        END IF;
        
        IF total_wins > 0 THEN
            new_ko_percentage := ROUND((total_knockouts::DECIMAL / total_wins * 100)::NUMERIC, 2);
        ELSE
            new_ko_percentage := 0;
        END IF;
        
        -- Update fighter profile with recalculated values
        UPDATE fighter_profiles
        SET 
            points = total_points,
            wins = total_wins,
            losses = total_losses,
            draws = total_draws,
            knockouts = total_knockouts,
            win_percentage = new_win_percentage,
            ko_percentage = new_ko_percentage,
            updated_at = NOW()
        WHERE user_id = fighter_record.user_id;
        
        updated_count := updated_count + 1;
    END LOOP;
    
    RAISE NOTICE '✅ Recalculated points for % fighters', updated_count;
END $$;

-- ============================================
-- 5. VERIFY POINTS ARE CORRECT
-- ============================================
-- Show fighters with incorrect points (should be empty after fix)
SELECT 
    fp.name,
    fp.user_id,
    fp.points as stored_points,
    COALESCE(SUM(calculate_fight_points(fr.result, fr.method)), 0)::INTEGER as calculated_points,
    fp.points - COALESCE(SUM(calculate_fight_points(fr.result, fr.method)), 0)::INTEGER as difference,
    COUNT(*) as total_fights,
    STRING_AGG(fr.result || ' (' || fr.method || ') = ' || calculate_fight_points(fr.result, fr.method)::TEXT, ', ' ORDER BY fr.date DESC) as fight_breakdown
FROM fighter_profiles fp
LEFT JOIN fight_records fr ON fr.fighter_id = fp.user_id
GROUP BY fp.name, fp.user_id, fp.points
HAVING fp.points != COALESCE(SUM(calculate_fight_points(fr.result, fr.method)), 0)::INTEGER
ORDER BY ABS(fp.points - COALESCE(SUM(calculate_fight_points(fr.result, fr.method)), 0)::INTEGER) DESC;

-- ============================================
-- 6. SAMPLE POINTS BREAKDOWN
-- ============================================
-- Show point breakdown for a few fighters
SELECT 
    fp.name,
    fp.points as total_points,
    COUNT(*) FILTER (WHERE fr.result = 'Win' AND UPPER(TRIM(fr.method)) NOT IN ('KO', 'TKO')) as wins_decision,
    COUNT(*) FILTER (WHERE fr.result = 'Win' AND UPPER(TRIM(fr.method)) IN ('KO', 'TKO')) as wins_ko,
    COUNT(*) FILTER (WHERE fr.result = 'Loss') as losses,
    COUNT(*) FILTER (WHERE fr.result = 'Draw') as draws,
    (COUNT(*) FILTER (WHERE fr.result = 'Win' AND UPPER(TRIM(fr.method)) NOT IN ('KO', 'TKO')) * 5 +
     COUNT(*) FILTER (WHERE fr.result = 'Win' AND UPPER(TRIM(fr.method)) IN ('KO', 'TKO')) * 8 +
     COUNT(*) FILTER (WHERE fr.result = 'Loss') * -3 +
     COUNT(*) FILTER (WHERE fr.result = 'Draw') * 0) as calculated_total
FROM fighter_profiles fp
LEFT JOIN fight_records fr ON fr.fighter_id = fp.user_id
GROUP BY fp.name, fp.points
HAVING COUNT(*) > 0
ORDER BY fp.points DESC
LIMIT 10;

-- ============================================
-- 7. SUMMARY
-- ============================================
DO $$
DECLARE
    total_fighters INTEGER;
    total_fights INTEGER;
    total_wins INTEGER;
    total_losses INTEGER;
    total_draws INTEGER;
    total_points INTEGER;
BEGIN
    SELECT COUNT(*) INTO total_fighters FROM fighter_profiles WHERE user_id IS NOT NULL;
    SELECT COUNT(*) INTO total_fights FROM fight_records;
    SELECT COUNT(*) INTO total_wins FROM fight_records WHERE result = 'Win';
    SELECT COUNT(*) INTO total_losses FROM fight_records WHERE result = 'Loss';
    SELECT COUNT(*) INTO total_draws FROM fight_records WHERE result = 'Draw';
    SELECT COALESCE(SUM(points), 0) INTO total_points FROM fighter_profiles;
    
    RAISE NOTICE '========================================';
    RAISE NOTICE 'POINT SYSTEM VERIFICATION COMPLETE';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Point System: Win = +5, Loss = -3, Draw = 0, KO/TKO Bonus = +3';
    RAISE NOTICE 'Total Fighters: %', total_fighters;
    RAISE NOTICE 'Total Fights: %', total_fights;
    RAISE NOTICE 'Total Wins: %', total_wins;
    RAISE NOTICE 'Total Losses: %', total_losses;
    RAISE NOTICE 'Total Draws: %', total_draws;
    RAISE NOTICE 'Total Points (all fighters): %', total_points;
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ All points have been recalculated correctly!';
END $$;

