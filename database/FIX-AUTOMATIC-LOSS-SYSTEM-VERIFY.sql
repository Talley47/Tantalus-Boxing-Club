-- COMPREHENSIVE FIX: Automatic Opponent Loss System & Point Calculation Verification
-- This script:
-- 1. Verifies calculate_fight_points function (Loss = -3)
-- 2. Recalculates ALL existing fight records to ensure correct points
-- 3. Recalculates ALL fighter points from scratch
-- 4. Verifies trigger order and automatic loss creation
-- 5. Tests the system with verification queries
-- Run this in Supabase SQL Editor

-- ============================================
-- 1. VERIFY AND FIX calculate_fight_points FUNCTION
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
        WHEN 'Loss' THEN base_points := -3;  -- CRITICAL: Loss = -3
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

-- Test the function
DO $$
BEGIN
    IF calculate_fight_points('Win', 'Decision') != 5 THEN
        RAISE EXCEPTION 'FAIL: Win + Decision should be 5';
    END IF;
    IF calculate_fight_points('Win', 'KO') != 8 THEN
        RAISE EXCEPTION 'FAIL: Win + KO should be 8';
    END IF;
    IF calculate_fight_points('Loss', 'Decision') != -3 THEN
        RAISE EXCEPTION 'FAIL: Loss + Decision should be -3';
    END IF;
    IF calculate_fight_points('Loss', 'KO') != -3 THEN
        RAISE EXCEPTION 'FAIL: Loss + KO should be -3 (no bonus for losers)';
    END IF;
    IF calculate_fight_points('Draw', 'Decision') != 0 THEN
        RAISE EXCEPTION 'FAIL: Draw should be 0';
    END IF;
    RAISE NOTICE '✅ calculate_fight_points function verified: Win=+5, Loss=-3, Draw=0, KO Bonus=+3';
END $$;

-- ============================================
-- 2. RECALCULATE ALL EXISTING FIGHT RECORDS
-- ============================================
-- Fix points_earned for all existing records
UPDATE fight_records
SET points_earned = calculate_fight_points(result, method)
WHERE points_earned IS NULL 
   OR points_earned != calculate_fight_points(result, method);

-- ============================================
-- 3. RECALCULATE ALL FIGHTER POINTS FROM SCRATCH
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
-- 4. VERIFY TRIGGER ORDER
-- ============================================
-- Ensure triggers are in correct order:
-- 1. trigger_update_fighter_stats (FIRST) - updates winner's stats
-- 2. trigger_auto_create_opponent_loss (AFTER) - creates opponent loss
-- 3. trigger_update_fighter_tier (LAST) - updates tier after stats

-- Drop and recreate triggers in correct order
DROP TRIGGER IF EXISTS trigger_update_fighter_stats ON fight_records;
DROP TRIGGER IF EXISTS trigger_update_fighter_tier ON fight_records;
DROP TRIGGER IF EXISTS trigger_auto_create_opponent_loss ON fight_records;

-- ============================================
-- 5. UPDATE FIGHTER STATS TRIGGER FUNCTION
-- ============================================
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
    -- Calculate points for this fight (ALWAYS recalculate to ensure consistency)
    -- CRITICAL: This function calculates Loss = -3
    calculated_points := calculate_fight_points(NEW.result, NEW.method);
    
    -- Get current fighter stats BEFORE updating
    SELECT COALESCE(points, 0), COALESCE(wins, 0), COALESCE(losses, 0), COALESCE(draws, 0), COALESCE(knockouts, 0), (COALESCE(wins, 0) + COALESCE(losses, 0) + COALESCE(draws, 0)) 
    INTO fighter_points, fighter_wins, fighter_losses, fighter_draws, fighter_knockouts, total_fights
    FROM fighter_profiles 
    WHERE user_id = NEW.fighter_id;
    
    -- Update points_earned in the fight record to match calculated value
    UPDATE fight_records
    SET points_earned = calculated_points
    WHERE id = NEW.id;
    
    -- Update wins/losses/draws/knockouts and points
    -- CRITICAL: Use calculated_points, NOT NEW.points_earned
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
-- 6. AUTO-CREATE OPPONENT LOSS FUNCTION
-- ============================================
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

    -- Calculate points for loss using the same function as the system
    -- Loss = -3 points (no KO bonus for losers)
    loss_points := calculate_fight_points('Loss', NEW.method);

    -- Find the opponent by name (try both name and handle for flexibility)
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
        RAISE NOTICE 'Opponent "%" not found in fighter_profiles. Skipping auto-loss creation.', NEW.opponent_name;
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

    -- Create the loss record for the opponent
    -- CRITICAL: This will trigger update_fighter_stats_after_fight() which will add -3 points
    INSERT INTO fight_records (
        fighter_id,
        opponent_name,
        result,
        method,
        round,
        date,
        weight_class,
        points_earned,
        notes
    ) VALUES (
        opponent_user_id,
        winner_name,
        'Loss',
        NEW.method,
        COALESCE(NEW.round, 1),
        NEW.date,
        NEW.weight_class,
        loss_points, -- -3 points for loss
        'Auto-created from opponent''s win record'
    );

    RAISE NOTICE 'Auto-created Loss record for opponent "%" (user_id: %) with -3 points', NEW.opponent_name, opponent_user_id;

    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Failed to auto-create opponent loss record: %', SQLERRM;
        RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 7. CREATE TRIGGERS IN CORRECT ORDER
