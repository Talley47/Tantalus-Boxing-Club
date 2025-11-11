-- Quick fix for reset_all_fighters_records tier constraint issue
-- This script updates the function to dynamically detect the correct tier value
-- Run this in Supabase SQL Editor

-- First, let's check what the constraint expects
DO $$
DECLARE
    constraint_def TEXT;
    tier_value TEXT := 'Amateur';
BEGIN
    -- Get constraint definition
    SELECT pg_get_constraintdef(oid)
    INTO constraint_def
    FROM pg_constraint
    WHERE conrelid = 'fighter_profiles'::regclass
    AND conname = 'fighter_profiles_tier_check'
    AND contype = 'c';
    
    IF constraint_def IS NULL THEN
        RAISE NOTICE '⚠️ Constraint fighter_profiles_tier_check not found!';
        RAISE NOTICE 'Creating constraint with capitalized values...';
        
        -- Create the constraint with capitalized values
        ALTER TABLE fighter_profiles
        ADD CONSTRAINT fighter_profiles_tier_check 
        CHECK (tier IS NULL OR tier IN ('Amateur', 'Semi-Pro', 'Pro', 'Contender', 'Elite'));
        
        tier_value := 'Amateur';
        RAISE NOTICE '✅ Created constraint with capitalized values';
    ELSE
        RAISE NOTICE 'Constraint definition: %', constraint_def;
        
        -- Determine correct tier value
        IF constraint_def LIKE '%''Amateur''%' OR constraint_def LIKE '%"Amateur"%' THEN
            tier_value := 'Amateur';
            RAISE NOTICE '✅ Constraint expects CAPITALIZED: Amateur';
        ELSIF constraint_def LIKE '%''amateur''%' OR constraint_def LIKE '%"amateur"%' THEN
            tier_value := 'amateur';
            RAISE NOTICE '✅ Constraint expects lowercase: amateur';
        ELSE
            RAISE NOTICE '⚠️ Could not determine case from constraint, using capitalized as default';
            tier_value := 'Amateur';
        END IF;
    END IF;
    
    RAISE NOTICE 'Using tier value: %', tier_value;
END $$;

-- Now update the reset function (this is the same as reset-all-fighters-records-function.sql)
-- The function will dynamically detect the tier value
CREATE OR REPLACE FUNCTION reset_all_fighters_records()
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    updated_count INTEGER;
    deleted_fight_records INTEGER;
    admin_check BOOLEAN;
    tier_value TEXT := 'Amateur'; -- Default to capitalized
    constraint_def TEXT;
BEGIN
    -- Determine correct tier value from constraint
    BEGIN
        SELECT pg_get_constraintdef(oid)
        INTO constraint_def
        FROM pg_constraint
        WHERE conrelid = 'fighter_profiles'::regclass
        AND conname = 'fighter_profiles_tier_check'
        AND contype = 'c';
        
        IF constraint_def IS NOT NULL THEN
            -- Check if constraint expects capitalized or lowercase
            IF constraint_def LIKE '%''Amateur''%' OR constraint_def LIKE '%"Amateur"%' THEN
                tier_value := 'Amateur';
            ELSIF constraint_def LIKE '%''amateur''%' OR constraint_def LIKE '%"amateur"%' THEN
                tier_value := 'amateur';
            END IF;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            -- If we can't determine, use default capitalized
            tier_value := 'Amateur';
    END;
    
    -- Verify user is admin
    BEGIN
        SELECT is_admin_user() INTO admin_check;
    EXCEPTION
        WHEN OTHERS THEN
            admin_check := FALSE;
    END;
    
    IF NOT admin_check THEN
        SELECT EXISTS (
            SELECT 1 FROM profiles 
            WHERE id = auth.uid() 
            AND role = 'admin'
        ) INTO admin_check;
    END IF;
    
    IF NOT admin_check THEN
        SELECT EXISTS (
            SELECT 1 FROM auth.users
            WHERE id = auth.uid()
            AND (
                COALESCE(raw_app_meta_data->>'role', '') = 'admin'
                OR COALESCE(raw_user_meta_data->>'role', '') = 'admin'
                OR email = 'tantalusboxingclub@gmail.com'
            )
        ) INTO admin_check;
    END IF;
    
    IF NOT admin_check THEN
        RAISE EXCEPTION 'Only admins can reset fighters records. Current user role could not be verified as admin.';
    END IF;
    
    -- Delete all fight records
    DELETE FROM fight_records WHERE TRUE;
    GET DIAGNOSTICS deleted_fight_records = ROW_COUNT;
    
    -- Cancel all scheduled fights
    UPDATE scheduled_fights
    SET status = 'Cancelled'
    WHERE status IN ('Scheduled', 'Pending');
    
    -- Clear all rankings
    DELETE FROM rankings WHERE TRUE;
    
    -- Delete related data (if tables exist)
    BEGIN
        DELETE FROM matchmaking_requests WHERE TRUE;
    EXCEPTION
        WHEN undefined_table THEN NULL;
    END;
    
    BEGIN
        DELETE FROM training_camp_invitations WHERE TRUE;
    EXCEPTION
        WHEN undefined_table THEN NULL;
    END;
    
    BEGIN
        DELETE FROM callout_requests WHERE TRUE;
    EXCEPTION
        WHEN undefined_table THEN NULL;
    END;
    
    BEGIN
        DELETE FROM tier_history WHERE TRUE;
    EXCEPTION
        WHEN undefined_table THEN NULL;
    END;
    
    -- Reset all fighters records using the detected tier value
    UPDATE fighter_profiles
    SET
        wins = 0,
        losses = 0,
        draws = 0,
        knockouts = 0,
        points = 0,
        win_percentage = 0.00,
        ko_percentage = 0.00,
        current_streak = 0,
        tier = tier_value,
        updated_at = NOW()
    WHERE TRUE;
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    
    -- Trigger real-time notifications
    PERFORM pg_notify('fighter_profiles_changes', json_build_object(
        'event', 'UPDATE',
        'table', 'fighter_profiles',
        'action', 'reset_all_records'
    )::text);
    
    PERFORM pg_notify('fight_records_changes', json_build_object(
        'event', 'DELETE',
        'table', 'fight_records',
        'action', 'reset_all_records'
    )::text);
    
    PERFORM pg_notify('rankings_changes', json_build_object(
        'event', 'DELETE',
        'table', 'rankings',
        'action', 'reset_all_records'
    )::text);
    
    PERFORM pg_notify('scheduled_fights_changes', json_build_object(
        'event', 'UPDATE',
        'table', 'scheduled_fights',
        'action', 'reset_all_records'
    )::text);
    
    RETURN json_build_object(
        'success', true,
        'updated_count', updated_count,
        'deleted_fight_records', deleted_fight_records,
        'tier_used', tier_value,
        'message', format('Successfully reset %s fighter records and deleted %s fight records', updated_count, deleted_fight_records)
    );
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM,
            'error_code', SQLSTATE,
            'tier_value_attempted', tier_value
        );
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION reset_all_fighters_records() TO authenticated;

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✅ reset_all_fighters_records() function updated successfully!';
    RAISE NOTICE '✅ The function now dynamically detects the correct tier value from the constraint';
    RAISE NOTICE '✅ Try resetting fighter records again - it should work now!';
END $$;

