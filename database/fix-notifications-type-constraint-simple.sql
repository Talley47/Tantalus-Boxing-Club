-- Fix notifications type constraint violation - SIMPLE VERSION
-- This script uses a transaction to ensure atomicity
-- Run this in Supabase SQL Editor

BEGIN;

-- STEP 1: Drop the constraint (this should work even with violations)
DO $$
DECLARE
    constraint_name TEXT;
BEGIN
    -- Find the constraint
    SELECT conname INTO constraint_name
    FROM pg_constraint
    WHERE conrelid = 'notifications'::regclass
    AND contype = 'c'
    AND (conname LIKE '%type%' OR pg_get_constraintdef(oid) LIKE '%type%IN%');
    
    IF constraint_name IS NOT NULL THEN
        EXECUTE 'ALTER TABLE notifications DROP CONSTRAINT ' || quote_ident(constraint_name);
        RAISE NOTICE '✅ Dropped constraint: %', constraint_name;
    END IF;
    
    -- Also try common names
    ALTER TABLE notifications DROP CONSTRAINT IF EXISTS notifications_type_check;
END $$;

-- STEP 2: Fix invalid rows
-- Handle 'Training Camp' (with space) -> 'TrainingCamp' (no space)
UPDATE notifications
SET type = 'TrainingCamp'
WHERE type = 'Training Camp';

-- Update other invalid types to 'General'
UPDATE notifications
SET type = 'General'
WHERE type IS NOT NULL
AND type NOT IN (
    'Match', 
    'Tournament', 
    'Tier', 
    'Dispute', 
    'Award', 
    'General',
    'FightRequest',
    'TrainingCamp',
    'Callout',
    'FightUrlSubmission',
    'Event',
    'News',
    'NewFighter'
);

-- STEP 3: Recreate the constraint
ALTER TABLE notifications 
ADD CONSTRAINT notifications_type_check 
CHECK (type IN (
    'Match', 
    'Tournament', 
    'Tier', 
    'Dispute', 
    'Award', 
    'General',
    'FightRequest',
    'TrainingCamp',
    'Callout',
    'FightUrlSubmission',
    'Event',
    'News',
    'NewFighter'
));

COMMIT;

-- Verify the fix
SELECT 
    type,
    COUNT(*) as count
FROM notifications
GROUP BY type
ORDER BY count DESC;

