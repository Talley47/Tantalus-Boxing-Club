-- Fix tournament_participants status check constraint
-- The constraint may be outdated and only allow ('Active', 'Eliminated', 'Withdrawn')
-- but the code expects ('Registered', 'Checked In', 'Active', 'Eliminated', 'Withdrawn', 'Bye')

-- Drop the existing constraint
DO $$
DECLARE
    constraint_name TEXT;
BEGIN
    -- Find the constraint name
    SELECT conname INTO constraint_name
    FROM pg_constraint
    WHERE conrelid = 'tournament_participants'::regclass
    AND contype = 'c'
    AND conname LIKE '%status%';
    
    IF constraint_name IS NOT NULL THEN
        EXECUTE format('ALTER TABLE tournament_participants DROP CONSTRAINT IF EXISTS %I', constraint_name);
        RAISE NOTICE 'Dropped constraint: %', constraint_name;
    ELSE
        RAISE NOTICE 'No status constraint found to drop';
    END IF;
END $$;

-- Add the new constraint with all valid status values
ALTER TABLE tournament_participants
DROP CONSTRAINT IF EXISTS tournament_participants_status_check;

ALTER TABLE tournament_participants
ADD CONSTRAINT tournament_participants_status_check 
CHECK (status IN ('Registered', 'Checked In', 'Active', 'Eliminated', 'Withdrawn', 'Bye'));

-- Update the default value to 'Registered' if it's not already
ALTER TABLE tournament_participants
ALTER COLUMN status SET DEFAULT 'Registered';

-- Update any existing records with invalid status values to 'Registered'
UPDATE tournament_participants
SET status = 'Registered'
WHERE status NOT IN ('Registered', 'Checked In', 'Active', 'Eliminated', 'Withdrawn', 'Bye');

DO $$
BEGIN
    RAISE NOTICE 'Fixed tournament_participants status constraint - now allows: Registered, Checked In, Active, Eliminated, Withdrawn, Bye';
END $$;

