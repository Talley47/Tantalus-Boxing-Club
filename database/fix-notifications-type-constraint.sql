-- Fix notifications type constraint violation
-- This script finds and fixes invalid notification types
-- Run this in Supabase SQL Editor

-- STEP 1: Drop the constraint FIRST (before fixing rows)
-- This allows us to update rows that currently violate the constraint
DO $$
DECLARE
    constraint_name TEXT;
BEGIN
    -- Try to find and drop the constraint
    SELECT conname INTO constraint_name
    FROM pg_constraint
    WHERE conrelid = 'notifications'::regclass
    AND contype = 'c'
    AND (conname = 'notifications_type_check' OR pg_get_constraintdef(oid) LIKE '%type%IN%');
    
    IF constraint_name IS NOT NULL THEN
        EXECUTE 'ALTER TABLE notifications DROP CONSTRAINT ' || quote_ident(constraint_name);
        RAISE NOTICE '✅ Dropped constraint: %', constraint_name;
    ELSE
        RAISE NOTICE 'ℹ️ No constraint found to drop';
    END IF;
    
    -- Also try dropping by common names
    ALTER TABLE notifications DROP CONSTRAINT IF EXISTS notifications_type_check;
    ALTER TABLE notifications DROP CONSTRAINT IF EXISTS notifications_type_check1;
    ALTER TABLE notifications DROP CONSTRAINT IF EXISTS notifications_type_check2;
END $$;

-- STEP 2: Show what invalid types exist
DO $$
DECLARE
    invalid_types TEXT[];
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
    invalid_count INTEGER;
BEGIN
    -- Find invalid notification types
    SELECT ARRAY_AGG(DISTINCT type)
    INTO invalid_types
    FROM notifications
    WHERE type IS NOT NULL
    AND type != ALL(valid_types);
    
    -- Count invalid rows
    SELECT COUNT(*)
    INTO invalid_count
    FROM notifications
    WHERE type IS NOT NULL
    AND type != ALL(valid_types);
    
    IF invalid_types IS NOT NULL AND array_length(invalid_types, 1) > 0 THEN
        RAISE NOTICE 'Found % rows with invalid notification types: %', invalid_count, invalid_types;
    ELSE
        RAISE NOTICE '✅ No invalid notification types found';
    END IF;
END $$;

-- STEP 3: Fix invalid rows (now that constraint is dropped)
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

-- STEP 4: Recreate the constraint with all valid types
DO $$
BEGIN
    -- Recreate the constraint with all valid types
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
    
    RAISE NOTICE '✅ Notification type constraint recreated!';
END $$;

-- Verify the fix
DO $$
DECLARE
    invalid_count INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO invalid_count
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
    );
    
    IF invalid_count > 0 THEN
        RAISE WARNING '⚠️ Still found % invalid notification types. Please check manually.', invalid_count;
    ELSE
        RAISE NOTICE '✅ All notification types are valid!';
    END IF;
END $$;

-- Show summary of notification types
SELECT 
    type,
    COUNT(*) as count
FROM notifications
GROUP BY type
ORDER BY count DESC;

