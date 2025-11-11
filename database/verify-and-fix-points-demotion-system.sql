-- Verify and Fix Points & Demotion System
-- This script ensures the system matches the requirements:
-- Point System: Win = +5, Loss = -3, Draw = 0, KO/TKO Bonus = +3
-- Demotion: 5 consecutive losses = automatic demotion
-- Promotion Back: 5 consecutive wins after demotion = promote back
-- Tier Progression: Amateur → Semi-Pro → Pro → Contender → Elite
-- Warning: 3+ consecutive losses = red warning indicator
-- Run this in Supabase SQL Editor

-- ============================================
-- 1. Fix Points Calculation Function
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
-- 2. Fix Tier Calculation Function
-- ============================================
-- REQUIREMENT: Amateur → Semi-Pro → Pro → Contender → Elite
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
-- 3. Fix Consecutive Losses Function
-- ============================================
-- REQUIREMENT: Check for 5 consecutive losses (for demotion) and 3+ (for warning)
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

-- ============================================
-- 4. Fix Consecutive Wins Function
-- ============================================
-- REQUIREMENT: Check for 5 consecutive wins (for promotion back)
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

-- ============================================
-- 5. Fix Tier Index Functions
-- ============================================
-- REQUIREMENT: Amateur → Semi-Pro → Pro → Contender → Elite
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
-- 6. Fix Stats Update Trigger
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
    -- Calculate points for this fight (Loss = -3, not -2)
    calculated_points := calculate_fight_points(NEW.result, NEW.method);
    
    -- Update points_earned in the fight record to match calculated value
    UPDATE fight_records
    SET points_earned = calculated_points
    WHERE id = NEW.id;
    
    -- Get current fighter stats BEFORE updating
    SELECT COALESCE(points, 0), COALESCE(wins, 0), COALESCE(losses, 0), COALESCE(draws, 0), COALESCE(knockouts, 0), (COALESCE(wins, 0) + COALESCE(losses, 0) + COALESCE(draws, 0)) 
    INTO fighter_points, fighter_wins, fighter_losses, fighter_draws, fighter_knockouts, total_fights
    FROM fighter_profiles 
    WHERE user_id = NEW.fighter_id;
    
    -- Update wins/losses/draws/knockouts and points
    UPDATE fighter_profiles SET
        wins = CASE WHEN NEW.result = 'Win' THEN fighter_wins + 1 ELSE fighter_wins END,
        losses = CASE WHEN NEW.result = 'Loss' THEN fighter_losses + 1 ELSE fighter_losses END,
        draws = CASE WHEN NEW.result = 'Draw' THEN fighter_draws + 1 ELSE fighter_draws END,
        knockouts = CASE WHEN NEW.result = 'Win' AND UPPER(TRIM(NEW.method)) IN ('KO', 'TKO') THEN fighter_knockouts + 1 ELSE fighter_knockouts END,
        points = fighter_points + calculated_points,  -- Use calculated points (Loss = -3)
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
        ko_percentage = calc_ko_percentage
    WHERE user_id = NEW.fighter_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 7. Fix Tier Update with Demotion/Promotion System
-- ============================================
-- REQUIREMENT: 5 consecutive losses = demote one tier, 5 consecutive wins = promote back
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
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 8. Drop and Recreate Triggers
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
-- 9. Recalculate All Existing Records
-- ============================================
-- Update points_earned for all existing fight records (Loss = -3)
UPDATE fight_records
SET points_earned = calculate_fight_points(result, method)
WHERE points_earned IS NULL OR points_earned != calculate_fight_points(result, method);

-- ============================================
-- 10. Verification Queries
-- ============================================
-- Test points calculation
SELECT 
    'Win + Decision' as test_case,
    calculate_fight_points('Win', 'Decision') as points,
    CASE WHEN calculate_fight_points('Win', 'Decision') = 5 THEN '✓ PASS' ELSE '✗ FAIL' END as result
