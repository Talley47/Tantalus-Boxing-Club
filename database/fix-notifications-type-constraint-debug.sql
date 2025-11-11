-- Fix notifications type constraint violation - DEBUG VERSION
-- This script has extensive logging to help debug the issue
-- Run this in Supabase SQL Editor

-- STEP 0: Show current state BEFORE making changes
DO $$
DECLARE
    constraint_count INTEGER;
    invalid_count INTEGER;
    invalid_types TEXT[];
BEGIN
    -- Count constraints
    SELECT COUNT(*) INTO constraint_count
    FROM pg_constraint
    WHERE conrelid = 'notifications'::regclass
    AND contype = 'c';
    
    RAISE NOTICE '=== BEFORE FIX ===';
    RAISE NOTICE 'Check constraints found: %', constraint_count;
    
    -- Count invalid rows
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
        RAISE NOTICE 'Invalid rows found: %', invalid_count;
        RAISE NOTICE 'Invalid types: %', invalid_types;
    ELSE
        RAISE NOTICE 'No invalid rows found';
    END IF;
END $$;

BEGIN;

-- STEP 1: Drop ALL check constraints on notifications table
DO $$
DECLARE
    r RECORD;
    dropped_count INTEGER := 0;
BEGIN
    RAISE NOTICE '=== STEP 1: Dropping constraints ===';
    
    FOR r IN 
        SELECT conname, pg_get_constraintdef(oid) as def
        FROM pg_constraint
        WHERE conrelid = 'notifications'::regclass
        AND contype = 'c'
    LOOP
        BEGIN
            EXECUTE 'ALTER TABLE notifications DROP CONSTRAINT ' || quote_ident(r.conname) || ' CASCADE';
            dropped_count := dropped_count + 1;
            RAISE NOTICE 'Dropped constraint: % (definition: %)', r.conname, r.def;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE WARNING 'Failed to drop constraint %: %', r.conname, SQLERRM;
        END;
    END LOOP;
    
    IF dropped_count = 0 THEN
        RAISE NOTICE 'No constraints found to drop';
    ELSE
        RAISE NOTICE 'Dropped % constraint(s)', dropped_count;
    END IF;
END $$;

-- STEP 2: Show what types exist before fixing
DO $$
DECLARE
    type_list TEXT;
BEGIN
    RAISE NOTICE '=== STEP 2: Current notification types ===';
    SELECT STRING_AGG(DISTINCT type, ', ' ORDER BY type)
    INTO type_list
    FROM notifications;
    RAISE NOTICE 'Types found: %', COALESCE(type_list, 'NONE');
END $$;

-- STEP 3: Fix 'Training Camp' -> 'TrainingCamp'
DO $$
DECLARE
    updated_count INTEGER;
BEGIN
    RAISE NOTICE '=== STEP 3: Fixing "Training Camp" -> "TrainingCamp" ===';
    
    UPDATE notifications
    SET type = 'TrainingCamp'
    WHERE type = 'Training Camp';
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    RAISE NOTICE 'Updated % row(s)', updated_count;
END $$;

-- STEP 4: Fix all other invalid types -> 'General'
DO $$
DECLARE
    updated_count INTEGER;
    invalid_types_before TEXT[];
    invalid_types_after TEXT[];
BEGIN
    RAISE NOTICE '=== STEP 4: Fixing other invalid types -> "General" ===';
    
    -- Show what invalid types exist before
    SELECT ARRAY_AGG(DISTINCT type)
    INTO invalid_types_before
    FROM notifications
    WHERE type IS NOT NULL
    AND type NOT IN (
        'Match', 'Tournament', 'Tier', 'Dispute', 'Award', 'General',
        'FightRequest', 'TrainingCamp', 'Callout', 'FightUrlSubmission',
        'Event', 'News', 'NewFighter'
    );
    
    IF invalid_types_before IS NOT NULL AND array_length(invalid_types_before, 1) > 0 THEN
        RAISE NOTICE 'Invalid types before fix: %', invalid_types_before;
    END IF;
    
    -- Update invalid types
    UPDATE notifications
    SET type = 'General'
    WHERE type IS NOT NULL
    AND type NOT IN (
        'Match', 'Tournament', 'Tier', 'Dispute', 'Award', 'General',
        'FightRequest', 'TrainingCamp', 'Callout', 'FightUrlSubmission',
        'Event', 'News', 'NewFighter'
    );
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    RAISE NOTICE 'Updated % row(s) to "General"', updated_count;
    
    -- Show what invalid types exist after
    SELECT ARRAY_AGG(DISTINCT type)
    INTO invalid_types_after
    FROM notifications
    WHERE type IS NOT NULL
    AND type NOT IN (
        'Match', 'Tournament', 'Tier', 'Dispute', 'Award', 'General',
        'FightRequest', 'TrainingCamp', 'Callout', 'FightUrlSubmission',
        'Event', 'News', 'NewFighter'
    );
    
    IF invalid_types_after IS NOT NULL AND array_length(invalid_types_after, 1) > 0 THEN
        RAISE WARNING 'Still have invalid types after fix: %', invalid_types_after;
    END IF;
END $$;

-- STEP 5: Verify no invalid types remain
DO $$
DECLARE
    invalid_count INTEGER;
    invalid_types TEXT[];
BEGIN
    RAISE NOTICE '=== STEP 5: Verifying all types are valid ===';
    
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
        RAISE EXCEPTION 'Still have % invalid notification types: %. Cannot recreate constraint.', invalid_count, invalid_types;
    ELSE
        RAISE NOTICE '✅ All notification types are valid!';
    END IF;
END $$;

-- STEP 6: Recreate the constraint
DO $$
BEGIN
    RAISE NOTICE '=== STEP 6: Recreating constraint ===';
    
    -- Check if constraint already exists
    IF EXISTS (
        SELECT 1 
        FROM pg_constraint 
        WHERE conrelid = 'notifications'::regclass 
        AND conname = 'notifications_type_check'
    ) THEN
        RAISE WARNING 'Constraint notifications_type_check already exists!';
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

-- STEP 7: Final verification
DO $$
DECLARE
    final_invalid_count INTEGER;
BEGIN
    RAISE NOTICE '=== STEP 7: Final verification ===';
    
    SELECT COUNT(*)
    INTO final_invalid_count
    FROM notifications
    WHERE type NOT IN (
        'Match', 'Tournament', 'Tier', 'Dispute', 'Award', 'General',
        'FightRequest', 'TrainingCamp', 'Callout', 'FightUrlSubmission',
        'Event', 'News', 'NewFighter'
    );
    
    IF final_invalid_count > 0 THEN
        RAISE WARNING '⚠️ Still found % invalid notification types after fix!', final_invalid_count;
    ELSE
        RAISE NOTICE '✅ All notification types are valid!';
    END IF;
END $$;

-- Show final summary
SELECT 
    type,
    COUNT(*) as count
FROM notifications
GROUP BY type
ORDER BY count DESC;

