-- Fix notifications type constraint violation - ROBUST VERSION
-- This script finds and fixes invalid notification types
-- Run this in Supabase SQL Editor

-- STEP 1: First, let's see what we're dealing with
SELECT 
    type,
    COUNT(*) as count
FROM notifications
GROUP BY type
ORDER BY type;

-- STEP 2: Drop ALL constraints on the type column (multiple attempts)
DO $$
DECLARE
    constraint_record RECORD;
    dropped_count INTEGER := 0;
BEGIN
    -- Find and drop all CHECK constraints on the notifications table that involve the type column
    FOR constraint_record IN 
        SELECT conname, pg_get_constraintdef(oid) as def
        FROM pg_constraint
        WHERE conrelid = 'notifications'::regclass
        AND contype = 'c'
        AND (pg_get_constraintdef(oid) LIKE '%type%' OR conname LIKE '%type%')
    LOOP
        BEGIN
            EXECUTE 'ALTER TABLE notifications DROP CONSTRAINT ' || quote_ident(constraint_record.conname) || ' CASCADE';
            dropped_count := dropped_count + 1;
            RAISE NOTICE '✅ Dropped constraint: %', constraint_record.conname;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE WARNING '⚠️ Could not drop constraint %: %', constraint_record.conname, SQLERRM;
        END;
    END LOOP;
    
    -- Also try common constraint names
    BEGIN
        ALTER TABLE notifications DROP CONSTRAINT IF EXISTS notifications_type_check CASCADE;
        RAISE NOTICE '✅ Attempted to drop notifications_type_check';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE WARNING '⚠️ Could not drop notifications_type_check: %', SQLERRM;
    END;
    
    BEGIN
        ALTER TABLE notifications DROP CONSTRAINT IF EXISTS notifications_type_check1 CASCADE;
    EXCEPTION
        WHEN OTHERS THEN NULL;
    END;
    
    BEGIN
        ALTER TABLE notifications DROP CONSTRAINT IF EXISTS notifications_type_check2 CASCADE;
    EXCEPTION
        WHEN OTHERS THEN NULL;
    END;
    
    RAISE NOTICE '✅ Dropped % constraint(s)', dropped_count;
END $$;

-- STEP 3: Show invalid types (if any still exist)
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
        RAISE NOTICE '⚠️ Found % rows with invalid notification types: %', invalid_count, invalid_types;
    ELSE
        RAISE NOTICE '✅ No invalid notification types found';
    END IF;
END $$;

-- STEP 4: Fix invalid rows
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

-- STEP 5: Verify all rows are valid before recreating constraint
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
    invalid_count INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO invalid_count
    FROM notifications
    WHERE type IS NOT NULL
    AND type != ALL(valid_types);
    
    IF invalid_count > 0 THEN
        RAISE EXCEPTION 'Still have % invalid notification types. Cannot recreate constraint.', invalid_count;
    END IF;
    
    RAISE NOTICE '✅ All notification types are valid. Safe to recreate constraint.';
END $$;

-- STEP 6: Recreate the constraint with all valid types
DO $$
BEGIN
    -- Check if constraint already exists
    IF EXISTS (
        SELECT 1 
        FROM pg_constraint 
        WHERE conrelid = 'notifications'::regclass 
        AND conname = 'notifications_type_check'
    ) THEN
        RAISE NOTICE 'ℹ️ Constraint notifications_type_check already exists. Skipping recreation.';
    ELSE
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
        
        RAISE NOTICE '✅ Notification type constraint recreated successfully!';
    END IF;
END $$;

-- STEP 7: Final verification
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

-- Show final summary of notification types
SELECT 
    type,
    COUNT(*) as count
FROM notifications
GROUP BY type
ORDER BY count DESC;

