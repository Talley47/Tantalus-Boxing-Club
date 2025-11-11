-- Create a SECURITY DEFINER function to reset all fighters records
-- This function bypasses RLS and can be called by admins via RPC
-- Run this in Supabase SQL Editor

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
    -- Try is_admin_user function first if it exists
    BEGIN
        SELECT is_admin_user() INTO admin_check;
    EXCEPTION
        WHEN OTHERS THEN
            admin_check := FALSE;
    END;
    
    -- If not admin via function, check profiles table
    IF NOT admin_check THEN
        SELECT EXISTS (
            SELECT 1 FROM profiles 
            WHERE id = auth.uid() 
            AND role = 'admin'
        ) INTO admin_check;
    END IF;
    
    -- Also check auth.users metadata as fallback
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
    -- Use WHERE TRUE to satisfy Supabase safety requirement for DELETE without WHERE
    DELETE FROM fight_records WHERE TRUE;
    GET DIAGNOSTICS deleted_fight_records = ROW_COUNT;
    
    -- Cancel all scheduled fights (set status to 'Cancelled') including mandatory fight requests
    UPDATE scheduled_fights
    SET status = 'Cancelled'
    WHERE status IN ('Scheduled', 'Pending');
    
    -- Clear all rankings
    DELETE FROM rankings WHERE TRUE;
    
    -- Delete all matchmaking requests (if table exists)
    BEGIN
        DELETE FROM matchmaking_requests WHERE TRUE;
    EXCEPTION
        WHEN undefined_table THEN NULL; -- Table doesn't exist, skip
    END;
    
    -- Delete all training camp invitations (if table exists)
    BEGIN
        DELETE FROM training_camp_invitations WHERE TRUE;
    EXCEPTION
        WHEN undefined_table THEN NULL; -- Table doesn't exist, skip
    END;
    
    -- Delete all callout requests (if table exists)
    BEGIN
        DELETE FROM callout_requests WHERE TRUE;
    EXCEPTION
        WHEN undefined_table THEN NULL; -- Table doesn't exist, skip
    END;
    
    -- Delete all tier history (if table exists)
    BEGIN
        DELETE FROM tier_history WHERE TRUE;
    EXCEPTION
        WHEN undefined_table THEN NULL; -- Table doesn't exist, skip
    END;
    
    -- Reset all fighters records
    -- Use the tier_value determined from the constraint
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
    WHERE TRUE; -- Update all rows
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    
    -- Trigger real-time notifications by updating updated_at again
    -- This ensures all subscribers get notified of the changes
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
    
    -- Notify about matchmaking, training camp, and callout deletions (if tables exist)
    PERFORM pg_notify('matchmaking_requests_changes', json_build_object(
        'event', 'DELETE',
        'table', 'matchmaking_requests',
        'action', 'reset_all_records'
    )::text);
    
    PERFORM pg_notify('training_camp_invitations_changes', json_build_object(
        'event', 'DELETE',
        'table', 'training_camp_invitations',
        'action', 'reset_all_records'
    )::text);
    
    PERFORM pg_notify('callout_requests_changes', json_build_object(
        'event', 'DELETE',
        'table', 'callout_requests',
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
            'error_code', SQLSTATE
        );
END;
$$;

-- Grant execute permission to authenticated users
-- (The function itself checks for admin, so this is safe)
GRANT EXECUTE ON FUNCTION reset_all_fighters_records() TO authenticated;

-- Add comment
COMMENT ON FUNCTION reset_all_fighters_records() IS 
    'Resets all fighters records (wins, losses, draws, points, etc.) to zero, deletes all fight records, cancels all scheduled fights, clears all rankings, and deletes all matchmaking/training camp/callout requests. Requires admin privileges.';

