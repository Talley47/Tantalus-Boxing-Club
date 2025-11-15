-- ============================================
-- COMPLETE FIX FOR RESET FUNCTIONS
-- Run this entire script in Supabase SQL Editor
-- ============================================

BEGIN;

-- STEP 1: Find the correct tier value
DO $$
DECLARE
    tier_value TEXT;
    constraint_def TEXT;
BEGIN
    -- Get constraint
    SELECT pg_get_constraintdef(oid) INTO constraint_def
    FROM pg_constraint
    WHERE conrelid = 'fighter_profiles'::regclass
    AND conname = 'fighter_profiles_tier_check';
    
    RAISE NOTICE 'Constraint: %', constraint_def;
    
    -- Determine correct value
    IF constraint_def LIKE '%''Amateur''%' THEN
        tier_value := 'Amateur';
    ELSIF constraint_def LIKE '%''amateur''%' THEN
        tier_value := 'amateur';
    ELSE
        -- Test both
        BEGIN
            UPDATE fighter_profiles SET tier = 'Amateur' WHERE FALSE;
            tier_value := 'Amateur';
        EXCEPTION
            WHEN check_violation THEN
                tier_value := 'amateur';
        END;
    END IF;
    
    CREATE TEMP TABLE IF NOT EXISTS tier_val (val TEXT);
    DELETE FROM tier_val;
    INSERT INTO tier_val VALUES (tier_value);
    
    RAISE NOTICE 'Using tier value: %', tier_value;
END $$;

-- STEP 2: Update reset_all_fighters_records
DO $$
DECLARE
    tv TEXT;
