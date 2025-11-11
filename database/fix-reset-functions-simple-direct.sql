-- Simple direct fix for reset functions
-- This script directly creates the functions with the correct tier value
-- Run this in Supabase SQL Editor

-- First, let's see what the constraint expects
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint
WHERE conrelid = 'fighter_profiles'::regclass
AND conname = 'fighter_profiles_tier_check';

-- Based on the constraint above, update the functions
-- If you see 'Amateur' (capitalized) in the constraint, the functions below use 'Amateur'
-- If you see 'amateur' (lowercase) in the constraint, change 'Amateur' to 'amateur' in both functions below

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
        RAISE EXCEPTION 'Only admins can reset fighters records.';
    END IF;
    
    DELETE FROM fight_records WHERE TRUE;
    GET DIAGNOSTICS deleted_fight_records = ROW_COUNT;
    
    UPDATE scheduled_fights
    SET status = 'Cancelled'
    WHERE status IN ('Scheduled', 'Pending');
    
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
    
    -- Reset all fighters - CHANGE 'Amateur' to 'amateur' if your constraint uses lowercase
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
        tier = 'Amateur',  -- <-- CHANGE THIS to 'amateur' if constraint uses lowercase
        updated_at = NOW()
    WHERE TRUE;
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    
    PERFORM pg_notify('fighter_profiles_changes', json_build_object(
        'event', 'UPDATE',
        'table', 'fighter_profiles',
        'action', 'reset_all_records'
    )::text);
    
    RETURN json_build_object(
        'success', true,
        'updated_count', updated_count,
        'deleted_fight_records', deleted_fight_records,
        'message', format('Successfully reset %s fighter records', updated_count)
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
        RAISE EXCEPTION 'Only admins can reset fighter records.';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM fighter_profiles WHERE user_id = fighter_user_id) THEN
        RAISE EXCEPTION 'Fighter profile not found for user ID: %', fighter_user_id;
    END IF;
    
    SELECT id, name INTO fighter_profile_id, fighter_name 
    FROM fighter_profiles 
    WHERE user_id = fighter_user_id;
    
    DELETE FROM fight_records 
    WHERE fighter_id = fighter_profile_id 
       OR fighter_id = fighter_user_id;
    GET DIAGNOSTICS deleted_fight_records = ROW_COUNT;
    
    UPDATE scheduled_fights
    SET status = 'Cancelled'
    WHERE (fighter1_id = fighter_profile_id OR fighter2_id = fighter_profile_id)
      AND status IN ('Scheduled', 'Pending');
    
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
    
    -- Reset fighter - CHANGE 'Amateur' to 'amateur' if your constraint uses lowercase
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
        tier = 'Amateur',  -- <-- CHANGE THIS to 'amateur' if constraint uses lowercase
        updated_at = NOW()
    WHERE user_id = fighter_user_id;
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    
    UPDATE fighter_profiles
    SET updated_at = NOW()
    WHERE user_id = fighter_user_id;
    
    PERFORM pg_notify('fighter_profiles_changes', json_build_object(
        'event', 'UPDATE',
        'table', 'fighter_profiles',
        'action', 'reset_fighter_records'
    )::text);
    
    RETURN json_build_object(
        'success', true,
        'updated_count', updated_count,
        'deleted_fight_records', deleted_fight_records,
        'fighter_name', fighter_name,
        'message', format('Successfully reset records for %s', fighter_name)
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

-- Grant permissions
GRANT EXECUTE ON FUNCTION reset_all_fighters_records() TO authenticated;
GRANT EXECUTE ON FUNCTION reset_fighter_records(UUID) TO authenticated;

-- Show what tier values exist in your database
SELECT 
    tier,
    COUNT(*) as count
FROM fighter_profiles
GROUP BY tier
ORDER BY tier;