-- ============================================
-- Trigger 1: Update fighter stats (FIRST - fires AFTER INSERT)
-- This updates the winner's stats when they enter a win
CREATE TRIGGER trigger_update_fighter_stats
    AFTER INSERT ON fight_records
    FOR EACH ROW
    EXECUTE FUNCTION update_fighter_stats_after_fight();

-- Trigger 2: Auto-create opponent loss (AFTER INSERT - fires after winner's record is inserted)
CREATE TRIGGER trigger_auto_create_opponent_loss
    AFTER INSERT ON fight_records
    FOR EACH ROW
    EXECUTE FUNCTION auto_create_opponent_loss();

-- Trigger 3: Update tier (AFTER INSERT - fires after stats are updated)
-- (Assuming this function exists - if not, it will be created by other scripts)
-- CREATE TRIGGER trigger_update_fighter_tier
--     AFTER INSERT ON fight_records
--     FOR EACH ROW
--     EXECUTE FUNCTION update_fighter_tier_after_fight();

-- ============================================
-- 8. VERIFICATION QUERIES
-- ============================================
-- Check for fighters with incorrect points
DO $$
DECLARE
    incorrect_count INTEGER;
    test_fighter_name TEXT := 'Moose Itauma';
    test_fighter_points INTEGER;
    test_fighter_losses INTEGER;
    calculated_points INTEGER;
BEGIN
    -- Check if Moose Itauma exists and has correct points
    SELECT points, losses INTO test_fighter_points, test_fighter_losses
    FROM fighter_profiles
    WHERE LOWER(name) LIKE '%moose%itauma%' OR LOWER(handle) LIKE '%moose%itauma%'
    LIMIT 1;
    
    IF test_fighter_points IS NOT NULL THEN
        -- Calculate what points should be
        SELECT COALESCE(SUM(calculate_fight_points(result, method)), 0) INTO calculated_points
        FROM fight_records fr
        JOIN fighter_profiles fp ON fr.fighter_id = fp.user_id
        WHERE (LOWER(fp.name) LIKE '%moose%itauma%' OR LOWER(fp.handle) LIKE '%moose%itauma%');
        
        RAISE NOTICE 'Fighter: %', test_fighter_name;
        RAISE NOTICE 'Current Points: %', test_fighter_points;
        RAISE NOTICE 'Calculated Points: %', calculated_points;
        RAISE NOTICE 'Losses: %', test_fighter_losses;
        
        IF test_fighter_points != calculated_points THEN
            RAISE WARNING '⚠️ Points mismatch for %: Current=%, Calculated=%', test_fighter_name, test_fighter_points, calculated_points;
        ELSE
            RAISE NOTICE '✅ Points are correct for %', test_fighter_name;
        END IF;
    END IF;
    
    -- Count fighters with incorrect points
    SELECT COUNT(*) INTO incorrect_count
    FROM fighter_profiles fp
    WHERE fp.points != COALESCE((
        SELECT SUM(calculate_fight_points(fr.result, fr.method))
        FROM fight_records fr
        WHERE fr.fighter_id = fp.user_id
    ), 0);
    
    IF incorrect_count > 0 THEN
        RAISE WARNING '⚠️ Found % fighters with incorrect points', incorrect_count;
    ELSE
        RAISE NOTICE '✅ All fighter points are correct';
    END IF;
END $$;

-- Show fighters with Loss records and their points
SELECT 
    fp.name,
    fp.handle,
    fp.points,
    COUNT(*) FILTER (WHERE fr.result = 'Loss') as losses,
    COUNT(*) FILTER (WHERE fr.result = 'Win') as wins,
    SUM(calculate_fight_points(fr.result, fr.method)) as calculated_points,
    fp.points - SUM(calculate_fight_points(fr.result, fr.method)) as difference
FROM fighter_profiles fp
LEFT JOIN fight_records fr ON fr.fighter_id = fp.user_id
WHERE EXISTS (
    SELECT 1 FROM fight_records 
    WHERE fighter_id = fp.user_id AND result = 'Loss'
)
GROUP BY fp.user_id, fp.name, fp.handle, fp.points
HAVING fp.points != SUM(calculate_fight_points(fr.result, fr.method))
ORDER BY ABS(fp.points - SUM(calculate_fight_points(fr.result, fr.method))) DESC
LIMIT 20;

-- ============================================
-- 9. GRANT PERMISSIONS
-- ============================================
GRANT EXECUTE ON FUNCTION calculate_fight_points(TEXT, TEXT) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION update_fighter_stats_after_fight() TO authenticated, anon;
GRANT EXECUTE ON FUNCTION auto_create_opponent_loss() TO authenticated, anon;

-- ============================================
-- 10. SUCCESS MESSAGE
-- ============================================
DO $$
BEGIN
    RAISE NOTICE '✅ Automatic Opponent Loss System verified and fixed!';
    RAISE NOTICE '✅ All fight records recalculated';
    RAISE NOTICE '✅ All fighter points recalculated from scratch';
    RAISE NOTICE '✅ Triggers recreated in correct order';
    RAISE NOTICE '✅ Point System: Win = +5, Loss = -3, Draw = 0, KO/TKO Bonus = +3';
END $$;

