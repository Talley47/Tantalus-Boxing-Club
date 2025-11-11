-- Fix notifications type constraint violation - FORCE VERSION
-- This script uses a more aggressive approach to fix the constraint
-- Run this in Supabase SQL Editor

-- STEP 1: Show current notification types
SELECT 
    type,
    COUNT(*) as count
FROM notifications
GROUP BY type
ORDER BY type;

-- STEP 2: Find and show invalid types
SELECT 
    type,
    COUNT(*) as count
FROM notifications
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
)
GROUP BY type;

-- STEP 3: Drop constraint using CASCADE (forces drop even with violations)
DO $$
DECLARE
    constraint_record RECORD;
BEGIN
    -- Find all CHECK constraints on notifications table
    FOR constraint_record IN 
        SELECT conname, pg_get_constraintdef(oid) as def
        FROM pg_constraint
        WHERE conrelid = 'notifications'::regclass
        AND contype = 'c'
    LOOP
        BEGIN
            -- Try to drop with CASCADE
            EXECUTE 'ALTER TABLE notifications DROP CONSTRAINT ' || quote_ident(constraint_record.conname) || ' CASCADE';
            RAISE NOTICE '✅ Dropped constraint: % (definition: %)', constraint_record.conname, constraint_record.def;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE WARNING '⚠️ Could not drop constraint %: %', constraint_record.conname, SQLERRM;
        END;
    END LOOP;
END $$;

-- STEP 4: Also try direct DROP with IF EXISTS
ALTER TABLE notifications DROP CONSTRAINT IF EXISTS notifications_type_check CASCADE;
ALTER TABLE notifications DROP CONSTRAINT IF EXISTS notifications_type_check1 CASCADE;
ALTER TABLE notifications DROP CONSTRAINT IF EXISTS notifications_type_check2 CASCADE;

-- STEP 5: Now fix invalid rows
DO $$
DECLARE
    valid_types TEXT[] := ARRAY[
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
    ];
    updated_count INTEGER;
BEGIN
    -- Handle 'Training Camp' (with space) -> 'TrainingCamp' (no space)
    UPDATE notifications
    SET type = 'TrainingCamp'
    WHERE type = 'Training Camp';
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    IF updated_count > 0 THEN
        RAISE NOTICE '✅ Updated % rows: "Training Camp" -> "TrainingCamp"', updated_count;
    END IF;
    
    -- Update other invalid types to 'General'
    UPDATE notifications
    SET type = 'General'
    WHERE type IS NOT NULL
    AND type != ALL(valid_types);
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    IF updated_count > 0 THEN
        RAISE NOTICE '✅ Updated % rows: invalid types -> "General"', updated_count;
    END IF;
END $$;

-- STEP 6: Verify all rows are now valid
DO $$
DECLARE
    invalid_count INTEGER;
    invalid_types TEXT[];
BEGIN
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
        RAISE EXCEPTION 'Still have % invalid notification types: %. Please fix manually before recreating constraint.', invalid_count, invalid_types;
    END IF;
    
    RAISE NOTICE '✅ All notification types are valid. Safe to recreate constraint.';
END $$;

-- STEP 7: Recreate the constraint
DO $$
BEGIN
    -- Check if constraint already exists
    IF EXISTS (
        SELECT 1 
        FROM pg_constraint 
        WHERE conrelid = 'notifications'::regclass 
        AND conname = 'notifications_type_check'
    ) THEN
        RAISE NOTICE 'ℹ️ Constraint notifications_type_check already exists.';
    ELSE
        -- Recreate the constraint
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
        
        RAISE NOTICE '✅ Notification type constraint recreated successfully!';
    END IF;
END $$;

-- STEP 8: Final verification
SELECT 
    type,
    COUNT(*) as count
FROM notifications
GROUP BY type
ORDER BY count DESC;

