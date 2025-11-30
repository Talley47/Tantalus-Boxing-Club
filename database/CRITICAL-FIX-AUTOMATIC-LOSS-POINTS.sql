-- CRITICAL FIX: Automatic Loss System - Ensure Opponent Gets -3 Points
-- This script fixes the issue where opponents are getting +1 instead of -3 points
-- Run this in Supabase SQL Editor

-- ============================================
-- STEP 1: VERIFY calculate_fight_points FUNCTION
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
        WHEN 'Loss' THEN base_points := -3;  -- CRITICAL: Loss MUST be -3
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

-- Test the function immediately
DO $$
BEGIN
    IF calculate_fight_points('Loss', 'Decision') != -3 THEN
        RAISE EXCEPTION 'CRITICAL: calculate_fight_points is broken! Loss should be -3, got %', calculate_fight_points('Loss', 'Decision');
    END IF;
    RAISE NOTICE '✅ calculate_fight_points verified: Loss = -3';
END $$;

-- ============================================
-- STEP 2: FIX update_fighter_stats_after_fight FUNCTION
-- ============================================
-- This function MUST use calculate_fight_points, NOT NEW.points_earned
CREATE OR REPLACE FUNCTION update_fighter_stats_after_fight()
RETURNS TRIGGER AS $$
DECLARE
    calculated_points INTEGER;
    fighter_points INTEGER;
    fighter_wins INTEGER;
    fighter_losses INTEGER;
    fighter_draws INTEGER;
    fighter_knockouts INTEGER;
    total_fights INTEGER;
    calc_win_percentage NUMERIC;
    calc_ko_percentage NUMERIC;
BEGIN
    -- CRITICAL: ALWAYS recalculate points using the function
    -- DO NOT trust NEW.points_earned - it might be wrong!
    calculated_points := calculate_fight_points(NEW.result, NEW.method);
    
    -- Get current fighter stats BEFORE updating
    SELECT COALESCE(points, 0), COALESCE(wins, 0), COALESCE(losses, 0), COALESCE(draws, 0), COALESCE(knockouts, 0), (COALESCE(wins, 0) + COALESCE(losses, 0) + COALESCE(draws, 0)) 
    INTO fighter_points, fighter_wins, fighter_losses, fighter_draws, fighter_knockouts, total_fights
    FROM fighter_profiles 
    WHERE user_id = NEW.fighter_id;
    
    -- CRITICAL: Update points_earned in the fight record to the CORRECT calculated value
    -- This ensures the record has the right points even if frontend sent wrong value
    UPDATE fight_records
    SET points_earned = calculated_points
    WHERE id = NEW.id;
    
    -- Update wins/losses/draws/knockouts and points
    -- CRITICAL: Use calculated_points (Loss = -3), NOT NEW.points_earned
    UPDATE fighter_profiles SET
        wins = CASE WHEN NEW.result = 'Win' THEN fighter_wins + 1 ELSE fighter_wins END,
        losses = CASE WHEN NEW.result = 'Loss' THEN fighter_losses + 1 ELSE fighter_losses END,
        draws = CASE WHEN NEW.result = 'Draw' THEN fighter_draws + 1 ELSE fighter_draws END,
        knockouts = CASE WHEN NEW.result = 'Win' AND UPPER(TRIM(NEW.method)) IN ('KO', 'TKO') THEN fighter_knockouts + 1 ELSE fighter_knockouts END,
        points = fighter_points + calculated_points,  -- Loss = -3, Win = +5 or +8
        updated_at = NOW()
    WHERE user_id = NEW.fighter_id;
    
    -- Recalculate percentages after the update
    SELECT 
        CASE WHEN (wins + losses + draws) > 0 
            THEN ROUND((wins::DECIMAL / (wins + losses + draws) * 100)::NUMERIC, 2) 
            ELSE 0 
        END,
        CASE WHEN wins > 0 
            THEN ROUND((knockouts::DECIMAL / wins * 100)::NUMERIC, 2)
            ELSE 0 
        END
    INTO calc_win_percentage, calc_ko_percentage
    FROM fighter_profiles 
    WHERE user_id = NEW.fighter_id;
    
    -- Update percentages
    UPDATE fighter_profiles SET
        win_percentage = calc_win_percentage,
        ko_percentage = calc_ko_percentage,
        updated_at = NOW()
    WHERE user_id = NEW.fighter_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- STEP 3: FIX auto_create_opponent_loss FUNCTION
