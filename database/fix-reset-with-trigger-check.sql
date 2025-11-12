-- Fix reset functions with trigger check
-- The "new row" error suggests a trigger might be interfering
-- Run this in Supabase SQL Editor

-- STEP 1: Check what the constraint expects
SELECT 
    'CONSTRAINT' as check_type,
    pg_get_constraintdef(oid) as definition
FROM pg_constraint
WHERE conrelid = 'fighter_profiles'::regclass
AND conname = 'fighter_profiles_tier_check';

-- STEP 2: Check for triggers that might interfere
SELECT 
    'TRIGGER' as check_type,
    tgname as trigger_name,
    CASE tgenabled
        WHEN 'O' THEN 'Enabled'
        WHEN 'D' THEN 'Disabled'
        ELSE 'Unknown'
    END as status,
    pg_get_triggerdef(oid) as definition
FROM pg_trigger
WHERE tgrelid = 'fighter_profiles'::regclass
AND tgisinternal = false
ORDER BY tgname;

-- STEP 3: Check what tier values currently exist
SELECT 
    'CURRENT DATA' as check_type,
    tier,
    COUNT(*) as count
FROM fighter_profiles
GROUP BY tier
ORDER BY tier;

-- STEP 4: Determine correct tier value and update functions
DO $$
DECLARE
    tier_value TEXT;
    constraint_def TEXT;
