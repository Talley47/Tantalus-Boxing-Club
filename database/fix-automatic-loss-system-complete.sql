-- Complete Fix for Automatic Loss System and Tier Thresholds
-- This script ensures:
-- 1. Auto-create opponent loss when fighter enters a win (-3 points)
-- 2. Correct tier thresholds including Hall of famer (560+ pts)
-- 3. All systems update in real-time
-- Run this in Supabase SQL Editor

-- ============================================
-- 1. POINTS CALCULATION FUNCTION
-- ============================================
-- REQUIREMENT: Win = +5, Loss = -3, Draw = 0, KO/TKO Bonus = +3 (only for winners)
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
-- 2. TIER CALCULATION FUNCTION (UPDATED WITH HALL OF FAMER)
-- ============================================
-- REQUIREMENT: 
-- Amateur: 0-29 pts
-- Semi-Pro: 30-69 pts
-- Pro: 70-139 pts
-- Contender: 140-279 pts
-- Elite: 280-559 pts
-- Hall of famer: 560+ pts
CREATE OR REPLACE FUNCTION calculate_tier(points INTEGER)
RETURNS TEXT AS $$
BEGIN
    IF points >= 560 THEN
        RETURN 'Hall of famer';  -- ≥560 points
    ELSIF points >= 280 THEN
        RETURN 'Elite';          -- 280-559 points
    ELSIF points >= 140 THEN
        RETURN 'Contender';      -- 140-279 points
    ELSIF points >= 70 THEN
        RETURN 'Pro';            -- 70-139 points
    ELSIF points >= 30 THEN
        RETURN 'Semi-Pro';       -- 30-69 points
    ELSE
        RETURN 'Amateur';        -- 0-29 points (default start)
    END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================
-- 3. TIER INDEX FUNCTIONS (UPDATED WITH HALL OF FAMER)
-- ============================================
-- REQUIREMENT: Amateur → Semi-Pro → Pro → Contender → Elite → Hall of famer
CREATE OR REPLACE FUNCTION get_tier_index(tier_name TEXT)
RETURNS INTEGER AS $$
BEGIN
    CASE tier_name
        WHEN 'Hall of famer' THEN RETURN 5;
        WHEN 'Elite' THEN RETURN 4;
        WHEN 'Contender' THEN RETURN 3;
        WHEN 'Pro' THEN RETURN 2;
        WHEN 'Semi-Pro' THEN RETURN 1;
        WHEN 'Amateur' THEN RETURN 0;
        ELSE RETURN 0;
    END CASE;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION get_tier_name(tier_index INTEGER)
RETURNS TEXT AS $$
BEGIN
    CASE tier_index
        WHEN 5 THEN RETURN 'Hall of famer';
        WHEN 4 THEN RETURN 'Elite';
        WHEN 3 THEN RETURN 'Contender';
        WHEN 2 THEN RETURN 'Pro';
        WHEN 1 THEN RETURN 'Semi-Pro';
        WHEN 0 THEN RETURN 'Amateur';
        ELSE RETURN 'Amateur';
    END CASE;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================
-- 4. CONSECUTIVE LOSSES FUNCTION
-- ============================================
-- Used for demotion check (5 consecutive losses = demote) and warning (3+ losses)
CREATE OR REPLACE FUNCTION get_consecutive_losses(fighter_user_id UUID)
RETURNS INTEGER AS $$
DECLARE
    consecutive_count INTEGER := 0;
    record_result TEXT;
BEGIN
    FOR record_result IN
        SELECT result
        FROM fight_records
        WHERE fighter_id = fighter_user_id
        ORDER BY date DESC, created_at DESC
        LIMIT 10
    LOOP
        IF record_result = 'Loss' THEN
            consecutive_count := consecutive_count + 1;
        ELSE
            EXIT; -- Stop counting when we hit a non-loss
        END IF;
    END LOOP;
    
    RETURN consecutive_count;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 5. CONSECUTIVE WINS FUNCTION
-- ============================================
-- Used for promotion back check (5 consecutive wins after demotion)
CREATE OR REPLACE FUNCTION get_consecutive_wins(fighter_user_id UUID)
RETURNS INTEGER AS $$
DECLARE
    consecutive_count INTEGER := 0;
    record_result TEXT;
