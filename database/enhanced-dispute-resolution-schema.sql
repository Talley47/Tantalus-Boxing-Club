-- Enhanced Dispute Resolution Schema Updates
-- This adds support for enhanced dispute resolution with status management, resolution types, and notifications

-- Update disputes table status constraint to include 'In Review'
DO $$ 
BEGIN
    -- Drop the old constraint if it exists
    ALTER TABLE disputes 
    DROP CONSTRAINT IF EXISTS disputes_status_check;
    
    -- Add the new constraint with 'In Review' status
    ALTER TABLE disputes 
    ADD CONSTRAINT disputes_status_check 
    CHECK (status IN ('Open', 'In Review', 'Resolved'));
    
    RAISE NOTICE 'Updated disputes status constraint to include In Review';
END $$;

-- Add resolution_type column to track the type of resolution
ALTER TABLE disputes 
ADD COLUMN IF NOT EXISTS resolution_type VARCHAR(50) CHECK (resolution_type IN (
    'warning',
    'give_win_to_submitter',
    'one_week_suspension',
    'two_week_suspension',
    'one_month_suspension',
    'banned_from_league',
    'dispute_invalid',
    'other'
));

-- Add admin_message_to_disputer and admin_message_to_opponent columns
ALTER TABLE disputes 
ADD COLUMN IF NOT EXISTS admin_message_to_disputer TEXT,
ADD COLUMN IF NOT EXISTS admin_message_to_opponent TEXT;

-- Ensure fight_link column exists (should already exist from dispute-messaging-schema.sql)
ALTER TABLE disputes 
ADD COLUMN IF NOT EXISTS fight_link TEXT;

-- Create index for faster queries on status
CREATE INDEX IF NOT EXISTS idx_disputes_status ON disputes(status);
CREATE INDEX IF NOT EXISTS idx_disputes_opponent_id ON disputes(opponent_id);

-- Add comment
COMMENT ON COLUMN disputes.resolution_type IS 
    'Type of resolution: warning, give_win_to_submitter, one_week_suspension, two_week_suspension, one_month_suspension, banned_from_league, dispute_invalid, other';

COMMENT ON COLUMN disputes.admin_message_to_disputer IS 
    'Message sent by admin to the fighter who submitted the dispute';

COMMENT ON COLUMN disputes.admin_message_to_opponent IS 
    'Message sent by admin to the opponent being disputed against';

