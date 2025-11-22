-- Auto-create Opponent Loss Record Trigger
-- When a fighter enters a Win, automatically create a Loss record for their opponent
-- Run this SQL in your Supabase SQL Editor

-- Function to automatically create opponent loss record when a win is entered
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

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS trigger_auto_create_opponent_loss ON fight_records;

-- Create trigger that fires AFTER INSERT
-- Note: This trigger fires after the stats update trigger, so:
-- 1. Winner's win record is inserted
-- 2. Winner's stats are updated (by existing trigger)
-- 3. Opponent's loss record is auto-created (by this trigger)
-- 4. Opponent's stats are automatically updated (by existing trigger on the new INSERT)
CREATE TRIGGER trigger_auto_create_opponent_loss
    AFTER INSERT ON fight_records
    FOR EACH ROW
    EXECUTE FUNCTION auto_create_opponent_loss();

-- Grant execute permission
GRANT EXECUTE ON FUNCTION auto_create_opponent_loss() TO authenticated, anon;

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✅ Auto-create opponent loss trigger created successfully!';
END $$;

