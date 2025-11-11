-- Fix events trigger to use 'name' instead of 'title'
-- The error "record 'new' has no field 'title'" occurs because the events table uses 'name' not 'title'
-- Run this in Supabase SQL Editor

-- Fix the notify_event_created function
CREATE OR REPLACE FUNCTION notify_event_created()
RETURNS TRIGGER AS $$
DECLARE
    v_event_type TEXT;
BEGIN
    -- Determine event type based on event_type column or tournament_id
    IF NEW.tournament_id IS NOT NULL THEN
        v_event_type := 'Tournament';
    ELSIF NEW.event_type = 'Tournament' THEN
        v_event_type := 'Tournament';
    ELSE
        v_event_type := 'Event';
    END IF;
    
    -- Create notification for all fighters
    -- Use NEW.name instead of NEW.title (events table uses 'name' field)
    PERFORM create_notification_for_all_fighters(
        v_event_type,
        'New ' || v_event_type || ' Created',
        'A new ' || LOWER(v_event_type) || ' has been scheduled: ' || COALESCE(NEW.name, 'Event'),
        '/scheduling'
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Verify the trigger exists and is attached correctly
SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement
FROM information_schema.triggers
WHERE event_object_table = 'events'
AND trigger_name = 'trigger_notify_event_created';

-- Summary
DO $$
BEGIN
    RAISE NOTICE '✅ Events trigger fixed! Now uses NEW.name instead of NEW.title';
END $$;