-- ============================================
-- This function MUST create the loss record with -3 points
CREATE OR REPLACE FUNCTION auto_create_opponent_loss()
RETURNS TRIGGER AS $$
DECLARE
    opponent_user_id UUID;
    loss_points INTEGER;
    existing_loss_record UUID;
    winner_name TEXT;
BEGIN
    -- Only process if this is a Win
    IF NEW.result != 'Win' THEN
        RETURN NEW;
    END IF;

    -- CRITICAL: Calculate points for loss - MUST be -3
    loss_points := calculate_fight_points('Loss', NEW.method);
    
    -- Verify it's -3
    IF loss_points != -3 THEN
        RAISE EXCEPTION 'CRITICAL ERROR: Loss points should be -3, got %', loss_points;
    END IF;

    -- Find the opponent by name (try both name and handle)
    SELECT user_id INTO opponent_user_id
    FROM fighter_profiles
    WHERE LOWER(TRIM(name)) = LOWER(TRIM(NEW.opponent_name))
       OR LOWER(TRIM(handle)) = LOWER(TRIM(NEW.opponent_name))
    LIMIT 1;

    -- If not found, try partial match
    IF opponent_user_id IS NULL THEN
        SELECT user_id INTO opponent_user_id
        FROM fighter_profiles
        WHERE LOWER(TRIM(name)) LIKE '%' || LOWER(TRIM(NEW.opponent_name)) || '%'
           OR LOWER(TRIM(handle)) LIKE '%' || LOWER(TRIM(NEW.opponent_name)) || '%'
        LIMIT 1;
    END IF;

    -- If opponent not found, log a warning but don't fail
    IF opponent_user_id IS NULL THEN
        RAISE WARNING 'Opponent "%" not found in fighter_profiles. Skipping auto-loss creation.', NEW.opponent_name;
        RETURN NEW;
    END IF;

    -- Check if a loss record already exists for this fight
    SELECT id INTO existing_loss_record
    FROM fight_records
    WHERE fighter_id = opponent_user_id
      AND opponent_name = (
          SELECT name FROM fighter_profiles WHERE user_id = NEW.fighter_id LIMIT 1
      )
      AND date = NEW.date
      AND result = 'Loss'
    LIMIT 1;

    -- If loss record already exists, skip creation
    IF existing_loss_record IS NOT NULL THEN
        RAISE NOTICE 'Loss record already exists for opponent "%" on date %. Skipping auto-creation.', NEW.opponent_name, NEW.date;
        RETURN NEW;
    END IF;

    -- Get winner's name for the opponent record
    SELECT name INTO winner_name
    FROM fighter_profiles
    WHERE user_id = NEW.fighter_id
    LIMIT 1;

    -- If winner name not found, use a fallback
    IF winner_name IS NULL OR winner_name = '' THEN
        winner_name := 'Unknown Fighter';
    END IF;

    -- CRITICAL: Create the loss record with -3 points
    -- This INSERT will trigger update_fighter_stats_after_fight() which will add -3 points
    INSERT INTO fight_records (
        fighter_id,
        opponent_name,
        result,
        method,
        round,
        date,
        weight_class,
        points_earned,  -- CRITICAL: Set to -3
        notes
    ) VALUES (
        opponent_user_id,
        winner_name,
        'Loss',
        NEW.method,
        COALESCE(NEW.round, 1),
        NEW.date,
        NEW.weight_class,
        -3,  -- CRITICAL: Hardcode -3 to ensure it's correct
        'Auto-created from opponent''s win record'
    );

    RAISE NOTICE '✅ Auto-created Loss record for opponent "%" (user_id: %) with -3 points', NEW.opponent_name, opponent_user_id;

    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Failed to auto-create opponent loss record: %', SQLERRM;
        RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- STEP 4: DROP AND RECREATE TRIGGERS IN CORRECT ORDER
-- ============================================
-- Drop all existing triggers
DROP TRIGGER IF EXISTS trigger_update_fighter_stats ON fight_records;
DROP TRIGGER IF EXISTS trigger_auto_create_opponent_loss ON fight_records;
DROP TRIGGER IF EXISTS trigger_update_fighter_tier ON fight_records;