BEGIN
    FOR record_result IN
        SELECT result
        FROM fight_records
        WHERE fighter_id = fighter_user_id
        ORDER BY date DESC, created_at DESC
        LIMIT 10
    LOOP
        IF record_result = 'Win' THEN
            consecutive_count := consecutive_count + 1;
        ELSE
            EXIT; -- Stop counting when we hit a non-win
        END IF;
    END LOOP;
    
    RETURN consecutive_count;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 6. UPDATE FIGHTER STATS TRIGGER
-- ============================================
-- Updates points, wins/losses/draws, knockouts, and percentages
CREATE OR REPLACE FUNCTION update_fighter_stats_after_fight()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
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
        knockouts = CASE WHEN NEW.result = 'Win' AND UPPER(TRIM(NEW.method)) IN ('KO', 'TKO') THEN fighter_knockouts + 1 ELSE fighter_knockouts END,
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
        ko_percentage = calc_ko_percentage,
        updated_at = NOW()
    WHERE user_id = NEW.fighter_id;
    
    RETURN NEW;
END;
$$;

-- ============================================
-- 7. UPDATE FIGHTER TIER TRIGGER (WITH DEMOTION/PROMOTION)
-- ============================================
-- Handles tier updates, demotion (5 consecutive losses), and promotion back (5 consecutive wins)
CREATE OR REPLACE FUNCTION update_fighter_tier_after_fight()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
DECLARE
    fighter_points INTEGER;
    fighter_tier TEXT;
    calculated_tier TEXT;
    current_tier_index INTEGER;
    calculated_tier_index INTEGER;
    consecutive_losses_count INTEGER;
    consecutive_wins_count INTEGER;
    should_demote BOOLEAN := FALSE;
    should_promote_back BOOLEAN := FALSE;
    new_tier TEXT;
    previous_tier TEXT;
BEGIN
    -- Get current fighter stats
    SELECT points, tier INTO fighter_points, fighter_tier
    FROM fighter_profiles
    WHERE user_id = NEW.fighter_id;
    
    previous_tier := fighter_tier;
    
    -- Check consecutive losses for demotion (5 losses in a row)
    consecutive_losses_count := get_consecutive_losses(NEW.fighter_id);
    
    -- Check consecutive wins for promotion back (5 wins in a row after demotion)
    consecutive_wins_count := get_consecutive_wins(NEW.fighter_id);
    
    -- Calculate tier based on points first
    calculated_tier := calculate_tier(fighter_points);
    current_tier_index := get_tier_index(fighter_tier);
    calculated_tier_index := get_tier_index(calculated_tier);
    
    -- Demotion rule: 5 consecutive losses = demote one tier
    IF consecutive_losses_count >= 5 THEN
        IF current_tier_index > 0 THEN
            new_tier := get_tier_name(current_tier_index - 1);
            should_demote := TRUE;
            
            -- Log demotion
            RAISE NOTICE 'Fighter % demoted from % to % due to 5 consecutive losses', 
                NEW.fighter_id, fighter_tier, new_tier;
        ELSE
            -- Already at lowest tier (Amateur), can't demote further
            new_tier := fighter_tier;
        END IF;
    -- Promotion back rule: 5 consecutive wins after demotion = promote back to previous tier
    ELSIF consecutive_wins_count >= 5 THEN
        -- Check if fighter is below their points-based tier (indicating they were demoted)
        IF calculated_tier_index > current_tier_index THEN
            new_tier := calculated_tier;
            should_promote_back := TRUE;
            
            -- Log promotion back
            RAISE NOTICE 'Fighter % promoted back from % to % due to 5 consecutive wins', 
                NEW.fighter_id, fighter_tier, new_tier;
        ELSE
            -- Normal promotion based on points threshold
            IF calculated_tier_index > current_tier_index THEN
                new_tier := calculated_tier;
            ELSE
                new_tier := fighter_tier;
            END IF;
        END IF;
    ELSE
        -- Normal tier calculation based on points (promote if points threshold reached)
        IF calculated_tier_index > current_tier_index THEN
            new_tier := calculated_tier;
        ELSE
            new_tier := fighter_tier; -- Keep current tier
        END IF;
    END IF;
    
    -- Update fighter profile with new tier
    IF new_tier != fighter_tier THEN
        UPDATE fighter_profiles
        SET tier = new_tier,
            updated_at = NOW()
        WHERE user_id = NEW.fighter_id;
    END IF;
    
    RETURN NEW;
