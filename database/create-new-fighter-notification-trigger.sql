-- Create trigger to notify all fighters when a new fighter joins
-- This creates a "New Fighter Joined" notification for all existing fighters

-- First, drop ALL existing versions of the function to avoid conflicts
-- This handles function overloading (multiple functions with same name, different signatures)
DO $$
DECLARE
    func_record RECORD;
BEGIN
    -- Find and drop all versions of create_notification_for_all_fighters
    FOR func_record IN 
        SELECT 
            p.proname as func_name,
            pg_get_function_identity_arguments(p.oid) as func_args
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'public'
          AND p.proname = 'create_notification_for_all_fighters'
    LOOP
        EXECUTE format('DROP FUNCTION IF EXISTS %I.%I(%s) CASCADE', 
            'public', 
            func_record.func_name, 
            func_record.func_args);
    END LOOP;
END $$;

-- Create a helper function to create notifications for all fighters
-- This function is used by multiple triggers (news, events, new fighters)
CREATE OR REPLACE FUNCTION create_notification_for_all_fighters(
    notification_type TEXT,
    notification_title TEXT,
    notification_message TEXT,
    action_url TEXT DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    fighter_record RECORD;
    batch_size INTEGER := 100;
    notification_batch JSONB[];
BEGIN
    -- Get all fighter user IDs
    -- Note: The calling function should exclude specific fighters if needed
    FOR fighter_record IN 
        SELECT DISTINCT user_id 
        FROM fighter_profiles 
        WHERE user_id IS NOT NULL
    LOOP
        -- Build batch
        notification_batch := array_append(
            notification_batch,
            jsonb_build_object(
                'user_id', fighter_record.user_id,
                'type', notification_type,
                'title', notification_title,
                'message', notification_message,
                'action_url', action_url,
                'is_read', false,
                'created_at', NOW()
            )
        );
        
        -- Insert in batches
        IF array_length(notification_batch, 1) >= batch_size THEN
            INSERT INTO notifications (
                user_id, type, title, message, action_url, is_read, created_at
            )
            SELECT 
                (item->>'user_id')::uuid,
                item->>'type',
                item->>'title',
                item->>'message',
                NULLIF(item->>'action_url', 'null'),
                (item->>'is_read')::boolean,
                (item->>'created_at')::timestamptz
            FROM unnest(notification_batch) AS item;
            
            notification_batch := ARRAY[]::jsonb[];
        END IF;
    END LOOP;
    
    -- Insert remaining notifications
    IF array_length(notification_batch, 1) > 0 THEN
        INSERT INTO notifications (
            user_id, type, title, message, action_url, is_read, created_at
        )
        SELECT 
            (item->>'user_id')::uuid,
            item->>'type',
            item->>'title',
            item->>'message',
            NULLIF(item->>'action_url', 'null'),
            (item->>'is_read')::boolean,
            (item->>'created_at')::timestamptz
        FROM unnest(notification_batch) AS item;
    END IF;
END;
$$;

-- Create trigger function to notify when a new fighter profile is created
CREATE OR REPLACE FUNCTION notify_new_fighter_joined()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    fighter_name TEXT;
    fighter_user_id UUID;
BEGIN
    -- Get fighter name and user_id
    fighter_name := COALESCE(NEW.name, 'A new fighter');
    fighter_user_id := NEW.user_id;
    
    -- Only notify if this is a new fighter (not an update)
    -- We check if there are other fighters already (to avoid notifying on the very first fighter)
    IF EXISTS (SELECT 1 FROM fighter_profiles WHERE id != NEW.id) THEN
        -- Create notifications for all existing fighters (excluding the new fighter)
        -- We'll manually insert notifications to exclude the new fighter
        INSERT INTO notifications (user_id, type, title, message, action_url, is_read, created_at)
        SELECT 
            fp.user_id,
            'NewFighter',
            'New Fighter Joined',
            fighter_name || ' has joined the club!',
            '/fighter/' || fighter_user_id::text,
            false,
            NOW()
        FROM fighter_profiles fp
        WHERE fp.user_id IS NOT NULL 
          AND fp.user_id != fighter_user_id;  -- Exclude the new fighter from receiving their own notification
    END IF;
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Log error but don't fail the insert
        RAISE WARNING 'Failed to create new fighter notifications: %', SQLERRM;
        RETURN NEW;
END;
$$;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS trigger_notify_new_fighter_joined ON fighter_profiles;

-- Create trigger
CREATE TRIGGER trigger_notify_new_fighter_joined
    AFTER INSERT ON fighter_profiles
    FOR EACH ROW
    EXECUTE FUNCTION notify_new_fighter_joined();

-- Grant necessary permissions (specify full signature to avoid ambiguity)
GRANT EXECUTE ON FUNCTION create_notification_for_all_fighters(TEXT, TEXT, TEXT, TEXT) TO postgres, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION notify_new_fighter_joined() TO postgres, anon, authenticated, service_role;

-- Success message
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '✅ New Fighter notification trigger created successfully!';
    RAISE NOTICE '   - Trigger: trigger_notify_new_fighter_joined';
    RAISE NOTICE '   - Notification type: NewFighter';
    RAISE NOTICE '   - Action URL: /fighter/{user_id}';
    RAISE NOTICE '';
END $$;