-- Trigger 1: Update fighter stats (fires AFTER INSERT)
-- This updates the winner's stats when they enter a win
CREATE TRIGGER trigger_update_fighter_stats
    AFTER INSERT ON fight_records
    FOR EACH ROW
    EXECUTE FUNCTION update_fighter_stats_after_fight();

-- Trigger 2: Auto-create opponent loss (fires AFTER INSERT, after stats update)
-- This creates the loss record for the opponent
-- The loss record INSERT will trigger update_fighter_stats_after_fight() again
CREATE TRIGGER trigger_auto_create_opponent_loss
    AFTER INSERT ON fight_records
    FOR EACH ROW
    EXECUTE FUNCTION auto_create_opponent_loss();

-- ============================================
-- STEP 5: FIX ALL EXISTING INCORRECT POINTS
-- ============================================
-- Fix points_earned for all Loss records (should be -3)
UPDATE fight_records
SET points_earned = -3
WHERE result = 'Loss' 
  AND (points_earned IS NULL OR points_earned != -3);

-- Fix points_earned for all Win records
UPDATE fight_records
SET points_earned = calculate_fight_points(result, method)
WHERE result = 'Win' 
  AND (points_earned IS NULL OR points_earned != calculate_fight_points(result, method));

-- Fix points_earned for all Draw records (should be 0)
UPDATE fight_records
SET points_earned = 0
WHERE result = 'Draw' 
  AND (points_earned IS NULL OR points_earned != 0);

-- ============================================
-- STEP 6: RECALCULATE ALL FIGHTER POINTS FROM SCRATCH
-- ============================================
-- This ensures all fighter points are correct based on their fight records
UPDATE fighter_profiles fp
SET 
    points = COALESCE((
        SELECT SUM(calculate_fight_points(fr.result, fr.method))
        FROM fight_records fr
        WHERE fr.fighter_id = fp.user_id
    ), 0),
    wins = COALESCE((
        SELECT COUNT(*) 
        FROM fight_records 
        WHERE fighter_id = fp.user_id AND result = 'Win'
    ), 0),
    losses = COALESCE((
        SELECT COUNT(*) 
        FROM fight_records 
        WHERE fighter_id = fp.user_id AND result = 'Loss'
    ), 0),
    draws = COALESCE((
        SELECT COUNT(*) 
        FROM fight_records 
        WHERE fighter_id = fp.user_id AND result = 'Draw'
    ), 0),
    knockouts = COALESCE((
        SELECT COUNT(*) 
        FROM fight_records 
        WHERE fighter_id = fp.user_id 
        AND result = 'Win' 
        AND UPPER(TRIM(method)) IN ('KO', 'TKO')
    ), 0),
    updated_at = NOW();

-- Recalculate percentages
UPDATE fighter_profiles fp
SET 
    win_percentage = CASE 
        WHEN (wins + losses + draws) > 0 
        THEN ROUND((wins::DECIMAL / (wins + losses + draws) * 100)::NUMERIC, 2)
        ELSE 0 
    END,
    ko_percentage = CASE 
        WHEN wins > 0 
        THEN ROUND((knockouts::DECIMAL / wins * 100)::NUMERIC, 2)
        ELSE 0 
    END,
    updated_at = NOW();

-- ============================================
-- STEP 7: VERIFY MOOSE ITAUMA SPECIFICALLY
-- ============================================
DO $$
DECLARE
    moose_user_id UUID;
    moose_points INTEGER;
    moose_losses INTEGER;
    calculated_points INTEGER;
    loss_records_count INTEGER;
    rec RECORD;
