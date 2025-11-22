-- Complete Calculation System Verification & Fix
-- Ensures all point calculations, tier thresholds, and demotion system are correct
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
-- 2. TIER CALCULATION FUNCTION
-- ============================================
-- REQUIREMENT: Amateur: 0-29, Semi-Pro: 30-69, Pro: 70-139, Contender: 140-279, Elite: 280+
CREATE OR REPLACE FUNCTION calculate_tier(points INTEGER)
RETURNS TEXT AS $$
BEGIN
    IF points >= 280 THEN
        RETURN 'Elite';      -- ≥280 points
    ELSIF points >= 140 THEN
        RETURN 'Contender';  -- 140-279 points
    ELSIF points >= 70 THEN
        RETURN 'Pro';        -- 70-139 points
    ELSIF points >= 30 THEN
        RETURN 'Semi-Pro';   -- 30-69 points
    ELSE
        RETURN 'Amateur';    -- 0-29 points (default start)
    END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================
-- 3. CONSECUTIVE LOSSES FUNCTION
-- ============================================
-- Used for demotion check (5 consecutive losses = demote)
CREATE OR REPLACE FUNCTION get_consecutive_losses(fighter_user_id UUID)
RETURNS INTEGER AS $$
DECLARE
    consecutive_count INTEGER := 0;
    record_result TEXT;
BEGIN
    -- Get last fight records ordered by date (most recent first)
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
-- 4. CONSECUTIVE WINS FUNCTION
-- ============================================
-- Used for promotion back check (5 consecutive wins after demotion = promote back)
CREATE OR REPLACE FUNCTION get_consecutive_wins(fighter_user_id UUID)
RETURNS INTEGER AS $$
DECLARE
    consecutive_count INTEGER := 0;
    record_result TEXT;
