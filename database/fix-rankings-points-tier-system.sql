-- Fix Rankings, Points, Tier, and Demotion System
-- Run this in Supabase SQL Editor
-- UPDATED: Loss = -2 (not -3), KO bonus only for winners

-- ============================================
-- 1. Fix Points Calculation Function
-- ============================================
-- Update points calculation: Win +5, Loss -2, Draw 0, KO/TKO bonus +3 (only for winners)
CREATE OR REPLACE FUNCTION calculate_fight_points(result TEXT, method TEXT)
RETURNS INTEGER AS $$
DECLARE
    base_points INTEGER;
    ko_bonus INTEGER := 0;
BEGIN
    -- Base points (CORRECTED: Loss = -2)
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
-- 2. Update Tier Thresholds
-- ============================================
-- Amateur: ≤29, Semi-Pro: 30-69, Pro: 70-139, Contender: 140-279, Elite: ≥280
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
        RETURN 'Amateur';    -- ≤29 points (default start)
    END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================
-- 3. Enhanced Demotion System
-- ============================================
-- Get consecutive losses (for demotion check - 5 losses in a row)
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
            EXIT;
        END IF;
    END LOOP;
    
    RETURN consecutive_count;
END;
$$ LANGUAGE plpgsql;

-- Get consecutive wins (for promotion back - 5 wins in a row)
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
            EXIT;
        END IF;
    END LOOP;
    
    RETURN consecutive_count;
END;
$$ LANGUAGE plpgsql;

-- Get tier index (for demotion/promotion calculations)
CREATE OR REPLACE FUNCTION get_tier_index(tier_name TEXT)
RETURNS INTEGER AS $$
BEGIN
    CASE tier_name
        WHEN 'Amateur' THEN RETURN 0;
        WHEN 'Semi-Pro' THEN RETURN 1;
        WHEN 'Pro' THEN RETURN 2;
        WHEN 'Contender' THEN RETURN 3;
        WHEN 'Elite' THEN RETURN 4;
        ELSE RETURN 0;
    END CASE;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Get tier name from index
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
-- 4. Stats Update Trigger Function
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
    calculated_points := calculate_fight_points(NEW.result, NEW.method);
    
    -- Update points_earned in the fight record to match calculated value
    -- This ensures consistency even if frontend sends wrong value
    UPDATE fight_records
    SET points_earned = calculated_points
    WHERE id = NEW.id;
    
    -- Get current fighter stats
    SELECT points, wins, losses, draws, knockouts, (wins + losses + draws) 
    INTO fighter_points, fighter_wins, fighter_losses, fighter_draws, fighter_knockouts, total_fights
    FROM fighter_profiles 
    WHERE user_id = NEW.fighter_id;
    
    -- Update wins/losses/draws/knockouts and points
    -- CRITICAL: Use calculated_points, NOT NEW.points_earned, to ensure correct calculation
    UPDATE fighter_profiles SET
        wins = CASE WHEN NEW.result = 'Win' THEN fighter_wins + 1 ELSE fighter_wins END,
        losses = CASE WHEN NEW.result = 'Loss' THEN fighter_losses + 1 ELSE fighter_losses END,
        draws = CASE WHEN NEW.result = 'Draw' THEN fighter_draws + 1 ELSE fighter_draws END,
        knockouts = CASE WHEN NEW.result = 'Win' AND UPPER(TRIM(NEW.method)) IN ('KO', 'TKO') THEN fighter_knockouts + 1 ELSE fighter_knockouts END,
        points = COALESCE(fighter_points, 0) + calculated_points,  -- Ensure points is never null
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
-- 5. Tier Update with Demotion/Promotion System
-- ============================================
CREATE OR REPLACE FUNCTION update_fighter_tier_after_fight()
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
        
        -- Optional: Create tier history entry
        -- INSERT INTO tier_history (fighter_id, from_tier, to_tier, reason, created_at)
        -- VALUES (
        --     (SELECT id FROM fighter_profiles WHERE user_id = NEW.fighter_id),
        --     previous_tier,
        --     new_tier,
        --     CASE 
        --         WHEN should_demote THEN '5 consecutive losses'
        --         WHEN should_promote_back THEN '5 consecutive wins'
        --         ELSE 'Points threshold reached'
        --     END,
        --     NOW()
        -- );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 6. Drop and Recreate Triggers