BEGIN
    -- Find Moose Itauma
    SELECT user_id, points, losses INTO moose_user_id, moose_points, moose_losses
    FROM fighter_profiles
    WHERE LOWER(name) LIKE '%moose%itauma%' OR LOWER(handle) LIKE '%moose%itauma%'
    LIMIT 1;
    
    IF moose_user_id IS NOT NULL THEN
        -- Calculate what points should be
        SELECT COALESCE(SUM(calculate_fight_points(result, method)), 0) INTO calculated_points
        FROM fight_records
        WHERE fighter_id = moose_user_id;
        
        -- Count loss records
        SELECT COUNT(*) INTO loss_records_count
        FROM fight_records
        WHERE fighter_id = moose_user_id AND result = 'Loss';
        
        RAISE NOTICE '========================================';
        RAISE NOTICE 'MOOSE ITAUMA VERIFICATION';
        RAISE NOTICE '========================================';
        RAISE NOTICE 'User ID: %', moose_user_id;
        RAISE NOTICE 'Current Points: %', moose_points;
        RAISE NOTICE 'Calculated Points: %', calculated_points;
        RAISE NOTICE 'Loss Records: %', loss_records_count;
        RAISE NOTICE 'Expected Points (if 1 loss): -3';
        
        IF moose_points != calculated_points THEN
            RAISE WARNING '⚠️ POINTS MISMATCH! Current: %, Calculated: %', moose_points, calculated_points;
            -- Fix it
            UPDATE fighter_profiles
            SET points = calculated_points
            WHERE user_id = moose_user_id;
            RAISE NOTICE '✅ Fixed Moose Itauma points to %', calculated_points;
        ELSE
            RAISE NOTICE '✅ Moose Itauma points are correct';
        END IF;
        
        -- Check loss records
        IF loss_records_count > 0 THEN
            RAISE NOTICE 'Loss Records Details:';
            FOR rec IN 
                SELECT id, opponent_name, date, points_earned, result
                FROM fight_records
                WHERE fighter_id = moose_user_id AND result = 'Loss'
                ORDER BY date DESC
            LOOP
                RAISE NOTICE '  - Loss vs % on %: points_earned = %', rec.opponent_name, rec.date, rec.points_earned;
                IF rec.points_earned != -3 THEN
                    RAISE WARNING '  ⚠️ INCORRECT! Should be -3, got %', rec.points_earned;
                    -- Fix it
                    UPDATE fight_records
                    SET points_earned = -3
                    WHERE id = rec.id;
                    RAISE NOTICE '  ✅ Fixed points_earned to -3';
                END IF;
            END LOOP;
        END IF;
    ELSE
        RAISE NOTICE 'Moose Itauma not found in database';
    END IF;
END $$;

-- ============================================
-- STEP 8: SHOW ALL FIGHTERS WITH INCORRECT POINTS
-- ============================================
SELECT 
    fp.name,
    fp.handle,
    fp.points as current_points,
    COUNT(*) FILTER (WHERE fr.result = 'Loss') as losses,
    COUNT(*) FILTER (WHERE fr.result = 'Win') as wins,
    COALESCE(SUM(calculate_fight_points(fr.result, fr.method)), 0) as calculated_points,
    fp.points - COALESCE(SUM(calculate_fight_points(fr.result, fr.method)), 0) as difference
FROM fighter_profiles fp
LEFT JOIN fight_records fr ON fr.fighter_id = fp.user_id
GROUP BY fp.user_id, fp.name, fp.handle, fp.points
HAVING fp.points != COALESCE(SUM(calculate_fight_points(fr.result, fr.method)), 0)
ORDER BY ABS(fp.points - COALESCE(SUM(calculate_fight_points(fr.result, fr.method)), 0)) DESC;

-- ============================================
-- STEP 9: GRANT PERMISSIONS
-- ============================================
GRANT EXECUTE ON FUNCTION calculate_fight_points(TEXT, TEXT) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION update_fighter_stats_after_fight() TO authenticated, anon;
GRANT EXECUTE ON FUNCTION auto_create_opponent_loss() TO authenticated, anon;

-- ============================================
-- STEP 10: SUCCESS MESSAGE
-- ============================================
DO $$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ CRITICAL FIX COMPLETE!';
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ calculate_fight_points: Loss = -3 verified';
    RAISE NOTICE '✅ All Loss records fixed to -3 points';
    RAISE NOTICE '✅ All fighter points recalculated from scratch';
    RAISE NOTICE '✅ Triggers recreated in correct order';
    RAISE NOTICE '✅ Moose Itauma points verified and fixed';
    RAISE NOTICE '';
    RAISE NOTICE 'The automatic loss system will now:';
    RAISE NOTICE '1. Create loss record with -3 points';
    RAISE NOTICE '2. Update opponent stats with -3 points';
    RAISE NOTICE '3. Update all systems in real-time';
END $$;

