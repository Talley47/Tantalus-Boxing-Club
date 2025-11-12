-- Smart fix for reset functions - automatically detects constraint case
-- This script checks what the constraint expects and updates functions accordingly
-- Run this in Supabase SQL Editor

BEGIN;

-- STEP 1: Determine what case the constraint expects
DO $$
DECLARE
    constraint_def TEXT;
    tier_value TEXT;
    test_result BOOLEAN;
BEGIN
    -- Get constraint definition
    SELECT pg_get_constraintdef(oid)
    INTO constraint_def
    FROM pg_constraint
    WHERE conrelid = 'fighter_profiles'::regclass
    AND conname = 'fighter_profiles_tier_check'
    AND contype = 'c';
    
    IF constraint_def IS NULL THEN
        RAISE EXCEPTION 'Constraint fighter_profiles_tier_check not found!';
    END IF;
    
    RAISE NOTICE 'Constraint definition: %', constraint_def;
    
    -- Determine correct tier value by checking constraint
    IF constraint_def LIKE '%''Amateur''%' OR constraint_def LIKE '%"Amateur"%' THEN
        tier_value := 'Amateur';
        RAISE NOTICE '✅ Constraint expects CAPITALIZED: Amateur';
    ELSIF constraint_def LIKE '%''amateur''%' OR constraint_def LIKE '%"amateur"%' THEN
        tier_value := 'amateur';
        RAISE NOTICE '✅ Constraint expects lowercase: amateur';
    ELSE
        -- Try to test both
        BEGIN
            -- Test capitalized
            UPDATE fighter_profiles
            SET tier = 'Amateur'
            WHERE FALSE; -- Never actually update, just test constraint
            tier_value := 'Amateur';
            RAISE NOTICE '✅ Testing shows CAPITALIZED works: Amateur';
        EXCEPTION
            WHEN check_violation THEN
                -- Try lowercase
                BEGIN
                    UPDATE fighter_profiles
                    SET tier = 'amateur'
                    WHERE FALSE; -- Never actually update, just test constraint
                    tier_value := 'amateur';
                    RAISE NOTICE '✅ Testing shows lowercase works: amateur';
                EXCEPTION
                    WHEN OTHERS THEN
                        RAISE EXCEPTION 'Could not determine correct tier case. Constraint: %', constraint_def;
                END;
        END;
    END IF;
    
    -- Store the tier value in a temporary table for use in functions
    CREATE TEMP TABLE IF NOT EXISTS tier_config (value TEXT);
    DELETE FROM tier_config;
    INSERT INTO tier_config VALUES (tier_value);
    
    RAISE NOTICE '✅ Using tier value: %', tier_value;
END $$;

-- STEP 2: Create updated reset_all_fighters_records function
-- This will use the tier value determined above
DO $$
DECLARE
    tier_value TEXT;
    function_sql TEXT;
BEGIN
    -- Get the tier value from temp table
    SELECT value INTO tier_value FROM tier_config;
    
    -- Build the function SQL with the correct tier value
    function_sql := format('
CREATE OR REPLACE FUNCTION reset_all_fighters_records()
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $func$
DECLARE
    updated_count INTEGER;
    deleted_fight_records INTEGER;
    admin_check BOOLEAN;
BEGIN
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
            AND role = ''admin''
        ) INTO admin_check;
    END IF;
    
    IF NOT admin_check THEN
        SELECT EXISTS (
            SELECT 1 FROM auth.users
            WHERE id = auth.uid()
            AND (
                COALESCE(raw_app_meta_data->>''role'', '''') = ''admin''
                OR COALESCE(raw_user_meta_data->>''role'', '''') = ''admin''
                OR email = ''tantalusboxingclub@gmail.com''
            )
        ) INTO admin_check;
    END IF;
    
    IF NOT admin_check THEN
        RAISE EXCEPTION ''Only admins can reset fighters records. Current user role could not be verified as admin.'';
    END IF;
    
    -- Delete all fight records
    DELETE FROM fight_records WHERE TRUE;
    GET DIAGNOSTICS deleted_fight_records = ROW_COUNT;
    
    -- Cancel all scheduled fights
    UPDATE scheduled_fights
    SET status = ''Cancelled''
    WHERE status IN (''Scheduled'', ''Pending'');
    
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
    
    -- Reset all fighters records - USING CORRECT TIER VALUE
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
        tier = %L,  -- This will be the correct tier value
        updated_at = NOW()
    WHERE TRUE;
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    
    -- Trigger real-time notifications
    PERFORM pg_notify(''fighter_profiles_changes'', json_build_object(
        ''event'', ''UPDATE'',
        ''table'', ''fighter_profiles'',
        ''action'', ''reset_all_records''
    )::text);
    
    RETURN json_build_object(
        ''success'', true,
        ''updated_count'', updated_count,
        ''deleted_fight_records'', deleted_fight_records,
        ''tier_used'', %L,
        ''message'', format(''Successfully reset %%s fighter records and deleted %%s fight records'', updated_count, deleted_fight_records)
    );
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            ''success'', false,
            ''error'', SQLERRM,
            ''error_code'', SQLSTATE
        );
END;
$func$;
    ', tier_value, tier_value);
    
    EXECUTE function_sql;
    RAISE NOTICE '✅ Created reset_all_fighters_records() with tier: %', tier_value;
END $$;

-- STEP 3: Create updated reset_fighter_records function
DO $$
DECLARE
    tier_value TEXT;
    function_sql TEXT;
