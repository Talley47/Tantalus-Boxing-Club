-- Create a SECURITY DEFINER function to create notifications
-- This bypasses RLS and allows authenticated users to create notifications for any user
-- This is the same approach used by other notification functions in the codebase

-- Drop existing function if it exists
DROP FUNCTION IF EXISTS create_notification_rpc(UUID, TEXT, TEXT, TEXT, TEXT);

-- Create the function with SECURITY DEFINER to bypass RLS
CREATE OR REPLACE FUNCTION create_notification_rpc(
    p_user_id UUID,
    p_type TEXT,
    p_title TEXT,
    p_message TEXT,
    p_action_url TEXT DEFAULT NULL
)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    type VARCHAR,
    title VARCHAR,
    message TEXT,
    is_read BOOLEAN,
    action_url TEXT,
    created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Insert the notification (bypasses RLS because of SECURITY DEFINER)
    -- Return the full notification row
    RETURN QUERY
    INSERT INTO notifications (
        user_id,
        type,
        title,
        message,
        action_url,
        is_read,
        created_at
    )
    VALUES (
        p_user_id,
        p_type::VARCHAR(20),
        p_title::VARCHAR(100),
        p_message,
        p_action_url,
        false,
        NOW()
    )
    RETURNING 
        notifications.id,
        notifications.user_id,
        notifications.type,
        notifications.title,
        notifications.message,
        notifications.is_read,
        notifications.action_url,
        notifications.created_at;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Failed to create notification: %', SQLERRM;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION create_notification_rpc(UUID, TEXT, TEXT, TEXT, TEXT) TO authenticated, anon, service_role;

-- Verify the function was created
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'create_notification_rpc' 
        AND pronamespace = 'public'::regnamespace
    ) THEN
        RAISE NOTICE '✅ Function create_notification_rpc created successfully';
        RAISE NOTICE '✅ This function bypasses RLS and can create notifications for any user';
    ELSE
        RAISE EXCEPTION '❌ Function creation failed';
    END IF;
END $$;

