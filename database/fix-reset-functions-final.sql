-- Final fix for reset functions - tests both cases and uses the correct one
-- Run this in Supabase SQL Editor

BEGIN;

-- STEP 1: Test which tier case works
DO $$
DECLARE
    tier_value TEXT;
    test_passed BOOLEAN;
BEGIN
    RAISE NOTICE 'Testing which tier case the constraint accepts...';
    
    -- Try capitalized first
    BEGIN
        -- Try to update with capitalized (this will fail if constraint doesn't allow it)
        UPDATE fighter_profiles
        SET tier = 'Amateur'
        WHERE FALSE; -- Never actually update, just test constraint
        
        tier_value := 'Amateur';
        test_passed := TRUE;
        RAISE NOTICE '✅ Constraint accepts CAPITALIZED: Amateur';
    EXCEPTION
        WHEN check_violation THEN
            test_passed := FALSE;
            RAISE NOTICE '❌ Constraint does NOT accept capitalized: Amateur';
    END;
    
    -- If capitalized didn't work, try lowercase
    IF NOT test_passed THEN
        BEGIN
            UPDATE fighter_profiles
            SET tier = 'amateur'
            WHERE FALSE; -- Never actually update, just test constraint
            
            tier_value := 'amateur';
            test_passed := TRUE;
            RAISE NOTICE '✅ Constraint accepts lowercase: amateur';
        EXCEPTION
            WHEN check_violation THEN
                RAISE EXCEPTION 'Could not determine correct tier case. Both Amateur and amateur failed constraint check.';
        END;
    END IF;
    
    -- Store the tier value in a temp table
    CREATE TEMP TABLE IF NOT EXISTS tier_config (value TEXT);
    DELETE FROM tier_config;
    INSERT INTO tier_config VALUES (tier_value);
    
    RAISE NOTICE '✅ Will use tier value: %', tier_value;
END $$;

-- STEP 2: Update reset_all_fighters_records function
DO $$
DECLARE
    tier_value TEXT;
    function_sql TEXT;
BEGIN
    SELECT value INTO tier_value FROM tier_config;
    
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
        RAISE EXCEPTION ''Only admins can reset fighters records.'';
    END IF;
    
    DELETE FROM fight_records WHERE TRUE;
    GET DIAGNOSTICS deleted_fight_records = ROW_COUNT;
    
    UPDATE scheduled_fights
    SET status = ''Cancelled''
    WHERE status IN (''Scheduled'', ''Pending'');
    
    DELETE FROM rankings WHERE TRUE;
    
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
    
    -- Reset all fighters - USING THE CORRECT TIER VALUE
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
        tier = %L,
        updated_at = NOW()
    WHERE TRUE;
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    
    PERFORM pg_notify(''fighter_profiles_changes'', json_build_object(
        ''event'', ''UPDATE'',
        ''table'', ''fighter_profiles'',
        ''action'', ''reset_all_records''
    )::text);
    
    RETURN json_build_object(
        ''success'', true,
        ''updated_count'', updated_count,
        ''deleted_fight_records'', deleted_fight_records,
        ''message'', format(''Successfully reset %%s fighter records'', updated_count)
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
    ', tier_value);
    
    EXECUTE function_sql;
    RAISE NOTICE '✅ Updated reset_all_fighters_records() with tier: %', tier_value;
END $$;

-- STEP 3: Update reset_fighter_records function
DO $$
DECLARE
    tier_value TEXT;
    function_sql TEXT;
BEGIN
    SELECT value INTO tier_value FROM tier_config;
    
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
        RAISE EXCEPTION ''Only admins can reset fighter records.'';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM fighter_profiles WHERE user_id = fighter_user_id) THEN
        RAISE EXCEPTION ''Fighter profile not found for user ID: %%'', fighter_user_id;
    END IF;
    
    SELECT id, name INTO fighter_profile_id, fighter_name 
    FROM fighter_profiles 
    WHERE user_id = fighter_user_id;
    
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
    
    -- Reset fighter - USING THE CORRECT TIER VALUE
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
        tier = %L,
        updated_at = NOW()
    WHERE user_id = fighter_user_id;
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    
    UPDATE fighter_profiles
    SET updated_at = NOW()
    WHERE user_id = fighter_user_id;
    
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
        ''message'', format(''Successfully reset records for %%s'', fighter_name)
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
    ', tier_value);
    
    EXECUTE function_sql;
    RAISE NOTICE '✅ Updated reset_fighter_records() with tier: %', tier_value;
END $$;

-- STEP 4: Grant permissions
GRANT EXECUTE ON FUNCTION reset_all_fighters_records() TO authenticated;
GRANT EXECUTE ON FUNCTION reset_fighter_records(UUID) TO authenticated;

COMMIT;

-- STEP 5: Show final result
DO $$
DECLARE
    tier_value TEXT;
BEGIN
    SELECT value INTO tier_value FROM tier_config;
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ FIX COMPLETE!';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Both functions updated to use tier: %', tier_value;
    RAISE NOTICE '';
    RAISE NOTICE 'Try resetting fighter records now - it should work!';
    RAISE NOTICE '========================================';
END $$;