BEGIN
    -- Get the tier value from temp table
    SELECT value INTO tier_value FROM tier_config;
    
    -- Build the function SQL with the correct tier value
    function_sql := format('
CREATE OR REPLACE FUNCTION reset_fighter_records(fighter_user_id UUID)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $func$
DECLARE
    updated_count INTEGER;
    deleted_fight_records INTEGER;
    admin_check BOOLEAN;
    fighter_name TEXT;
    fighter_profile_id UUID;
BEGIN
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
            AND role = ''admin''
        ) INTO admin_check;
    END IF;
    
    IF NOT admin_check THEN
        SELECT EXISTS (
            SELECT 1 FROM auth.users
            WHERE id = auth.uid()
            AND (
                COALESCE(raw_app_meta_data->>''role'', '''') = ''admin''
                OR COALESCE(raw_user_meta_data->>''role'', '''') = ''admin''
                OR email = ''tantalusboxingclub@gmail.com''
            )
        ) INTO admin_check;
    END IF;
    
    IF NOT admin_check THEN
        RAISE EXCEPTION ''Only admins can reset fighter records. Current user role could not be verified as admin.'';
    END IF;
    
    -- Check if fighter profile exists
    IF NOT EXISTS (SELECT 1 FROM fighter_profiles WHERE user_id = fighter_user_id) THEN
        RAISE EXCEPTION ''Fighter profile not found for user ID: %%'', fighter_user_id;
    END IF;
    
    -- Get fighter name and profile ID
    SELECT id, name INTO fighter_profile_id, fighter_name 
    FROM fighter_profiles 
    WHERE user_id = fighter_user_id;
    
    -- Delete related data
    DELETE FROM fight_records 
    WHERE fighter_id = fighter_profile_id 
       OR fighter_id = fighter_user_id;
    GET DIAGNOSTICS deleted_fight_records = ROW_COUNT;
    
    UPDATE scheduled_fights
    SET status = ''Cancelled''
    WHERE (fighter1_id = fighter_profile_id OR fighter2_id = fighter_profile_id)
      AND status IN (''Scheduled'', ''Pending'');
    
    DELETE FROM rankings 
    WHERE fighter_id = fighter_profile_id 
       OR fighter_id = fighter_user_id;
    
    BEGIN
        DELETE FROM matchmaking_requests
        WHERE requester_id = fighter_profile_id 
           OR requester_id = fighter_user_id
           OR target_id = fighter_profile_id 
           OR target_id = fighter_user_id;
    EXCEPTION
        WHEN undefined_table THEN NULL;
    END;
    
    BEGIN
        DELETE FROM training_camp_invitations
        WHERE inviter_id = fighter_profile_id 
           OR inviter_id = fighter_user_id
           OR invitee_id = fighter_profile_id 
           OR invitee_id = fighter_user_id;
    EXCEPTION
        WHEN undefined_table THEN NULL;
    END;
    
    BEGIN
        DELETE FROM callout_requests
        WHERE caller_id = fighter_profile_id 
           OR caller_id = fighter_user_id
           OR target_id = fighter_profile_id 
           OR target_id = fighter_user_id;
    EXCEPTION
        WHEN undefined_table THEN NULL;
    END;
    
    BEGIN
        DELETE FROM tier_history
        WHERE fighter_id = fighter_profile_id 
           OR fighter_id = fighter_user_id;
    EXCEPTION
        WHEN undefined_table THEN NULL;
    END;
    
    -- Reset fighter records - USING CORRECT TIER VALUE
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
        tier = %L,  -- This will be the correct tier value
        updated_at = NOW()
    WHERE user_id = fighter_user_id;
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    
    -- Force a second update to ensure real-time notifications
    UPDATE fighter_profiles
    SET updated_at = NOW()
    WHERE user_id = fighter_user_id;
    
    -- Trigger real-time notifications
    PERFORM pg_notify(''fighter_profiles_changes'', json_build_object(
        ''event'', ''UPDATE'',
        ''table'', ''fighter_profiles'',
        ''action'', ''reset_fighter_records''
    )::text);
    
    RETURN json_build_object(
        ''success'', true,
        ''updated_count'', updated_count,
        ''deleted_fight_records'', deleted_fight_records,
        ''fighter_name'', fighter_name,
        ''tier_used'', %L,
        ''message'', format(''Successfully reset records for %%s and deleted %%s fight records'', fighter_name, deleted_fight_records)
    );
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            ''success'', false,
            ''error'', SQLERRM,
            ''error_code'', SQLSTATE
        );
END;
$func$;
    ', tier_value, tier_value);
    
    EXECUTE function_sql;
    RAISE NOTICE '✅ Created reset_fighter_records() with tier: %', tier_value;
END $$;

-- STEP 4: Grant permissions
GRANT EXECUTE ON FUNCTION reset_all_fighters_records() TO authenticated;
GRANT EXECUTE ON FUNCTION reset_fighter_records(UUID) TO authenticated;

COMMIT;

-- STEP 5: Final verification
DO $$
DECLARE
    tier_value TEXT;
BEGIN
    SELECT value INTO tier_value FROM tier_config;
    RAISE NOTICE '✅ Both reset functions have been updated';
    RAISE NOTICE '✅ Functions use tier value: %', tier_value;
    RAISE NOTICE '✅ Try resetting fighter records again - it should work now!';
END $$;





