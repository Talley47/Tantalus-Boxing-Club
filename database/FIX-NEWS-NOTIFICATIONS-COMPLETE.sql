-- COMPLETE FIX: News and Announcements Notification System
-- This script ensures notifications are created for all fighters when admin posts news
-- Run this script to fix the notification system

-- Step 1: Ensure create_notification_for_all_fighters function exists
-- Drop all existing versions first to avoid conflicts
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

-- Create the helper function to create notifications for all fighters
CREATE OR REPLACE FUNCTION create_notification_for_all_fighters(
    notification_type TEXT,
    notification_title TEXT,
    notification_message TEXT,
    action_url TEXT DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    fighter_record RECORD;
    batch_size INTEGER := 100;
    notification_batch JSONB[];
BEGIN
    -- Get all fighter user IDs
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

-- Step 2: Create trigger function for new news posts
CREATE OR REPLACE FUNCTION notify_news_posted()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Only create notifications for published news/announcements
    IF NEW.is_published = TRUE THEN
        -- Create notifications for all fighters
        PERFORM create_notification_for_all_fighters(
            'News'::TEXT,
            'New Announcement'::TEXT,
            'A new announcement has been posted: ' || COALESCE(NEW.title, 'News')::TEXT,
            '/?tab=news'::TEXT
        );
    END IF;
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Log error but don't fail the insert
        RAISE WARNING 'Failed to create news notifications: %', SQLERRM;
        RETURN NEW;
END;
$$;

-- Step 3: Create trigger function for when news is published (updated from unpublished to published)
CREATE OR REPLACE FUNCTION notify_news_published()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Only create notifications if news was just published (was unpublished, now published)
    IF OLD.is_published = FALSE AND NEW.is_published = TRUE THEN
        -- Create notifications for all fighters
        PERFORM create_notification_for_all_fighters(
            'News'::TEXT,
            'New Announcement'::TEXT,
            'A new announcement has been posted: ' || COALESCE(NEW.title, 'News')::TEXT,
            '/?tab=news'::TEXT
        );
    END IF;
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Log error but don't fail the update
        RAISE WARNING 'Failed to create news publish notifications: %', SQLERRM;
        RETURN NEW;
END;
$$;

-- Step 4: Drop and recreate triggers to ensure they're active
DROP TRIGGER IF EXISTS trigger_notify_news_posted ON news_announcements;
CREATE TRIGGER trigger_notify_news_posted
    AFTER INSERT ON news_announcements
    FOR EACH ROW
    EXECUTE FUNCTION notify_news_posted();

DROP TRIGGER IF EXISTS trigger_notify_news_published ON news_announcements;
CREATE TRIGGER trigger_notify_news_published
    AFTER UPDATE ON news_announcements
    FOR EACH ROW
    WHEN (OLD.is_published IS DISTINCT FROM NEW.is_published)
    EXECUTE FUNCTION notify_news_published();

-- Step 5: Grant execute permissions
GRANT EXECUTE ON FUNCTION create_notification_for_all_fighters(TEXT, TEXT, TEXT, TEXT) TO postgres, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION notify_news_posted() TO postgres, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION notify_news_published() TO postgres, anon, authenticated, service_role;

-- Step 6: Verify the triggers exist
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'trigger_notify_news_posted' 
        AND tgrelid = 'news_announcements'::regclass
    ) THEN
        RAISE NOTICE '✅ News notification trigger (INSERT) is active';
    ELSE
        RAISE WARNING '❌ News notification trigger (INSERT) is missing!';
    END IF;
    
    IF EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'trigger_notify_news_published' 
        AND tgrelid = 'news_announcements'::regclass
    ) THEN
        RAISE NOTICE '✅ News publish notification trigger (UPDATE) is active';
    ELSE
        RAISE WARNING '❌ News publish notification trigger (UPDATE) is missing!';
    END IF;
    
    -- Verify function exists
    IF EXISTS (
        SELECT 1 FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'public'
          AND p.proname = 'create_notification_for_all_fighters'
    ) THEN
        RAISE NOTICE '✅ create_notification_for_all_fighters function exists';
    ELSE
        RAISE WARNING '❌ create_notification_for_all_fighters function is missing!';
    END IF;
END $$;

-- Step 7: Test the function (optional - comment out if you don't want test notifications)
-- Uncomment the following to test:
/*
DO $$
BEGIN
    -- This will create test notifications for all fighters
    -- Comment this out after testing
    PERFORM create_notification_for_all_fighters(
        'News'::TEXT,
        'Test Notification'::TEXT,
        'This is a test notification to verify the system is working.'::TEXT,
        '/?tab=news'::TEXT
    );
    RAISE NOTICE '✅ Test notification created for all fighters';
END $$;
*/