UNION ALL
SELECT 
    'Win + KO',
    calculate_fight_points('Win', 'KO'),
    CASE WHEN calculate_fight_points('Win', 'KO') = 8 THEN '✓ PASS' ELSE '✗ FAIL' END
UNION ALL
SELECT 
    'Loss + Decision',
    calculate_fight_points('Loss', 'Decision'),
    CASE WHEN calculate_fight_points('Loss', 'Decision') = -3 THEN '✓ PASS' ELSE '✗ FAIL' END
UNION ALL
SELECT 
    'Loss + TKO',
    calculate_fight_points('Loss', 'TKO'),
    CASE WHEN calculate_fight_points('Loss', 'TKO') = -3 THEN '✓ PASS' ELSE '✗ FAIL' END
UNION ALL
SELECT 
    'Draw + Decision',
    calculate_fight_points('Draw', 'Decision'),
    CASE WHEN calculate_fight_points('Draw', 'Decision') = 0 THEN '✓ PASS' ELSE '✗ FAIL' END;

-- Test tier calculation
SELECT 
    '0 points' as test_case,
    calculate_tier(0) as tier,
    CASE WHEN calculate_tier(0) = 'Amateur' THEN '✓ PASS' ELSE '✗ FAIL' END as result
UNION ALL
SELECT 
    '30 points',
    calculate_tier(30),
    CASE WHEN calculate_tier(30) = 'Semi-Pro' THEN '✓ PASS' ELSE '✗ FAIL' END
UNION ALL
SELECT 
    '70 points',
    calculate_tier(70),
    CASE WHEN calculate_tier(70) = 'Pro' THEN '✓ PASS' ELSE '✗ FAIL' END
UNION ALL
SELECT 
    '140 points',
    calculate_tier(140),
    CASE WHEN calculate_tier(140) = 'Contender' THEN '✓ PASS' ELSE '✗ FAIL' END
UNION ALL
SELECT 
    '280 points',
    calculate_tier(280),
    CASE WHEN calculate_tier(280) = 'Elite' THEN '✓ PASS' ELSE '✗ FAIL' END;

-- Show fighters with 3+ consecutive losses (warning indicator)
SELECT 
    fp.name,
    fp.tier,
    fp.points,
    get_consecutive_losses(fp.user_id) as consecutive_losses,
    CASE 
        WHEN get_consecutive_losses(fp.user_id) >= 5 THEN '⚠️ DEMOTION RISK (5+)'
        WHEN get_consecutive_losses(fp.user_id) >= 3 THEN '⚠️ WARNING (3+)'
        ELSE 'OK'
    END as status
FROM fighter_profiles fp
WHERE get_consecutive_losses(fp.user_id) >= 3
ORDER BY get_consecutive_losses(fp.user_id) DESC, fp.points DESC;

-- Show tier distribution
SELECT 
    tier,
    COUNT(*) as fighter_count,
    MIN(points) as min_points,
    MAX(points) as max_points,
    AVG(points)::INTEGER as avg_points
FROM fighter_profiles
GROUP BY tier
ORDER BY 
    CASE tier
        WHEN 'Amateur' THEN 0
        WHEN 'Semi-Pro' THEN 1
        WHEN 'Pro' THEN 2
        WHEN 'Contender' THEN 3
        WHEN 'Elite' THEN 4
        ELSE 5
    END;

-- Final verification summary
DO $$
BEGIN
    RAISE NOTICE 'Points and Demotion System Verification Complete!';
    RAISE NOTICE 'Point System: Win = +5, Loss = -3, Draw = 0, KO/TKO Bonus = +3';
    RAISE NOTICE 'Demotion: 5 consecutive losses = automatic demotion';
    RAISE NOTICE 'Promotion Back: 5 consecutive wins after demotion = promote back';
    RAISE NOTICE 'Tier Progression: Amateur → Semi-Pro → Pro → Contender → Elite';
    RAISE NOTICE 'Warning: 3+ consecutive losses = red warning indicator';
END $$;

