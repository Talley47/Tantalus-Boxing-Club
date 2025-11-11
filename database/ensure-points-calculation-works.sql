-- Ensure Points Calculation is Working Correctly
-- This script verifies and fixes the points calculation system
-- Run this in Supabase SQL Editor

-- ============================================
-- 1. Drop ALL existing triggers on fight_records
-- ============================================
DROP TRIGGER IF EXISTS trigger_update_fighter_stats ON fight_records;
DROP TRIGGER IF EXISTS trigger_update_fighter_tier ON fight_records;
DROP TRIGGER IF EXISTS update_fighter_stats_trigger ON fight_records;
DROP TRIGGER IF EXISTS update_fighter_tier_trigger ON fight_records;

-- ============================================
-- 2. Ensure calculate_fight_points function is correct
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
    
    -- KO/TKO bonus (+3)
    IF UPPER(TRIM(method)) IN ('KO', 'TKO') THEN
        ko_bonus := 3;
    END IF;
    
    RETURN base_points + ko_bonus;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================
-- 3. Create/Update Stats Trigger (with points_earned update)
-- ============================================
CREATE OR REPLACE FUNCTION update_fighter_stats_after_fight()
RETURNS TRIGGER AS $$
DECLARE
    fighter_points INTEGER;
    calculated_points INTEGER;
    total_fights INTEGER;
    calc_win_percentage DECIMAL(5,2);
    calc_ko_percentage DECIMAL(5,2);
    fighter_wins INTEGER;
    fighter_losses INTEGER;
    fighter_draws INTEGER;
    fighter_knockouts INTEGER;
BEGIN
    -- Calculate points for this fight (ALWAYS recalculate to ensure consistency)
    -- CRITICAL: This function calculates Loss = -3, NOT -2
    calculated_points := calculate_fight_points(NEW.result, NEW.method);
    
    -- Get current fighter stats BEFORE updating
    SELECT COALESCE(points, 0), COALESCE(wins, 0), COALESCE(losses, 0), COALESCE(draws, 0), COALESCE(knockouts, 0), (COALESCE(wins, 0) + COALESCE(losses, 0) + COALESCE(draws, 0)) 
    INTO fighter_points, fighter_wins, fighter_losses, fighter_draws, fighter_knockouts, total_fights
    FROM fighter_profiles 
    WHERE user_id = NEW.fighter_id;
    
    -- Update points_earned in the fight record to match calculated value
    -- This ensures consistency even if frontend sends wrong value
    UPDATE fight_records
    SET points_earned = calculated_points
    WHERE id = NEW.id;
    
    -- Update wins/losses/draws/knockouts and points
    -- CRITICAL: Use calculated_points, NOT NEW.points_earned, to ensure correct calculation
    UPDATE fighter_profiles SET
        wins = CASE WHEN NEW.result = 'Win' THEN fighter_wins + 1 ELSE fighter_wins END,
        losses = CASE WHEN NEW.result = 'Loss' THEN fighter_losses + 1 ELSE fighter_losses END,
        draws = CASE WHEN NEW.result = 'Draw' THEN fighter_draws + 1 ELSE fighter_draws END,
        knockouts = CASE WHEN UPPER(TRIM(NEW.method)) IN ('KO', 'TKO') THEN fighter_knockouts + 1 ELSE fighter_knockouts END,
        points = fighter_points + calculated_points,  -- Use calculated points, not NEW.points_earned
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
    
    -- Update percentages using calculated values (avoiding ambiguity)
    UPDATE fighter_profiles SET
        win_percentage = calc_win_percentage,
        ko_percentage = calc_ko_percentage
    WHERE user_id = NEW.fighter_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 4. Create Tier Update Function (if not exists from previous script)
-- ============================================
-- This will use the tier update function from fix-rankings-points-tier-system.sql
-- If it doesn't exist, create a basic one
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'update_fighter_tier_after_fight'
    ) THEN
        -- Create a basic tier update function (full version should be in fix-rankings-points-tier-system.sql)
        EXECUTE 'CREATE OR REPLACE FUNCTION update_fighter_tier_after_fight()
        RETURNS TRIGGER AS $tier$
        DECLARE
            fighter_points INTEGER;
            calculated_tier TEXT;
        BEGIN
            SELECT points INTO fighter_points
            FROM fighter_profiles
            WHERE user_id = NEW.fighter_id;
            
            -- Calculate tier based on points
            IF fighter_points >= 280 THEN
                calculated_tier := ''Elite'';
            ELSIF fighter_points >= 140 THEN
                calculated_tier := ''Contender'';
            ELSIF fighter_points >= 70 THEN
                calculated_tier := ''Pro'';
            ELSIF fighter_points >= 30 THEN
                calculated_tier := ''Semi-Pro'';
            ELSE
                calculated_tier := ''Amateur'';
            END IF;
            
            UPDATE fighter_profiles
            SET tier = calculated_tier,
                updated_at = NOW()
            WHERE user_id = NEW.fighter_id;
            
            RETURN NEW;
        END;
        $tier$ LANGUAGE plpgsql;';
    END IF;
END $$;

-- ============================================
-- 5. Create Triggers
-- ============================================
CREATE TRIGGER trigger_update_fighter_stats
    AFTER INSERT ON fight_records
    FOR EACH ROW
    EXECUTE FUNCTION update_fighter_stats_after_fight();

CREATE TRIGGER trigger_update_fighter_tier
    AFTER INSERT ON fight_records
    FOR EACH ROW
    EXECUTE FUNCTION update_fighter_tier_after_fight();

-- ============================================
-- 6. Recalculate all existing fight records' points_earned
-- ============================================
UPDATE fight_records
SET points_earned = calculate_fight_points(result, method)
WHERE points_earned IS NULL OR points_earned != calculate_fight_points(result, method);

-- ============================================
-- 7. Recalculate all fighter points from scratch
-- ============================================
-- This ensures all fighter points are correct based on their fight records
UPDATE fighter_profiles fp
SET points = COALESCE((
    SELECT SUM(calculate_fight_points(fr.result, fr.method))
    FROM fight_records fr
    WHERE fr.fighter_id = fp.user_id
), 0)
WHERE EXISTS (SELECT 1 FROM fight_records WHERE fighter_id = fp.user_id);

-- Success message
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '✅ Points calculation system verified and fixed!';
    RAISE NOTICE '';
    RAISE NOTICE 'Point System:';
    RAISE NOTICE '  Win: +5 points';
    RAISE NOTICE '  Loss: -3 points';
    RAISE NOTICE '  Draw: 0 points';
    RAISE NOTICE '  KO/TKO Bonus: +3 points';
    RAISE NOTICE '';
    RAISE NOTICE 'All existing fight records have been updated.';
    RAISE NOTICE 'All fighter points have been recalculated.';
    RAISE NOTICE '';
    RAISE NOTICE 'The trigger will now:';
    RAISE NOTICE '  1. Calculate points using calculate_fight_points()';
    RAISE NOTICE '  2. Update points_earned in fight_records to match';
    RAISE NOTICE '  3. Add calculated points to fighter_profiles.points';
END $$;