BEGIN
    -- Get last fight records ordered by date (most recent first)
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
-- 5. TIER INDEX FUNCTIONS (for demotion/promotion logic)
-- ============================================
CREATE OR REPLACE FUNCTION get_tier_index(tier_name TEXT)
RETURNS INTEGER AS $$
BEGIN
    CASE tier_name
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
-- 6. UPDATE FIGHTER STATS TRIGGER FUNCTION
-- ============================================
-- Updates wins, losses, draws, knockouts, and points when a fight record is added
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
    UPDATE fighter_profiles SET
        wins = CASE WHEN NEW.result = 'Win' THEN fighter_wins + 1 ELSE fighter_wins END,
        losses = CASE WHEN NEW.result = 'Loss' THEN fighter_losses + 1 ELSE fighter_losses END,
        draws = CASE WHEN NEW.result = 'Draw' THEN fighter_draws + 1 ELSE fighter_draws END,
        knockouts = CASE WHEN NEW.result = 'Win' AND UPPER(TRIM(NEW.method)) IN ('KO', 'TKO') THEN fighter_knockouts + 1 ELSE fighter_knockouts END,
        points = fighter_points + calculated_points,
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
-- 7. UPDATE TIER TRIGGER FUNCTION
-- ============================================
-- Handles automatic demotion (5 consecutive losses) and promotion back (5 consecutive wins)
CREATE OR REPLACE FUNCTION update_fighter_tier()
RETURNS TRIGGER AS $$
DECLARE
    fighter_points INTEGER;
    fighter_tier TEXT;
    calculated_tier TEXT;
    current_tier_index INTEGER;
    calculated_tier_index INTEGER;
    consecutive_losses_count INTEGER;
    consecutive_wins_count INTEGER;
    should_demote BOOLEAN := FALSE;
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
        -- Check if fighter was demoted (tier is lower than points-based tier)
        IF current_tier_index < calculated_tier_index THEN
            -- Promote back to tier based on points
            new_tier := calculated_tier;
            
            RAISE NOTICE 'Fighter % promoted back from % to % due to 5 consecutive wins', 
                NEW.fighter_id, fighter_tier, new_tier;
        ELSE
            -- Normal promotion based on points
            IF calculated_tier_index > current_tier_index THEN
                new_tier := calculated_tier;
            ELSE
                new_tier := fighter_tier;
            END IF;
        END IF;
    ELSE
        -- Normal tier calculation based on points (only promote, never demote based on points alone)
        IF calculated_tier_index > current_tier_index THEN
            new_tier := calculated_tier;
        ELSE
            new_tier := fighter_tier; -- Keep current tier (don't auto-demote based on points)
        END IF;
    END IF;
    
    -- Update fighter profile with new tier
    IF new_tier != previous_tier THEN
        UPDATE fighter_profiles
        SET tier = new_tier,
            updated_at = NOW()
        WHERE user_id = NEW.fighter_id;
        
        -- Log tier change in tier_history if table exists
        BEGIN
            INSERT INTO tier_history (fighter_id, from_tier, to_tier, reason)
            VALUES (
                (SELECT id FROM fighter_profiles WHERE user_id = NEW.fighter_id LIMIT 1),
                previous_tier,
                new_tier,
                CASE 
                    WHEN should_demote THEN '5 consecutive losses'
                    WHEN consecutive_wins_count >= 5 THEN '5 consecutive wins after demotion'
                    ELSE 'Points threshold reached'
                END
            );
        EXCEPTION
            WHEN OTHERS THEN
                -- tier_history table might not exist, ignore error
                NULL;
        END;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 8. DROP AND RECREATE TRIGGERS
-- ============================================
DROP TRIGGER IF EXISTS trigger_update_fighter_stats ON fight_records;
DROP TRIGGER IF EXISTS trigger_update_fighter_tier ON fight_records;
DROP TRIGGER IF EXISTS update_fighter_stats_trigger ON fight_records;
DROP TRIGGER IF EXISTS update_fighter_tier_trigger ON fight_records;

-- Create trigger for stats update (fires first)
CREATE TRIGGER trigger_update_fighter_stats
    AFTER INSERT ON fight_records
    FOR EACH ROW
    EXECUTE FUNCTION update_fighter_stats_after_fight();

-- Create trigger for tier update (fires after stats update)
CREATE TRIGGER trigger_update_fighter_tier
    AFTER INSERT ON fight_records
    FOR EACH ROW
    EXECUTE FUNCTION update_fighter_tier();

-- ============================================
-- 9. RECALCULATE ALL EXISTING RECORDS
-- ============================================
-- Fix any existing fight records with incorrect points
UPDATE fight_records
SET points_earned = calculate_fight_points(result, method)
WHERE points_earned IS NULL OR points_earned != calculate_fight_points(result, method);

-- Recalculate all fighter points, stats, and tiers
DO $$
DECLARE
    fighter_record RECORD;
    total_points INTEGER := 0;
    total_wins INTEGER := 0;
    total_losses INTEGER := 0;
    total_draws INTEGER := 0;
    total_knockouts INTEGER := 0;
    new_tier TEXT;
    new_win_percentage DECIMAL(5,2);
    new_ko_percentage DECIMAL(5,2);
BEGIN
    FOR fighter_record IN
        SELECT DISTINCT user_id FROM fighter_profiles WHERE user_id IS NOT NULL
    LOOP
        -- Recalculate points from all fight records
        SELECT 
            COALESCE(SUM(points_earned), 0),
            COUNT(*) FILTER (WHERE result = 'Win'),
            COUNT(*) FILTER (WHERE result = 'Loss'),
            COUNT(*) FILTER (WHERE result = 'Draw'),
            COUNT(*) FILTER (WHERE result = 'Win' AND UPPER(TRIM(method)) IN ('KO', 'TKO'))
        INTO total_points, total_wins, total_losses, total_draws, total_knockouts
        FROM fight_records
        WHERE fighter_id = fighter_record.user_id;
        
        -- Calculate tier based on points
        new_tier := calculate_tier(total_points);
        
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
        
        -- Update fighter profile
        UPDATE fighter_profiles
        SET 
            points = total_points,
            wins = total_wins,
            losses = total_losses,
            draws = total_draws,
            knockouts = total_knockouts,
            win_percentage = new_win_percentage,
            ko_percentage = new_ko_percentage,
            tier = new_tier,
            updated_at = NOW()
        WHERE user_id = fighter_record.user_id;
    END LOOP;
END $$;

-- ============================================
-- 10. GRANT PERMISSIONS
-- ============================================
GRANT EXECUTE ON FUNCTION calculate_fight_points(TEXT, TEXT) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION calculate_tier(INTEGER) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION get_consecutive_losses(UUID) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION get_consecutive_wins(UUID) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION get_tier_index(TEXT) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION get_tier_name(INTEGER) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION update_fighter_stats_after_fight() TO authenticated, anon;
GRANT EXECUTE ON FUNCTION update_fighter_tier() TO authenticated, anon;

-- ============================================
-- 11. VERIFICATION TESTS
-- ============================================
DO $$
BEGIN
    -- Test points calculation
    IF calculate_fight_points('Win', 'Decision') != 5 THEN
        RAISE EXCEPTION 'Points calculation test failed: Win Decision should be 5';
    END IF;
    
    IF calculate_fight_points('Win', 'KO') != 8 THEN
        RAISE EXCEPTION 'Points calculation test failed: Win KO should be 8';
    END IF;
    
    IF calculate_fight_points('Loss', 'Decision') != -3 THEN
        RAISE EXCEPTION 'Points calculation test failed: Loss Decision should be -3';
    END IF;
    
    IF calculate_fight_points('Draw', 'Decision') != 0 THEN
        RAISE EXCEPTION 'Points calculation test failed: Draw should be 0';
    END IF;
    
    -- Test tier calculation
    IF calculate_tier(0) != 'Amateur' THEN
        RAISE EXCEPTION 'Tier calculation test failed: 0 points should be Amateur';
    END IF;
    
    IF calculate_tier(29) != 'Amateur' THEN
        RAISE EXCEPTION 'Tier calculation test failed: 29 points should be Amateur';
    END IF;
    
    IF calculate_tier(30) != 'Semi-Pro' THEN
        RAISE EXCEPTION 'Tier calculation test failed: 30 points should be Semi-Pro';
    END IF;
    
    IF calculate_tier(70) != 'Pro' THEN
        RAISE EXCEPTION 'Tier calculation test failed: 70 points should be Pro';
    END IF;
    
    IF calculate_tier(140) != 'Contender' THEN
        RAISE EXCEPTION 'Tier calculation test failed: 140 points should be Contender';
    END IF;
    
    IF calculate_tier(280) != 'Elite' THEN
        RAISE EXCEPTION 'Tier calculation test failed: 280 points should be Elite';
    END IF;
    
    RAISE NOTICE '✅ All calculation system tests passed!';
    RAISE NOTICE '✅ Complete calculation system verification and fix completed successfully!';
END $$;

