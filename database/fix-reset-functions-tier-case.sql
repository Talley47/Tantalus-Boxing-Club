-- Fix tier case in reset functions
-- This ensures both RPC functions use the correct capitalized tier value
-- Run this in Supabase SQL Editor

-- First, check what the constraint actually expects
DO $$
DECLARE
    constraint_def TEXT;
BEGIN
    SELECT pg_get_constraintdef(oid)
    INTO constraint_def
    FROM pg_constraint
    WHERE conrelid = 'fighter_profiles'::regclass
    AND conname = 'fighter_profiles_tier_check'
    AND contype = 'c';
    
    IF constraint_def IS NOT NULL THEN
        RAISE NOTICE 'Current constraint definition: %', constraint_def;
    ELSE
        RAISE WARNING 'Constraint fighter_profiles_tier_check not found!';
    END IF;
END $$;

-- Update reset_all_fighters_records function
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
    
    -- First, delete all fight records
    DELETE FROM fight_records WHERE TRUE;
    GET DIAGNOSTICS deleted_fight_records = ROW_COUNT;
    
    -- Cancel all scheduled fights
    UPDATE scheduled_fights
    SET status = 'Cancelled'
    WHERE status IN ('Scheduled', 'Pending');
    
    -- Clear all rankings
    DELETE FROM rankings WHERE TRUE;
    
    -- Delete all matchmaking requests (if table exists)
    BEGIN
        DELETE FROM matchmaking_requests WHERE TRUE;
    EXCEPTION
        WHEN undefined_table THEN NULL;
    END;
    
    -- Delete all training camp invitations (if table exists)
    BEGIN
        DELETE FROM training_camp_invitations WHERE TRUE;
    EXCEPTION
        WHEN undefined_table THEN NULL;
    END;
    
    -- Delete all callout requests (if table exists)
    BEGIN
        DELETE FROM callout_requests WHERE TRUE;
    EXCEPTION
        WHEN undefined_table THEN NULL;
    END;
    
    -- Delete all tier history (if table exists)
    BEGIN
        DELETE FROM tier_history WHERE TRUE;
    EXCEPTION
        WHEN undefined_table THEN NULL;
    END;
    
    -- Reset all fighters records - USE CAPITALIZED 'Amateur' to match constraint
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
        tier = 'Amateur',  -- FIXED: Changed from 'amateur' to 'Amateur'
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
        'message', format('Successfully reset %s fighter records and deleted %s fight records', updated_count, deleted_fight_records)
    );
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM,
            'error_code', SQLSTATE
        );
END;
$$;

-- Update reset_fighter_records function
CREATE OR REPLACE FUNCTION reset_fighter_records(fighter_user_id UUID)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
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
        RAISE EXCEPTION 'Only admins can reset fighter records. Current user role could not be verified as admin.';
    END IF;
    
    -- Check if fighter profile exists
    IF NOT EXISTS (SELECT 1 FROM fighter_profiles WHERE user_id = fighter_user_id) THEN
        RAISE EXCEPTION 'Fighter profile not found for user ID: %', fighter_user_id;
    END IF;
    
    -- Get fighter name and profile ID
    SELECT id, name INTO fighter_profile_id, fighter_name 
    FROM fighter_profiles 
    WHERE user_id = fighter_user_id;
    
    -- Delete fight records for this fighter
    DELETE FROM fight_records 
    WHERE fighter_id = fighter_profile_id 
       OR fighter_id = fighter_user_id;
    
    GET DIAGNOSTICS deleted_fight_records = ROW_COUNT;
    
    -- Cancel scheduled fights for this fighter
    UPDATE scheduled_fights
    SET status = 'Cancelled'
    WHERE (fighter1_id = fighter_profile_id OR fighter2_id = fighter_profile_id)
      AND status IN ('Scheduled', 'Pending');
    
    -- Remove fighter from rankings
    DELETE FROM rankings 
    WHERE fighter_id = fighter_profile_id 
       OR fighter_id = fighter_user_id;
    
    -- Delete matchmaking requests (if table exists)
    BEGIN
        DELETE FROM matchmaking_requests
        WHERE requester_id = fighter_profile_id 
           OR requester_id = fighter_user_id
           OR target_id = fighter_profile_id 
           OR target_id = fighter_user_id;
    EXCEPTION
        WHEN undefined_table THEN NULL;
    END;
    
    -- Delete training camp invitations (if table exists)
    BEGIN
        DELETE FROM training_camp_invitations
        WHERE inviter_id = fighter_profile_id 
           OR inviter_id = fighter_user_id
           OR invitee_id = fighter_profile_id 
           OR invitee_id = fighter_user_id;
    EXCEPTION
        WHEN undefined_table THEN NULL;
    END;
    
    -- Delete callout requests (if table exists)
    BEGIN
        DELETE FROM callout_requests
        WHERE caller_id = fighter_profile_id 
           OR caller_id = fighter_user_id
           OR target_id = fighter_profile_id 
           OR target_id = fighter_user_id;
    EXCEPTION
        WHEN undefined_table THEN NULL;
    END;
    
    -- Delete tier history (if table exists)
    BEGIN
        DELETE FROM tier_history
        WHERE fighter_id = fighter_profile_id 
           OR fighter_id = fighter_user_id;
    EXCEPTION
        WHEN undefined_table THEN NULL;
    END;
    
    -- Reset fighter records - USE CAPITALIZED 'Amateur' to match constraint
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
        tier = 'Amateur',  -- FIXED: Changed from 'amateur' to 'Amateur'
        updated_at = NOW()
    WHERE user_id = fighter_user_id;
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    
    -- Force a second update to ensure real-time notifications
    UPDATE fighter_profiles
    SET updated_at = NOW()
    WHERE user_id = fighter_user_id;
    
    -- Trigger real-time notifications
    PERFORM pg_notify('fighter_profiles_changes', json_build_object(
        'event', 'UPDATE',
        'table', 'fighter_profiles',
        'new', json_build_object('user_id', fighter_user_id, 'id', fighter_profile_id),
        'old', json_build_object('user_id', fighter_user_id, 'id', fighter_profile_id),
        'action', 'reset_fighter_records'
    )::text);
    
    RETURN json_build_object(
        'success', true,
        'updated_count', updated_count,
        'deleted_fight_records', deleted_fight_records,
        'fighter_name', fighter_name,
        'message', format('Successfully reset records for %s and deleted %s fight records', fighter_name, deleted_fight_records)
    );
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM,
            'error_code', SQLSTATE
        );
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION reset_all_fighters_records() TO authenticated;
GRANT EXECUTE ON FUNCTION reset_fighter_records(UUID) TO authenticated;

-- Verify the functions were updated
DO $$
BEGIN
    RAISE NOTICE '✅ Both reset functions have been updated to use ''Amateur'' (capitalized)';
    RAISE NOTICE '✅ Functions are ready to use. Try resetting fighter records again.';
END $$;



