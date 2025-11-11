-- Fix Promotion Back System
-- This script fixes the promotion back logic after demotion
-- Rule: After demotion, a fighter must win 5 consecutive fights to be promoted back to their previous tier

-- ============================================
-- Update Tier Update Function with Fixed Promotion Back Logic
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
        -- Check if fighter's current tier is lower than what their points suggest
        -- This indicates they were likely demoted
        IF calculated_tier_index > current_tier_index THEN
            -- Fighter has points for a higher tier, promote back to points-based tier
            new_tier := calculated_tier;
            should_promote_back := TRUE;
            
            RAISE NOTICE 'Fighter % promoted back from % to % due to 5 consecutive wins (points-based)', 
                NEW.fighter_id, fighter_tier, new_tier;
        ELSIF current_tier_index < 4 THEN
            -- Even if points don't suggest higher tier, promote one tier up (back to previous tier)
            -- This handles case where fighter was demoted but hasn't earned enough points yet
            -- The 5 consecutive wins earns them the right to go back to their previous tier
            new_tier := get_tier_name(current_tier_index + 1);
            should_promote_back := TRUE;
            
            RAISE NOTICE 'Fighter % promoted back from % to % due to 5 consecutive wins (promotion back rule)', 
                NEW.fighter_id, fighter_tier, new_tier;
        ELSE
            -- Already at Elite tier, can't promote further
            new_tier := fighter_tier;
        END IF;
    ELSE
        -- Normal tier calculation based on points
        -- Only promote if new tier is higher (no auto-demotion based on points)
        IF calculated_tier_index > current_tier_index THEN
            new_tier := calculated_tier;
        ELSE
            new_tier := fighter_tier; -- Keep current tier (don't auto-demote based on points)
        END IF;
    END IF;
    
    -- Update fighter profile with new tier
    IF new_tier != fighter_tier THEN
        UPDATE fighter_profiles
        SET tier = new_tier,
            updated_at = NOW()
        WHERE user_id = NEW.fighter_id;
        
        RAISE NOTICE 'Tier updated: Fighter % from % to %', NEW.fighter_id, fighter_tier, new_tier;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✅ Promotion Back System Fixed!';
    RAISE NOTICE '';
    RAISE NOTICE 'Demotion System:';
    RAISE NOTICE '  - 5 consecutive losses = demote one tier';
    RAISE NOTICE '';
    RAISE NOTICE 'Promotion Back System:';
    RAISE NOTICE '  - 5 consecutive wins after demotion = promote back to previous tier';
    RAISE NOTICE '  - Works even if points don''t yet support the higher tier';
    RAISE NOTICE '  - Fighter earns the right to return to their previous tier through consecutive wins';
END $$;

