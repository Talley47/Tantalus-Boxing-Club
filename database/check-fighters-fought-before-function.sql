-- Helper function to check if two fighters have fought before (for mandatory fights)
-- This prevents fighters from fighting the same opponent before weekly reset
-- Note: This function is optional - the frontend code handles validation directly
-- But it can be useful for database-level checks or triggers

CREATE OR REPLACE FUNCTION have_fighters_fought_before(
  fighter1_profile_id UUID,
  fighter2_profile_id UUID,
  since_date TIMESTAMP WITH TIME ZONE DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
  fight_count INTEGER;
BEGIN
  -- If since_date is provided, only count fights after that date
  IF since_date IS NOT NULL THEN
    SELECT COUNT(*) INTO fight_count
    FROM scheduled_fights
    WHERE status = 'Completed'
      AND (
        (fighter1_id = fighter1_profile_id AND fighter2_id = fighter2_profile_id) OR
        (fighter1_id = fighter2_profile_id AND fighter2_id = fighter1_profile_id)
      )
      AND created_at >= since_date;
  ELSE
    -- If no date provided, check all completed fights
    SELECT COUNT(*) INTO fight_count
    FROM scheduled_fights
    WHERE status = 'Completed'
      AND (
        (fighter1_id = fighter1_profile_id AND fighter2_id = fighter2_profile_id) OR
        (fighter1_id = fighter2_profile_id AND fighter2_id = fighter1_profile_id)
      );
  END IF;
  
  RETURN fight_count > 0;
END;
$$ LANGUAGE plpgsql;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION have_fighters_fought_before(UUID, UUID, TIMESTAMP WITH TIME ZONE) TO authenticated;

COMMENT ON FUNCTION have_fighters_fought_before(UUID, UUID, TIMESTAMP WITH TIME ZONE) IS 
  'Checks if two fighters have fought before (completed fights). If since_date is provided, only checks fights after that date. Used to prevent mandatory fights between fighters who have already fought before weekly reset. Can be called with 2 or 3 parameters (since_date is optional).';

-- Example usage:
-- SELECT have_fighters_fought_before('fighter1_id', 'fighter2_id'); -- Check all time
-- SELECT have_fighters_fought_before('fighter1_id', 'fighter2_id', NOW() - INTERVAL '7 days'); -- Check last 7 days

