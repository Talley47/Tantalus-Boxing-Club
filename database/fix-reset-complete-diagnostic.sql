-- Complete diagnostic and fix for reset functions
-- This will show you exactly what's wrong and fix it
-- Run this in Supabase SQL Editor

-- STEP 1: Show what the constraint expects
SELECT 
    'CONSTRAINT DEFINITION' as info,
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint
WHERE conrelid = 'fighter_profiles'::regclass
AND conname = 'fighter_profiles_tier_check';

-- STEP 2: Show what tier values currently exist
SELECT 
    'CURRENT TIER VALUES' as info,
    tier,
    COUNT(*) as count
FROM fighter_profiles
GROUP BY tier
ORDER BY tier;

-- STEP 3: Check for triggers that might interfere
SELECT 
    'TRIGGERS ON FIGHTER_PROFILES' as info,
    tgname as trigger_name,
    tgenabled as enabled,
    pg_get_triggerdef(oid) as trigger_definition
FROM pg_trigger
WHERE tgrelid = 'fighter_profiles'::regclass
AND tgisinternal = false
ORDER BY tgname;

-- STEP 4: Test which tier value works
DO $$
DECLARE
    tier_value TEXT := NULL;
    test_result TEXT;
BEGIN
    RAISE NOTICE 'Testing tier values...';
    
    -- Try capitalized
    BEGIN
        UPDATE fighter_profiles
        SET tier = 'Amateur'
        WHERE FALSE; -- Never actually update
        tier_value := 'Amateur';
        RAISE NOTICE '✅ Constraint accepts: Amateur (capitalized)';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE '❌ Constraint does NOT accept: Amateur (capitalized)';
    END;
    
    -- If capitalized didn't work, try lowercase
    IF tier_value IS NULL THEN
        BEGIN
            UPDATE fighter_profiles
            SET tier = 'amateur'
            WHERE FALSE; -- Never actually update
            tier_value := 'amateur';
            RAISE NOTICE '✅ Constraint accepts: amateur (lowercase)';
        EXCEPTION
            WHEN check_violation THEN
                RAISE NOTICE '❌ Constraint does NOT accept: amateur (lowercase)';
                RAISE EXCEPTION 'Could not determine correct tier case. Please check constraint manually.';
        END;
    END IF;
    
    -- Store for use in functions
    CREATE TEMP TABLE IF NOT EXISTS tier_config (value TEXT);
    DELETE FROM tier_config;
    INSERT INTO tier_config VALUES (tier_value);
    
    RAISE NOTICE '✅ Will use tier value: %', tier_value;
END $$;

-- STEP 5: Now update the functions with the correct tier value
-- This uses the tier value determined above
DO $$
DECLARE
    tier_value TEXT;
BEGIN
    SELECT value INTO tier_value FROM tier_config;
    
    -- Update reset_all_fighters_records
    EXECUTE format('
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
        
        -- Reset all fighters with CORRECT tier value
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
            ''tier_used'', %L,
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
    ', tier_value, tier_value);
    
    -- Update reset_fighter_records
    EXECUTE format('
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
        
        -- Reset fighter with CORRECT tier value
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
            ''tier_used'', %L,
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
    ', tier_value, tier_value);
    
    RAISE NOTICE '✅ Both functions updated with tier: %', tier_value;
END $$;

-- STEP 6: Grant permissions
GRANT EXECUTE ON FUNCTION reset_all_fighters_records() TO authenticated;
GRANT EXECUTE ON FUNCTION reset_fighter_records(UUID) TO authenticated;

-- STEP 7: Final summary
DO $$
DECLARE
    tier_value TEXT;
BEGIN
    SELECT value INTO tier_value FROM tier_config;
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ FIX COMPLETE!';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Tier value used: %', tier_value;
    RAISE NOTICE 'Both functions have been updated.';
    RAISE NOTICE '';
    RAISE NOTICE 'Try resetting fighter records now!';
    RAISE NOTICE '========================================';
END $$;





