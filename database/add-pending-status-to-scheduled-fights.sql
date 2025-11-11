-- Add 'Pending' status to scheduled_fights table
-- This allows fighters to request mandatory fights that need to be accepted

-- First, drop the existing CHECK constraint
DO $$ 
BEGIN
    -- Drop the old constraint if it exists
    ALTER TABLE scheduled_fights 
    DROP CONSTRAINT IF EXISTS scheduled_fights_status_check;
    
    -- Add the new constraint with 'Pending' status
    ALTER TABLE scheduled_fights 
    ADD CONSTRAINT scheduled_fights_status_check 
    CHECK (status IN ('Pending', 'Scheduled', 'Completed', 'Cancelled', 'Disputed'));
    
    RAISE NOTICE 'Updated scheduled_fights status constraint to include Pending';
END $$;

-- Add a column to track who requested the fight (for pending requests)
ALTER TABLE scheduled_fights 
ADD COLUMN IF NOT EXISTS requested_by UUID REFERENCES fighter_profiles(id);

-- Create index for pending fights
CREATE INDEX IF NOT EXISTS idx_scheduled_fights_pending ON scheduled_fights(status, requested_by) 
WHERE status = 'Pending';