BEGIN
    SELECT val INTO tv FROM tier_val;
    
    EXECUTE format('
    CREATE OR REPLACE FUNCTION reset_all_fighters_records()
    RETURNS JSON LANGUAGE plpgsql SECURITY DEFINER
    SET search_path = public AS $f$
    DECLARE
        uc INTEGER; dfr INTEGER; ac BOOLEAN;
    BEGIN
        BEGIN SELECT is_admin_user() INTO ac; EXCEPTION WHEN OTHERS THEN ac := FALSE; END;
        IF NOT ac THEN
            SELECT EXISTS(SELECT 1 FROM profiles WHERE id = auth.uid() AND role = ''admin'') INTO ac;
        END IF;
        IF NOT ac THEN
            SELECT EXISTS(SELECT 1 FROM auth.users WHERE id = auth.uid() 
                AND (COALESCE(raw_app_meta_data->>''role'','''')=''admin''
                OR COALESCE(raw_user_meta_data->>''role'','''')=''admin''
                OR email=''tantalusboxingclub@gmail.com'')) INTO ac;
        END IF;
        IF NOT ac THEN RAISE EXCEPTION ''Admin only''; END IF;
        DELETE FROM fight_records WHERE TRUE; GET DIAGNOSTICS dfr = ROW_COUNT;
        UPDATE scheduled_fights SET status=''Cancelled'' WHERE status IN (''Scheduled'',''Pending'');
        DELETE FROM rankings WHERE TRUE;
        BEGIN DELETE FROM matchmaking_requests WHERE TRUE; EXCEPTION WHEN undefined_table THEN NULL; END;
        BEGIN DELETE FROM training_camp_invitations WHERE TRUE; EXCEPTION WHEN undefined_table THEN NULL; END;
        BEGIN DELETE FROM callout_requests WHERE TRUE; EXCEPTION WHEN undefined_table THEN NULL; END;
        BEGIN DELETE FROM tier_history WHERE TRUE; EXCEPTION WHEN undefined_table THEN NULL; END;
        UPDATE fighter_profiles SET wins=0,losses=0,draws=0,knockouts=0,points=0,
            win_percentage=0.00,ko_percentage=0.00,current_streak=0,tier=%L,updated_at=NOW() WHERE TRUE;
        GET DIAGNOSTICS uc = ROW_COUNT;
        PERFORM pg_notify(''fighter_profiles_changes'',json_build_object(''event'',''UPDATE'')::text);
        RETURN json_build_object(''success'',true,''updated_count'',uc,''deleted_fight_records'',dfr);
    EXCEPTION WHEN OTHERS THEN
        RETURN json_build_object(''success'',false,''error'',SQLERRM);
    END; $f$;
    ', tv);
    
    RAISE NOTICE 'Function 1 updated';
END $$;

-- STEP 3: Update reset_fighter_records
DO $$
DECLARE
    tv TEXT;
BEGIN
    SELECT val INTO tv FROM tier_val;
    
    EXECUTE format('
    CREATE OR REPLACE FUNCTION reset_fighter_records(fighter_user_id UUID)
    RETURNS JSON LANGUAGE plpgsql SECURITY DEFINER
    SET search_path = public AS $f$
    DECLARE
        uc INTEGER; dfr INTEGER; ac BOOLEAN; fn TEXT; fpid UUID;
    BEGIN
        BEGIN SELECT is_admin_user() INTO ac; EXCEPTION WHEN OTHERS THEN ac := FALSE; END;
        IF NOT ac THEN
            SELECT EXISTS(SELECT 1 FROM profiles WHERE id = auth.uid() AND role = ''admin'') INTO ac;
        END IF;
        IF NOT ac THEN
            SELECT EXISTS(SELECT 1 FROM auth.users WHERE id = auth.uid() 
                AND (COALESCE(raw_app_meta_data->>''role'','''')=''admin''
                OR COALESCE(raw_user_meta_data->>''role'','''')=''admin''
                OR email=''tantalusboxingclub@gmail.com'')) INTO ac;
        END IF;
        IF NOT ac THEN RAISE EXCEPTION ''Admin only''; END IF;
        IF NOT EXISTS(SELECT 1 FROM fighter_profiles WHERE user_id = fighter_user_id) THEN
            RAISE EXCEPTION ''Not found'';
        END IF;
        SELECT id,name INTO fpid,fn FROM fighter_profiles WHERE user_id = fighter_user_id;
        DELETE FROM fight_records WHERE fighter_id = fpid OR fighter_id = fighter_user_id;
        GET DIAGNOSTICS dfr = ROW_COUNT;
        UPDATE scheduled_fights SET status=''Cancelled''
            WHERE (fighter1_id=fpid OR fighter2_id=fpid) AND status IN (''Scheduled'',''Pending'');
        DELETE FROM rankings WHERE fighter_id = fpid OR fighter_id = fighter_user_id;
        BEGIN DELETE FROM matchmaking_requests WHERE requester_id=fpid OR requester_id=fighter_user_id
            OR target_id=fpid OR target_id=fighter_user_id; EXCEPTION WHEN undefined_table THEN NULL; END;
        BEGIN DELETE FROM training_camp_invitations WHERE inviter_id=fpid OR inviter_id=fighter_user_id
            OR invitee_id=fpid OR invitee_id=fighter_user_id; EXCEPTION WHEN undefined_table THEN NULL; END;
        BEGIN DELETE FROM callout_requests WHERE caller_id=fpid OR caller_id=fighter_user_id
            OR target_id=fpid OR target_id=fighter_user_id; EXCEPTION WHEN undefined_table THEN NULL; END;
        BEGIN DELETE FROM tier_history WHERE fighter_id=fpid OR fighter_id=fighter_user_id;
            EXCEPTION WHEN undefined_table THEN NULL; END;
        UPDATE fighter_profiles SET wins=0,losses=0,draws=0,knockouts=0,points=0,
            win_percentage=0.00,ko_percentage=0.00,current_streak=0,tier=%L,updated_at=NOW()
            WHERE user_id = fighter_user_id;
        GET DIAGNOSTICS uc = ROW_COUNT;
        PERFORM pg_notify(''fighter_profiles_changes'',json_build_object(''event'',''UPDATE'')::text);
        RETURN json_build_object(''success'',true,''updated_count'',uc,''deleted_fight_records'',dfr,''fighter_name'',fn);
    EXCEPTION WHEN OTHERS THEN
        RETURN json_build_object(''success'',false,''error'',SQLERRM);
    END; $f$;
    ', tv);
    
    RAISE NOTICE 'Function 2 updated';
END $$;

-- STEP 4: Grant permissions
GRANT EXECUTE ON FUNCTION reset_all_fighters_records() TO authenticated;
GRANT EXECUTE ON FUNCTION reset_fighter_records(UUID) TO authenticated;

COMMIT;

-- STEP 5: Show result
DO $$
DECLARE
    tv TEXT;
BEGIN
    SELECT val INTO tv FROM tier_val;
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ FIX COMPLETE!';
    RAISE NOTICE 'Tier value used: %', tv;
    RAISE NOTICE 'Both functions updated.';
    RAISE NOTICE 'Try resetting records now!';
    RAISE NOTICE '========================================';
END $$;








