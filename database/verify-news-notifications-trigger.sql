-- Verify and fix News notification trigger
-- This ensures notifications are created for all fighters when news is posted

-- First, ensure the trigger function only creates notifications for published news
CREATE OR REPLACE FUNCTION notify_news_posted()
RETURNS TRIGGER AS $$
BEGIN
    -- Only create notifications for published news/announcements
    IF NEW.is_published = TRUE THEN
        -- Use a background job or async approach to avoid blocking
        -- For now, we'll use a more efficient batch insert
        PERFORM create_notification_for_all_fighters(
            'News',
            'New Announcement',
            'A new announcement has been posted: ' || COALESCE(NEW.title, 'News'),
            '/?tab=news'  -- Navigate to home page and switch to News & Announcements tab
        );
    END IF;
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Log error but don't fail the insert
        RAISE WARNING 'Failed to create notifications: %', SQLERRM;
        RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Also trigger when news is updated from unpublished to published
CREATE OR REPLACE FUNCTION notify_news_published()
RETURNS TRIGGER AS $$
BEGIN
    -- Only create notifications if news was just published (was unpublished, now published)
    IF OLD.is_published = FALSE AND NEW.is_published = TRUE THEN
        PERFORM create_notification_for_all_fighters(
            'News',
            'New Announcement',
            'A new announcement has been posted: ' || COALESCE(NEW.title, 'News'),
            '/?tab=news'
        );
    END IF;
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Failed to create notifications: %', SQLERRM;
        RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop and recreate triggers to ensure they're active
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

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION create_notification TO authenticated;
GRANT EXECUTE ON FUNCTION create_notification_for_all_fighters TO authenticated;
GRANT EXECUTE ON FUNCTION notify_news_posted TO authenticated;
GRANT EXECUTE ON FUNCTION notify_news_published TO authenticated;

-- Verify the trigger exists
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'trigger_notify_news_posted' 
        AND tgrelid = 'news_announcements'::regclass
    ) THEN
        RAISE NOTICE '✅ News notification trigger is active';
    ELSE
        RAISE WARNING '❌ News notification trigger is missing!';
    END IF;
    
    IF EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'trigger_notify_news_published' 
        AND tgrelid = 'news_announcements'::regclass
    ) THEN
        RAISE NOTICE '✅ News publish notification trigger is active';
    ELSE
        RAISE WARNING '❌ News publish notification trigger is missing!';
    END IF;
END $$;

