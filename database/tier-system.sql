-- Tier System with Automatic Promotion/Demotion
-- Run this in your Supabase SQL Editor

-- Function to calculate tier based on points
-- Updated thresholds: Amateur ≤ 19, Semi-Pro 20-39, Pro 40-89, Contender 90-149, Elite ≥ 150
CREATE OR REPLACE FUNCTION calculate_tier(points INTEGER)
RETURNS TEXT AS $$
BEGIN
    IF points >= 150 THEN
        RETURN 'Elite';
    ELSIF points >= 90 THEN
        RETURN 'Contender';
    ELSIF points >= 40 THEN
        RETURN 'Pro';
    ELSIF points >= 20 THEN
        RETURN 'Semi-Pro';
    ELSE
        RETURN 'Amateur'; -- Default start, ≤ 19 points
    END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Function to check consecutive losses for a fighter
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
        ORDER BY date DESC
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

-- Function to get tier index (for demotion logic)
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

-- Function to get tier name from index
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

-- Function to update fighter tier after fight record is added
CREATE OR REPLACE FUNCTION update_fighter_tier()
RETURNS TRIGGER AS $$
DECLARE
    fighter_points INTEGER;
    fighter_tier TEXT;
    calculated_tier TEXT;
    current_tier_index INTEGER;
    consecutive_losses_count INTEGER;
    should_demote BOOLEAN := FALSE;
    new_tier TEXT;
BEGIN
    -- Get current fighter stats
    SELECT points, tier INTO fighter_points, fighter_tier
    FROM fighter_profiles
    WHERE user_id = NEW.fighter_id;
    
    -- Check consecutive losses for demotion
    consecutive_losses_count := get_consecutive_losses(NEW.fighter_id);
    
    IF consecutive_losses_count >= 4 THEN
        -- Demote one tier
        current_tier_index := get_tier_index(fighter_tier);
        IF current_tier_index > 0 THEN
            new_tier := get_tier_name(current_tier_index - 1);
            should_demote := TRUE;
        END IF;
    END IF;
    
    -- Calculate tier based on points (if not demoting)
    IF NOT should_demote THEN
        calculated_tier := calculate_tier(fighter_points);
        
        -- Only promote if new tier is higher (no auto-demotion based on points)
        current_tier_index := get_tier_index(fighter_tier);
        IF get_tier_index(calculated_tier) > current_tier_index THEN
            new_tier := calculated_tier;
        ELSE
            new_tier := fighter_tier; -- Keep current tier
        END IF;
    END IF;
    
    -- Update fighter profile with new tier
    UPDATE fighter_profiles
    SET tier = new_tier,
        updated_at = NOW()
    WHERE user_id = NEW.fighter_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS update_fighter_tier_trigger ON fight_records;

-- Create trigger to update tier when fight record is added
CREATE TRIGGER update_fighter_tier_trigger
    AFTER INSERT ON fight_records
    FOR EACH ROW
    EXECUTE FUNCTION update_fighter_tier();

-- Function to manually update all fighter tiers (for initial setup or batch update)
CREATE OR REPLACE FUNCTION update_all_fighter_tiers()
RETURNS TABLE(
    fighter_id UUID,
    old_tier TEXT,
    new_tier TEXT,
    points INTEGER
) AS $$
DECLARE
    fighter_record RECORD;
    calculated_tier TEXT;
    consecutive_losses_count INTEGER;
    current_tier_index INTEGER;
    new_tier TEXT;
BEGIN
    FOR fighter_record IN
        SELECT user_id, points, tier
        FROM fighter_profiles
    LOOP
        -- Check for demotion (4 consecutive losses)
        consecutive_losses_count := get_consecutive_losses(fighter_record.user_id);
        
        IF consecutive_losses_count >= 4 THEN
            -- Demote one tier
            current_tier_index := get_tier_index(fighter_record.tier);
            IF current_tier_index > 0 THEN
                new_tier := get_tier_name(current_tier_index - 1);
            ELSE
                new_tier := fighter_record.tier; -- Already at lowest tier
            END IF;
        ELSE
            -- Calculate tier based on points
            calculated_tier := calculate_tier(fighter_record.points);
            current_tier_index := get_tier_index(fighter_record.tier);
            
            -- Only promote if higher tier
            IF get_tier_index(calculated_tier) > current_tier_index THEN
                new_tier := calculated_tier;
            ELSE
                new_tier := fighter_record.tier; -- Keep current tier
            END IF;
        END IF;
        
        -- Update fighter tier
        UPDATE fighter_profiles
        SET tier = new_tier,
            updated_at = NOW()
        WHERE user_id = fighter_record.user_id;
        
        -- Return result
        RETURN QUERY SELECT
            fighter_record.user_id,
            fighter_record.tier,
            new_tier,
            fighter_record.points;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✅ Tier system functions created!';
    RAISE NOTICE '✅ Automatic promotion/demotion trigger enabled';
    RAISE NOTICE '';
    RAISE NOTICE 'Tier Thresholds (Updated):';
    RAISE NOTICE '  Amateur: 0-19 points (default start)';
    RAISE NOTICE '  Semi-Pro: 20-39 points';
    RAISE NOTICE '  Pro: 40-89 points';
    RAISE NOTICE '  Contender: 90-149 points';
    RAISE NOTICE '  Elite: 150+ points (eligible for live/media benefits)';
    RAISE NOTICE '';
    RAISE NOTICE 'Demotion Rule: 4 consecutive losses = demote one tier';
    RAISE NOTICE '';
    RAISE NOTICE 'Weight Class Movement:';
    RAISE NOTICE '  - Fighters can move up or down 3 weight classes from their original';
    RAISE NOTICE '  - Tiers and demotion are calculated independently of weight class';
    RAISE NOTICE '  - Weight class changes do not affect tier or points';
    RAISE NOTICE '';
    RAISE NOTICE 'To update all fighter tiers, run: SELECT * FROM update_all_fighter_tiers();';
END $$;