END;
$$;

-- ============================================
-- 8. AUTO-CREATE OPPONENT LOSS TRIGGER
-- ============================================
-- When a fighter enters a Win, automatically create a Loss record for their opponent (-3 points)
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
    -- First try exact match on name (case-insensitive, trimmed)
    SELECT user_id INTO opponent_user_id
    FROM fighter_profiles
    WHERE LOWER(TRIM(name)) = LOWER(TRIM(NEW.opponent_name))
       OR LOWER(TRIM(handle)) = LOWER(TRIM(NEW.opponent_name))
    LIMIT 1;

    -- If not found, try partial match (in case of slight name variations)
    -- Only if exact match failed
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
    -- We match by: same opponent_name (reversed), same date, and opponent has a Loss
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
        winner_name, -- Winner's name as opponent
        'Loss',
        NEW.method, -- Same method (e.g., if winner won by KO, opponent lost by KO)
        COALESCE(NEW.round, 1), -- Use round from win, default to 1 if null
        NEW.date,
        NEW.weight_class,
        loss_points, -- -3 points for loss (calculated by trigger)
        'Auto-created from opponent''s win record' -- Note that this was auto-created
    );

    RAISE NOTICE 'Auto-created Loss record for opponent "%" (user_id: %)', NEW.opponent_name, opponent_user_id;

    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Log error but don't fail the original insert
        RAISE WARNING 'Failed to auto-create opponent loss record: %', SQLERRM;
        RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 9. DROP AND RECREATE ALL TRIGGERS
-- ============================================
-- Drop existing triggers if they exist
DROP TRIGGER IF EXISTS trigger_update_fighter_stats ON fight_records;
DROP TRIGGER IF EXISTS trigger_update_fighter_tier ON fight_records;
DROP TRIGGER IF EXISTS trigger_auto_create_opponent_loss ON fight_records;

-- Create trigger to update stats (points, wins/losses, percentages)
-- This fires FIRST to update the fighter's own stats
CREATE TRIGGER trigger_update_fighter_stats
    AFTER INSERT ON fight_records
    FOR EACH ROW
    EXECUTE FUNCTION update_fighter_stats_after_fight();

-- Create trigger to auto-create opponent loss
-- This fires SECOND to create the opponent's loss record when a win is entered
CREATE TRIGGER trigger_auto_create_opponent_loss
    AFTER INSERT ON fight_records
    FOR EACH ROW
    EXECUTE FUNCTION auto_create_opponent_loss();

-- Create trigger to update tier (with demotion/promotion logic)
-- This fires LAST to update tier after all stats are updated
CREATE TRIGGER trigger_update_fighter_tier
    AFTER INSERT ON fight_records
    FOR EACH ROW
    EXECUTE FUNCTION update_fighter_tier_after_fight();

-- ============================================
-- 10. GRANT PERMISSIONS
-- ============================================
GRANT EXECUTE ON FUNCTION auto_create_opponent_loss() TO authenticated, anon;
GRANT EXECUTE ON FUNCTION calculate_fight_points(TEXT, TEXT) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION calculate_tier(INTEGER) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION get_tier_index(TEXT) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION get_tier_name(INTEGER) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION get_consecutive_losses(UUID) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION get_consecutive_wins(UUID) TO authenticated, anon;

-- ============================================
-- 11. SUCCESS MESSAGE
-- ============================================
DO $$
BEGIN
    RAISE NOTICE '✅ Automatic loss system and tier thresholds updated successfully!';
    RAISE NOTICE '✅ Tier thresholds: Amateur (0-29), Semi-Pro (30-69), Pro (70-139), Contender (140-279), Elite (280-559), Hall of famer (560+)';
    RAISE NOTICE '✅ Auto-create opponent loss trigger installed';
    RAISE NOTICE '✅ Demotion system: 5 consecutive losses = demote one tier';
    RAISE NOTICE '✅ Promotion back: 5 consecutive wins after demotion = promote back';
END $$;

