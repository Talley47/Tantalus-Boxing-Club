-- Update notifications table to allow 'Callout' and 'Training Camp' types
-- This is needed for the new Smart Matchmaking, Training Camp, and Callout systems

-- Drop existing CHECK constraints (try common names)
ALTER TABLE notifications DROP CONSTRAINT IF EXISTS notifications_type_check;
ALTER TABLE notifications DROP CONSTRAINT IF EXISTS notifications_type_check1;
ALTER TABLE notifications DROP CONSTRAINT IF EXISTS notifications_type_check2;

-- Also try to find and drop any CHECK constraint on the type column
DO $$ 
DECLARE
    constraint_record RECORD;
BEGIN
    FOR constraint_record IN 
        SELECT conname
        FROM pg_constraint
        WHERE conrelid = 'notifications'::regclass
        AND contype = 'c'
        AND pg_get_constraintdef(oid) LIKE '%type%IN%'
    LOOP
        EXECUTE 'ALTER TABLE notifications DROP CONSTRAINT ' || quote_ident(constraint_record.conname);
    END LOOP;
END $$;

-- Add the new CHECK constraint with all allowed types
ALTER TABLE notifications 
ADD CONSTRAINT notifications_type_check 
CHECK (type IN (
    'Match', 
    'Tournament', 
    'Tier', 
    'Dispute', 
    'Award', 
    'General',
    'Callout',
    'Training Camp'
));

