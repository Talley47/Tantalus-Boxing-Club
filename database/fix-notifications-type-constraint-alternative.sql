-- Alternative approach: Fix notifications type constraint violation
-- This version handles edge cases like NULL, whitespace, and case sensitivity
-- Run this in Supabase SQL Editor

BEGIN;

-- STEP 1: First, let's see ALL notification types (including edge cases)
SELECT 
    type,
    LENGTH(type) as type_length,
    COUNT(*) as count
FROM notifications
GROUP BY type, LENGTH(type)
ORDER BY type;

-- STEP 2: Drop constraint using a more aggressive approach
DO $$
DECLARE
    r RECORD;
    constraint_dropped BOOLEAN := false;
BEGIN
    -- Try to find and drop the constraint
    FOR r IN 
        SELECT conname, pg_get_constraintdef(oid) as def
        FROM pg_constraint
        WHERE conrelid = 'notifications'::regclass
        AND contype = 'c'
        AND (conname LIKE '%type%' OR pg_get_constraintdef(oid) LIKE '%type%')
    LOOP
        BEGIN
            -- Try without CASCADE first
            EXECUTE 'ALTER TABLE notifications DROP CONSTRAINT ' || quote_ident(r.conname);
            constraint_dropped := true;
            RAISE NOTICE 'Dropped constraint: %', r.conname;
        EXCEPTION
            WHEN OTHERS THEN
                BEGIN
                    -- Try with CASCADE
                    EXECUTE 'ALTER TABLE notifications DROP CONSTRAINT ' || quote_ident(r.conname) || ' CASCADE';
                    constraint_dropped := true;
                    RAISE NOTICE 'Dropped constraint (with CASCADE): %', r.conname;
                EXCEPTION
                    WHEN OTHERS THEN
                        RAISE WARNING 'Could not drop constraint %: %', r.conname, SQLERRM;
                END;
        END;
    END LOOP;
    
    -- Also try direct drop by name
    IF NOT constraint_dropped THEN
        BEGIN
            ALTER TABLE notifications DROP CONSTRAINT notifications_type_check;
            RAISE NOTICE 'Dropped constraint by name: notifications_type_check';
        EXCEPTION
            WHEN OTHERS THEN
                RAISE WARNING 'Could not drop notifications_type_check: %', SQLERRM;
        END;
    END IF;
END $$;

-- STEP 3: Fix rows - handle whitespace and case issues
-- First, trim whitespace from all types
UPDATE notifications
SET type = TRIM(type)
WHERE type IS NOT NULL AND type != TRIM(type);

-- Fix 'Training Camp' -> 'TrainingCamp'
UPDATE notifications
SET type = 'TrainingCamp'
WHERE LOWER(TRIM(type)) = 'training camp';

-- Fix case variations
UPDATE notifications
SET type = 'Match'
WHERE LOWER(TRIM(type)) = 'match' AND type != 'Match';

UPDATE notifications
SET type = 'Tournament'
WHERE LOWER(TRIM(type)) = 'tournament' AND type != 'Tournament';

UPDATE notifications
SET type = 'General'
WHERE LOWER(TRIM(type)) = 'general' AND type != 'General';

-- Fix all other invalid types -> 'General'
UPDATE notifications
SET type = 'General'
WHERE type IS NOT NULL
AND TRIM(type) NOT IN (
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

-- STEP 4: Verify - show any remaining invalid types
DO $$
DECLARE
    invalid_count INTEGER;
    invalid_types TEXT[];
    sample_ids UUID[];
BEGIN
    SELECT COUNT(*), ARRAY_AGG(DISTINCT type), ARRAY_AGG(id)
    INTO invalid_count, invalid_types, sample_ids
    FROM notifications
    WHERE type IS NOT NULL
    AND TRIM(type) NOT IN (
        'Match', 'Tournament', 'Tier', 'Dispute', 'Award', 'General',
        'FightRequest', 'TrainingCamp', 'Callout', 'FightUrlSubmission',
        'Event', 'News', 'NewFighter'
    )
    LIMIT 10;
    
    IF invalid_count > 0 THEN
        RAISE EXCEPTION 'Still have % invalid notification types: %. Sample IDs: %. Please fix manually.', 
            invalid_count, invalid_types, sample_ids;
    END IF;
    
    RAISE NOTICE '✅ All notification types are valid!';
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

-- Final summary
SELECT 
    type,
    COUNT(*) as count
FROM notifications
GROUP BY type
ORDER BY count DESC;

