-- Fix notifications type constraint violation - FINAL VERSION
-- This script MUST be run in a transaction
-- Run this in Supabase SQL Editor

-- IMPORTANT: Run the diagnostic script first to see what invalid types exist!

BEGIN;

-- STEP 1: Drop ALL check constraints on notifications table
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN 
        SELECT conname
        FROM pg_constraint
        WHERE conrelid = 'notifications'::regclass
        AND contype = 'c'
    LOOP
        EXECUTE 'ALTER TABLE notifications DROP CONSTRAINT ' || quote_ident(r.conname) || ' CASCADE';
        RAISE NOTICE 'Dropped constraint: %', r.conname;
    END LOOP;
END $$;

-- STEP 2: Fix 'Training Camp' -> 'TrainingCamp'
UPDATE notifications
SET type = 'TrainingCamp'
WHERE type = 'Training Camp';

-- STEP 3: Fix all other invalid types -> 'General'
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

-- STEP 4: Verify no invalid types remain
DO $$
DECLARE
    invalid_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO invalid_count
    FROM notifications
    WHERE type NOT IN (
        'Match', 'Tournament', 'Tier', 'Dispute', 'Award', 'General',
        'FightRequest', 'TrainingCamp', 'Callout', 'FightUrlSubmission',
        'Event', 'News', 'NewFighter'
    );
    
    IF invalid_count > 0 THEN
        RAISE EXCEPTION 'Still have % invalid notification types. Cannot proceed.', invalid_count;
    END IF;
END $$;

-- STEP 5: Recreate the constraint
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

-- Verification query
SELECT 
    type,
    COUNT(*) as count
FROM notifications
GROUP BY type
ORDER BY count DESC;

