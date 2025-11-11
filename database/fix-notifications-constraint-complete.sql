-- Complete fix for notifications type constraint violation
-- This script: 1) Diagnoses, 2) Fixes invalid rows, 3) Recreates constraint
-- Run this in Supabase SQL Editor

BEGIN;

-- STEP 1: Show current state
DO $$
DECLARE
    invalid_count INTEGER;
    invalid_types TEXT[];
BEGIN
    RAISE NOTICE '=== DIAGNOSING NOTIFICATION TYPES ===';
    
    -- Count invalid types
    SELECT COUNT(*), ARRAY_AGG(DISTINCT type)
    INTO invalid_count, invalid_types
    FROM notifications
    WHERE type IS NOT NULL
    AND type NOT IN (
        'Match', 'Tournament', 'Tier', 'Dispute', 'Award', 'General',
        'FightRequest', 'TrainingCamp', 'Callout', 'FightUrlSubmission',
        'Event', 'News', 'NewFighter'
    );
    
    IF invalid_count > 0 THEN
        RAISE NOTICE 'Found % invalid rows with types: %', invalid_count, invalid_types;
    ELSE
        RAISE NOTICE 'No invalid types found';
    END IF;
END $$;

-- STEP 2: Drop existing constraint
DO $$
DECLARE
    r RECORD;
    dropped_count INTEGER := 0;
BEGIN
    RAISE NOTICE '=== DROPPING EXISTING CONSTRAINTS ===';
    
    FOR r IN 
        SELECT conname, pg_get_constraintdef(oid) as def
        FROM pg_constraint
        WHERE conrelid = 'notifications'::regclass
        AND contype = 'c'
    LOOP
        BEGIN
            EXECUTE 'ALTER TABLE notifications DROP CONSTRAINT ' || quote_ident(r.conname);
            dropped_count := dropped_count + 1;
            RAISE NOTICE 'Dropped: %', r.conname;
        EXCEPTION
            WHEN OTHERS THEN
                BEGIN
                    EXECUTE 'ALTER TABLE notifications DROP CONSTRAINT ' || quote_ident(r.conname) || ' CASCADE';
                    dropped_count := dropped_count + 1;
                    RAISE NOTICE 'Dropped (CASCADE): %', r.conname;
                EXCEPTION
                    WHEN OTHERS THEN
                        RAISE WARNING 'Could not drop %: %', r.conname, SQLERRM;
                END;
        END;
    END LOOP;
    
    IF dropped_count = 0 THEN
        RAISE NOTICE 'No constraints found to drop';
    END IF;
END $$;

-- STEP 3: Fix invalid rows
-- Handle common variations and edge cases

-- 3a. Trim whitespace from all types
UPDATE notifications
SET type = TRIM(type)
WHERE type IS NOT NULL AND type != TRIM(type);

-- 3b. Fix 'Training Camp' (with space) -> 'TrainingCamp' (no space)
UPDATE notifications
SET type = 'TrainingCamp'
WHERE LOWER(TRIM(type)) = 'training camp' OR type = 'Training Camp';

-- 3c. Fix case variations (normalize to proper case)
UPDATE notifications
SET type = 'Match'
WHERE LOWER(TRIM(type)) = 'match' AND type != 'Match';

UPDATE notifications
SET type = 'Tournament'
WHERE LOWER(TRIM(type)) = 'tournament' AND type != 'Tournament';

UPDATE notifications
SET type = 'General'
WHERE LOWER(TRIM(type)) = 'general' AND type != 'General';

UPDATE notifications
SET type = 'Event'
WHERE LOWER(TRIM(type)) = 'event' AND type != 'Event';

UPDATE notifications
SET type = 'News'
WHERE LOWER(TRIM(type)) = 'news' AND type != 'News';

-- 3d. Fix all other invalid types -> 'General'
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

-- STEP 4: Verify all rows are now valid
DO $$
DECLARE
    invalid_count INTEGER;
    invalid_types TEXT[];
    sample_ids UUID[];
BEGIN
    RAISE NOTICE '=== VERIFYING ALL ROWS ARE VALID ===';
    
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
        RAISE EXCEPTION 'Still have % invalid notification types: %. Sample IDs: %. Cannot proceed.', 
            invalid_count, invalid_types, sample_ids;
    END IF;
    
    RAISE NOTICE '✅ All notification types are valid!';
END $$;

-- STEP 5: Recreate the constraint with correct values
DO $$
BEGIN
    RAISE NOTICE '=== RECREATING CONSTRAINT ===';
    
    -- Check if constraint already exists
    IF EXISTS (
        SELECT 1 
        FROM pg_constraint 
        WHERE conrelid = 'notifications'::regclass 
        AND conname = 'notifications_type_check'
    ) THEN
        RAISE WARNING 'Constraint already exists!';
    ELSE
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
        
        RAISE NOTICE '✅ Constraint recreated successfully!';
    END IF;
END $$;

COMMIT;

-- STEP 6: Final verification - show summary
SELECT 
    type,
    COUNT(*) as count
FROM notifications
GROUP BY type
ORDER BY count DESC;

