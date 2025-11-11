-- Fix update_fighter_stats() function to resolve ambiguous column references
-- Run this in your Supabase SQL Editor

-- Drop and recreate the function with properly qualified column references
DROP FUNCTION IF EXISTS update_fighter_stats() CASCADE;

CREATE OR REPLACE FUNCTION update_fighter_stats()
RETURNS TRIGGER AS $$
DECLARE
    fighter_points INTEGER;
    total_fights INTEGER;
    win_percentage_calc DECIMAL(5,2);
    ko_percentage_calc DECIMAL(5,2);
BEGIN
    -- Get current fighter stats (use table alias to avoid ambiguity)
    SELECT fp.points, (fp.wins + fp.losses + fp.draws) 
    INTO fighter_points, total_fights
    FROM fighter_profiles fp
    WHERE fp.user_id = NEW.fighter_id;
    
    -- Update wins/losses/draws/knockouts (qualify all column references)
    UPDATE fighter_profiles fp
    SET
        wins = CASE WHEN NEW.result = 'Win' THEN fp.wins + 1 ELSE fp.wins END,
        losses = CASE WHEN NEW.result = 'Loss' THEN fp.losses + 1 ELSE fp.losses END,
        draws = CASE WHEN NEW.result = 'Draw' THEN fp.draws + 1 ELSE fp.draws END,
        knockouts = CASE WHEN NEW.method IN ('KO', 'TKO') AND NEW.result = 'Win' THEN fp.knockouts + 1 ELSE fp.knockouts END,
        points = fp.points + NEW.points_earned
    WHERE fp.user_id = NEW.fighter_id;
    
    -- Calculate percentages using qualified references
    SELECT 
        CASE 
            WHEN (fp.wins + fp.losses + fp.draws) > 0 
            THEN ROUND((fp.wins::DECIMAL / (fp.wins + fp.losses + fp.draws) * 100)::NUMERIC, 2) 
            ELSE 0.00 
        END,
        CASE 
            WHEN fp.wins > 0 AND fp.knockouts IS NOT NULL
            THEN ROUND((fp.knockouts::DECIMAL / fp.wins * 100)::NUMERIC, 2) 
            ELSE 0.00 
        END
    INTO win_percentage_calc, ko_percentage_calc
    FROM fighter_profiles fp
    WHERE fp.user_id = NEW.fighter_id;
    
    -- Update percentages (qualify all column references)
    UPDATE fighter_profiles fp
    SET
        win_percentage = win_percentage_calc,
        ko_percentage = ko_percentage_calc
    WHERE fp.user_id = NEW.fighter_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS update_fighter_stats_trigger ON fight_records;

-- Create trigger
CREATE TRIGGER update_fighter_stats_trigger
    AFTER INSERT ON fight_records
    FOR EACH ROW EXECUTE FUNCTION update_fighter_stats();

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✅ update_fighter_stats() function fixed with qualified column references';
    RAISE NOTICE '✅ Trigger recreated on fight_records table';
END $$;