-- ============================================
DROP TRIGGER IF EXISTS trigger_update_fighter_stats ON fight_records;
DROP TRIGGER IF EXISTS trigger_update_fighter_tier ON fight_records;

-- Create trigger to update stats (points, wins/losses, percentages)
CREATE TRIGGER trigger_update_fighter_stats
    AFTER INSERT ON fight_records
    FOR EACH ROW
    EXECUTE FUNCTION update_fighter_stats_after_fight();

-- Create trigger to update tier (with demotion/promotion logic)
CREATE TRIGGER trigger_update_fighter_tier
    AFTER INSERT ON fight_records
    FOR EACH ROW
    EXECUTE FUNCTION update_fighter_tier_after_fight();

-- ============================================
-- 7. Update points_earned in existing records
-- ============================================
-- This will recalculate points_earned for all existing fight records
UPDATE fight_records
SET points_earned = calculate_fight_points(result, method)
WHERE points_earned IS NULL OR points_earned != calculate_fight_points(result, method);

-- ============================================
-- 8. Recalculate all fighter stats
-- ============================================
-- Function to recalculate all fighter stats from scratch
CREATE OR REPLACE FUNCTION recalculate_all_fighter_stats()
RETURNS TABLE(
    fighter_id UUID,
    total_points INTEGER,
    wins INTEGER,
    losses INTEGER,
    draws INTEGER,
    knockouts INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        fp.user_id,
        COALESCE(SUM(calculate_fight_points(fr.result, fr.method)), 0)::INTEGER as total_points,
        COUNT(*) FILTER (WHERE fr.result = 'Win')::INTEGER as wins,
        COUNT(*) FILTER (WHERE fr.result = 'Loss')::INTEGER as losses,
        COUNT(*) FILTER (WHERE fr.result = 'Draw')::INTEGER as draws,
        COUNT(*) FILTER (WHERE fr.result = 'Win' AND UPPER(TRIM(fr.method)) IN ('KO', 'TKO'))::INTEGER as knockouts
    FROM fighter_profiles fp
    LEFT JOIN fight_records fr ON fr.fighter_id = fp.user_id
    GROUP BY fp.user_id;
    
    -- Update fighter_profiles with recalculated stats
    UPDATE fighter_profiles fp
    SET 
        points = subq.total_points,
        wins = subq.wins,
        losses = subq.losses,
        draws = subq.draws,
        knockouts = subq.knockouts,
        tier = calculate_tier(subq.total_points),
        win_percentage = CASE 
            WHEN (subq.wins + subq.losses + subq.draws) > 0 
            THEN ROUND((subq.wins::DECIMAL / (subq.wins + subq.losses + subq.draws) * 100)::NUMERIC, 2)
            ELSE 0 
        END,
        ko_percentage = CASE 
            WHEN subq.wins > 0 
            THEN ROUND((subq.knockouts::DECIMAL / subq.wins * 100)::NUMERIC, 2)
            ELSE 0 
        END
    FROM (
        SELECT 
            fp2.user_id,
            COALESCE(SUM(calculate_fight_points(fr2.result, fr2.method)), 0)::INTEGER as total_points,
            COUNT(*) FILTER (WHERE fr2.result = 'Win')::INTEGER as wins,
            COUNT(*) FILTER (WHERE fr2.result = 'Loss')::INTEGER as losses,
            COUNT(*) FILTER (WHERE fr2.result = 'Draw')::INTEGER as draws,
            COUNT(*) FILTER (WHERE fr2.result = 'Win' AND UPPER(TRIM(fr2.method)) IN ('KO', 'TKO'))::INTEGER as knockouts
        FROM fighter_profiles fp2
        LEFT JOIN fight_records fr2 ON fr2.fighter_id = fp2.user_id
        GROUP BY fp2.user_id
    ) subq
    WHERE fp.user_id = subq.user_id;
END;
$$ LANGUAGE plpgsql;

-- Run recalculation
SELECT recalculate_all_fighter_stats();
