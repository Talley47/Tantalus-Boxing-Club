-- Weekly Smart Matchmaking Reset Function
-- This function cancels old mandatory fights (past their 1-week deadline) and can be called
-- to trigger a new round of matchmaking. The actual matchmaking logic is handled in the application.

-- Function to cancel old mandatory fights that are past their 1-week deadline
CREATE OR REPLACE FUNCTION cancel_old_mandatory_fights()
RETURNS TABLE(cleared_count INTEGER) AS $$
DECLARE
  cleared_count INTEGER;
  one_week_ago TIMESTAMP WITH TIME ZONE;
BEGIN
  -- Calculate 1 week ago from now
  one_week_ago := NOW() - INTERVAL '7 days';
  
  -- Cancel all mandatory fights that were created more than 1 week ago and are still scheduled
  UPDATE scheduled_fights
  SET status = 'Cancelled'
  WHERE match_type = 'auto_mandatory'
    AND status = 'Scheduled'
    AND created_at < one_week_ago;
  
  GET DIAGNOSTICS cleared_count = ROW_COUNT;
  
  RETURN QUERY SELECT cleared_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users (admins will call this)
GRANT EXECUTE ON FUNCTION cancel_old_mandatory_fights() TO authenticated;

-- Optional: Set up pg_cron to run this weekly (requires pg_cron extension)
-- Uncomment the following if you have pg_cron installed:
/*
SELECT cron.schedule(
  'weekly-smart-matchmaking-reset',
  '0 0 * * 0', -- Every Sunday at midnight UTC
  $$SELECT cancel_old_mandatory_fights();$$
);
*/

-- Note: The actual matchmaking (creating new fights) must be done via the application
-- by calling smartMatchmakingService.autoMatchFighters() after canceling old fights.
-- This is because the matching logic is complex and requires application-level filtering.

