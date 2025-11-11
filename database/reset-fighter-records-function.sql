-- Create a SECURITY DEFINER function to reset a single fighter's records
-- This function bypasses RLS and can be called by admins via RPC
-- Run this in Supabase SQL Editor

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
        RAISE EXCEPTION 'Only admins can reset fighter records. Current user role could not be verified as admin.';
    END IF;
    
    -- Check if fighter profile exists
    IF NOT EXISTS (SELECT 1 FROM fighter_profiles WHERE user_id = fighter_user_id) THEN
        RAISE EXCEPTION 'Fighter profile not found for user ID: %', fighter_user_id;
    END IF;
    
    -- Get fighter name and profile ID for response
    SELECT id, name INTO fighter_profile_id, fighter_name 
    FROM fighter_profiles 
    WHERE user_id = fighter_user_id;
    
    -- Delete fight records for this fighter
    -- Handle both possible foreign key references (fighter_id can reference id or user_id)
    -- Delete where fighter_id matches either the profile id or the user_id
    DELETE FROM fight_records 
    WHERE fighter_id = fighter_profile_id 
       OR fighter_id = fighter_user_id;
    
    GET DIAGNOSTICS deleted_fight_records = ROW_COUNT;
    
    -- Cancel scheduled fights for this fighter (including mandatory fight requests)
    UPDATE scheduled_fights
    SET status = 'Cancelled'
    WHERE (fighter1_id = fighter_profile_id OR fighter2_id = fighter_profile_id)
      AND status IN ('Scheduled', 'Pending');
    
    -- Remove fighter from rankings
    DELETE FROM rankings 
    WHERE fighter_id = fighter_profile_id 
       OR fighter_id = fighter_user_id;
    
    -- Delete matchmaking requests involving this fighter (if table exists)
    BEGIN
        DELETE FROM matchmaking_requests
        WHERE requester_id = fighter_profile_id 
           OR requester_id = fighter_user_id
           OR target_id = fighter_profile_id 
           OR target_id = fighter_user_id;
    EXCEPTION
        WHEN undefined_table THEN NULL; -- Table doesn't exist, skip
    END;
    
    -- Delete training camp invitations involving this fighter (if table exists)
    BEGIN
        DELETE FROM training_camp_invitations
        WHERE inviter_id = fighter_profile_id 
           OR inviter_id = fighter_user_id
           OR invitee_id = fighter_profile_id 
           OR invitee_id = fighter_user_id;
    EXCEPTION
        WHEN undefined_table THEN NULL; -- Table doesn't exist, skip
    END;
    
    -- Delete callout requests involving this fighter (if table exists)
    BEGIN
        DELETE FROM callout_requests
        WHERE caller_id = fighter_profile_id 
           OR caller_id = fighter_user_id
           OR target_id = fighter_profile_id 
           OR target_id = fighter_user_id;
    EXCEPTION
        WHEN undefined_table THEN NULL; -- Table doesn't exist, skip
    END;
    
    -- Delete tier history for this fighter (if table exists)
    BEGIN
        DELETE FROM tier_history
        WHERE fighter_id = fighter_profile_id 
           OR fighter_id = fighter_user_id;
    EXCEPTION
        WHEN undefined_table THEN NULL; -- Table doesn't exist, skip
    END;
    
    -- Reset fighter records
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
        tier = 'Amateur',
        updated_at = NOW()
    WHERE user_id = fighter_user_id;
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    
    -- Force a second update to ensure real-time notifications are triggered
    -- This ensures all subscribers receive the update event
    UPDATE fighter_profiles
    SET updated_at = NOW()
    WHERE user_id = fighter_user_id;
    
    -- Trigger real-time notifications via pg_notify (for custom listeners)
    -- Note: The actual database changes above will trigger postgres_changes events automatically
    PERFORM pg_notify('fighter_profiles_changes', json_build_object(
        'event', 'UPDATE',
        'table', 'fighter_profiles',
        'new', json_build_object('user_id', fighter_user_id, 'id', fighter_profile_id),
        'old', json_build_object('user_id', fighter_user_id, 'id', fighter_profile_id),
        'action', 'reset_fighter_records'
    )::text);
    
    PERFORM pg_notify('fight_records_changes', json_build_object(
        'event', 'DELETE',
        'table', 'fight_records',
        'action', 'reset_fighter_records',
        'fighter_user_id', fighter_user_id,
        'fighter_profile_id', fighter_profile_id
    )::text);
    
    PERFORM pg_notify('rankings_changes', json_build_object(
        'event', 'DELETE',
        'table', 'rankings',
        'action', 'reset_fighter_records',
        'fighter_user_id', fighter_user_id,
        'fighter_profile_id', fighter_profile_id
    )::text);
    
    PERFORM pg_notify('scheduled_fights_changes', json_build_object(
        'event', 'UPDATE',
        'table', 'scheduled_fights',
        'action', 'reset_fighter_records',
        'fighter_user_id', fighter_user_id,
        'fighter_profile_id', fighter_profile_id
    )::text);
    
    -- Notify about matchmaking, training camp, and callout deletions (if tables exist)
    PERFORM pg_notify('matchmaking_requests_changes', json_build_object(
        'event', 'DELETE',
        'table', 'matchmaking_requests',
        'action', 'reset_fighter_records',
        'fighter_user_id', fighter_user_id,
        'fighter_profile_id', fighter_profile_id
    )::text);
    
    PERFORM pg_notify('training_camp_invitations_changes', json_build_object(
        'event', 'DELETE',
        'table', 'training_camp_invitations',
        'action', 'reset_fighter_records',
        'fighter_user_id', fighter_user_id,
        'fighter_profile_id', fighter_profile_id
    )::text);
    
    PERFORM pg_notify('callout_requests_changes', json_build_object(
        'event', 'DELETE',
        'table', 'callout_requests',
        'action', 'reset_fighter_records',
        'fighter_user_id', fighter_user_id,
        'fighter_profile_id', fighter_profile_id
    )::text);
    
    -- Broadcast a general reset notification that all systems can listen to
    PERFORM pg_notify('fighter_reset_broadcast', json_build_object(
        'action', 'reset_fighter_records',
        'fighter_user_id', fighter_user_id,
        'fighter_profile_id', fighter_profile_id,
        'fighter_name', fighter_name,
        'timestamp', EXTRACT(EPOCH FROM NOW())
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

-- Grant execute permission to authenticated users
-- (The function itself checks for admin, so this is safe)
GRANT EXECUTE ON FUNCTION reset_fighter_records(UUID) TO authenticated;

-- Add comment
COMMENT ON FUNCTION reset_fighter_records(UUID) IS 
    'Resets a single fighter''s records (wins, losses, draws, points, etc.) to zero, deletes their fight records, cancels scheduled fights, removes from rankings, and clears matchmaking/training camp/callout requests. Requires admin privileges.';