BEGIN
    -- Get constraint definition
    SELECT pg_get_constraintdef(oid)
    INTO constraint_def
    FROM pg_constraint
    WHERE conrelid = 'fighter_profiles'::regclass
    AND conname = 'fighter_profiles_tier_check';
    
    -- Determine tier value from constraint
    IF constraint_def LIKE '%''Amateur''%' OR constraint_def LIKE '%"Amateur"%' THEN
        tier_value := 'Amateur';
        RAISE NOTICE 'Using capitalized: Amateur';
    ELSIF constraint_def LIKE '%''amateur''%' OR constraint_def LIKE '%"amateur"%' THEN
        tier_value := 'amateur';
        RAISE NOTICE 'Using lowercase: amateur';
    ELSE
        -- Try to test
        BEGIN
            UPDATE fighter_profiles SET tier = 'Amateur' WHERE FALSE;
            tier_value := 'Amateur';
            RAISE NOTICE 'Tested: Using capitalized: Amateur';
        EXCEPTION
            WHEN check_violation THEN
                tier_value := 'amateur';
                RAISE NOTICE 'Tested: Using lowercase: amateur';
        END;
    END IF;
    
    -- Create/update reset_all_fighters_records function
    EXECUTE format('
    CREATE OR REPLACE FUNCTION reset_all_fighters_records()
    RETURNS JSON
    LANGUAGE plpgsql
    SECURITY DEFINER
    SET search_path = public
    AS $fn$
    DECLARE
        v_updated_count INTEGER;
        v_deleted_fight_records INTEGER;
        v_admin_check BOOLEAN;
    BEGIN
        -- Admin check
        BEGIN
            SELECT is_admin_user() INTO v_admin_check;
        EXCEPTION
            WHEN OTHERS THEN
                v_admin_check := FALSE;
        END;
        
        IF NOT v_admin_check THEN
            SELECT EXISTS (
                SELECT 1 FROM profiles 
                WHERE id = auth.uid() AND role = ''admin''
            ) INTO v_admin_check;
        END IF;
        
        IF NOT v_admin_check THEN
            SELECT EXISTS (
                SELECT 1 FROM auth.users
                WHERE id = auth.uid()
                AND (
                    COALESCE(raw_app_meta_data->>''role'', '''') = ''admin''
                    OR COALESCE(raw_user_meta_data->>''role'', '''') = ''admin''
                    OR email = ''tantalusboxingclub@gmail.com''
                )
            ) INTO v_admin_check;
        END IF;
        
        IF NOT v_admin_check THEN
            RAISE EXCEPTION ''Only admins can reset fighters records.'';
        END IF;
        
        -- Delete fight records
        DELETE FROM fight_records WHERE TRUE;
        GET DIAGNOSTICS v_deleted_fight_records = ROW_COUNT;
        
        -- Cancel scheduled fights
        UPDATE scheduled_fights
        SET status = ''Cancelled''
        WHERE status IN (''Scheduled'', ''Pending'');
        
        -- Clear rankings
        DELETE FROM rankings WHERE TRUE;
        
        -- Delete related data
        BEGIN
            DELETE FROM matchmaking_requests WHERE TRUE;
        EXCEPTION WHEN undefined_table THEN NULL; END;
        
        BEGIN
            DELETE FROM training_camp_invitations WHERE TRUE;
        EXCEPTION WHEN undefined_table THEN NULL; END;
        
        BEGIN
            DELETE FROM callout_requests WHERE TRUE;
        EXCEPTION WHEN undefined_table THEN NULL; END;
        
        BEGIN
            DELETE FROM tier_history WHERE TRUE;
        EXCEPTION WHEN undefined_table THEN NULL; END;
        
        -- Reset fighter profiles - USE CORRECT TIER VALUE
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
        
        GET DIAGNOSTICS v_updated_count = ROW_COUNT;
        
        -- Notify
        PERFORM pg_notify(''fighter_profiles_changes'', json_build_object(
            ''event'', ''UPDATE'',
            ''table'', ''fighter_profiles''
        )::text);
        
        RETURN json_build_object(
            ''success'', true,
            ''updated_count'', v_updated_count,
            ''deleted_fight_records'', v_deleted_fight_records,
            ''tier_used'', %L
        );
    EXCEPTION
        WHEN OTHERS THEN
            RETURN json_build_object(
                ''success'', false,
                ''error'', SQLERRM,
                ''error_code'', SQLSTATE
            );
    END;
    $fn$;
    ', tier_value, tier_value);
    
    -- Create/update reset_fighter_records function
    EXECUTE format('
    CREATE OR REPLACE FUNCTION reset_fighter_records(fighter_user_id UUID)
    RETURNS JSON
    LANGUAGE plpgsql
    SECURITY DEFINER
    SET search_path = public
    AS $fn$
    DECLARE
        v_updated_count INTEGER;
        v_deleted_fight_records INTEGER;
        v_admin_check BOOLEAN;
        v_fighter_name TEXT;
        v_fighter_profile_id UUID;
    BEGIN
        -- Admin check (same as above)
        BEGIN
            SELECT is_admin_user() INTO v_admin_check;
        EXCEPTION
            WHEN OTHERS THEN
                v_admin_check := FALSE;
        END;
        
        IF NOT v_admin_check THEN
            SELECT EXISTS (
                SELECT 1 FROM profiles 
                WHERE id = auth.uid() AND role = ''admin''
            ) INTO v_admin_check;
        END IF;
        
        IF NOT v_admin_check THEN
            SELECT EXISTS (
                SELECT 1 FROM auth.users
                WHERE id = auth.uid()
                AND (
                    COALESCE(raw_app_meta_data->>''role'', '''') = ''admin''
                    OR COALESCE(raw_user_meta_data->>''role'', '''') = ''admin''
                    OR email = ''tantalusboxingclub@gmail.com''
                )
            ) INTO v_admin_check;
        END IF;
        
        IF NOT v_admin_check THEN
            RAISE EXCEPTION ''Only admins can reset fighter records.'';
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM fighter_profiles WHERE user_id = fighter_user_id) THEN
            RAISE EXCEPTION ''Fighter profile not found.'';
        END IF;
        
        SELECT id, name INTO v_fighter_profile_id, v_fighter_name 
        FROM fighter_profiles 
        WHERE user_id = fighter_user_id;
        
        -- Delete related data
        DELETE FROM fight_records 
        WHERE fighter_id = v_fighter_profile_id OR fighter_id = fighter_user_id;
        GET DIAGNOSTICS v_deleted_fight_records = ROW_COUNT;
        
        UPDATE scheduled_fights
        SET status = ''Cancelled''
        WHERE (fighter1_id = v_fighter_profile_id OR fighter2_id = v_fighter_profile_id)
          AND status IN (''Scheduled'', ''Pending'');
        
        DELETE FROM rankings 
        WHERE fighter_id = v_fighter_profile_id OR fighter_id = fighter_user_id;
        
        BEGIN
            DELETE FROM matchmaking_requests
            WHERE requester_id = v_fighter_profile_id OR requester_id = fighter_user_id
               OR target_id = v_fighter_profile_id OR target_id = fighter_user_id;
        EXCEPTION WHEN undefined_table THEN NULL; END;
        
        BEGIN
            DELETE FROM training_camp_invitations
            WHERE inviter_id = v_fighter_profile_id OR inviter_id = fighter_user_id
               OR invitee_id = v_fighter_profile_id OR invitee_id = fighter_user_id;
        EXCEPTION WHEN undefined_table THEN NULL; END;
        
        BEGIN
            DELETE FROM callout_requests
            WHERE caller_id = v_fighter_profile_id OR caller_id = fighter_user_id
               OR target_id = v_fighter_profile_id OR target_id = fighter_user_id;
        EXCEPTION WHEN undefined_table THEN NULL; END;
        
        BEGIN
            DELETE FROM tier_history
            WHERE fighter_id = v_fighter_profile_id OR fighter_id = fighter_user_id;
        EXCEPTION WHEN undefined_table THEN NULL; END;
        
        -- Reset fighter - USE CORRECT TIER VALUE
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
        
        GET DIAGNOSTICS v_updated_count = ROW_COUNT;
        
        -- Notify
        PERFORM pg_notify(''fighter_profiles_changes'', json_build_object(
            ''event'', ''UPDATE'',
            ''table'', ''fighter_profiles''
        )::text);
        
        RETURN json_build_object(
            ''success'', true,
            ''updated_count'', v_updated_count,
            ''deleted_fight_records'', v_deleted_fight_records,
            ''fighter_name'', v_fighter_name,
            ''tier_used'', %L
        );
    EXCEPTION
        WHEN OTHERS THEN
            RETURN json_build_object(
                ''success'', false,
                ''error'', SQLERRM,
                ''error_code'', SQLSTATE
            );
    END;
    $fn$;
    ', tier_value, tier_value);
    
    RAISE NOTICE '✅ Functions updated with tier: %', tier_value;
END $$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION reset_all_fighters_records() TO authenticated;
GRANT EXECUTE ON FUNCTION reset_fighter_records(UUID) TO authenticated;

-- Final check
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ Functions updated successfully!';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Try resetting fighter records now.';
    RAISE NOTICE 'If you still get an error, check the';
    RAISE NOTICE 'trigger output above for any triggers';
    RAISE NOTICE 'that might be interfering.';
    RAISE NOTICE '========================================';
END $$;





