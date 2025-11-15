-- Notification Triggers
-- Automatically creates notifications for various events

-- Function to create notification for a user
CREATE OR REPLACE FUNCTION create_notification(
    p_user_id UUID,
    p_type VARCHAR(20),
    p_title VARCHAR(100),
    p_message TEXT,
    p_action_url TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_notification_id UUID;
BEGIN
    INSERT INTO notifications (user_id, type, title, message, action_url, is_read)
    VALUES (p_user_id, p_type, p_title, p_message, p_action_url, false)
    RETURNING id INTO v_notification_id;
    
    RETURN v_notification_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to create notifications for all fighters (optimized with batching)
CREATE OR REPLACE FUNCTION create_notification_for_all_fighters(
    p_type VARCHAR(20),
    p_title VARCHAR(100),
    p_message TEXT,
    p_action_url TEXT DEFAULT NULL
)
RETURNS INTEGER AS $$
DECLARE
    v_count INTEGER := 0;
    v_user_ids UUID[];
BEGIN
    -- Collect all fighter user_ids into an array
    SELECT ARRAY_AGG(DISTINCT user_id) INTO v_user_ids
    FROM fighter_profiles
    WHERE user_id IS NOT NULL;
    
    -- If no fighters, return early
    IF v_user_ids IS NULL OR array_length(v_user_ids, 1) IS NULL THEN
        RETURN 0;
    END IF;
    
    -- Insert notifications in a single batch operation using unnest
    INSERT INTO notifications (user_id, type, title, message, action_url, is_read)
    SELECT 
        unnest(v_user_ids) as user_id,
        p_type,
        p_title,
        p_message,
        p_action_url,
        false;
    
    GET DIAGNOSTICS v_count = ROW_COUNT;
    
    RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger: New fighter joins the league
CREATE OR REPLACE FUNCTION notify_new_fighter()
RETURNS TRIGGER AS $$
DECLARE
    v_fighter_name TEXT;
    v_fighter_user_id UUID;
    v_existing_fighter RECORD;
BEGIN
    -- Get fighter name and user_id
    v_fighter_name := NEW.name;
    v_fighter_user_id := NEW.user_id;
    
    -- Create notification for all existing fighters (excluding the new fighter)
    -- We'll create notifications for all fighters, then delete the one for the new fighter
    PERFORM create_notification_for_all_fighters(
        'NewFighter',
        'New Fighter Joined',
        v_fighter_name || ' has joined the Tantalus Boxing League!',
        '/rankings'
    );
    
    -- Remove notification for the new fighter themselves
    DELETE FROM notifications 
    WHERE user_id = v_fighter_user_id 
    AND type = 'NewFighter' 
    AND title = 'New Fighter Joined'
    AND message LIKE v_fighter_name || '%';
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_notify_new_fighter ON fighter_profiles;
CREATE TRIGGER trigger_notify_new_fighter
    AFTER INSERT ON fighter_profiles
    FOR EACH ROW
    EXECUTE FUNCTION notify_new_fighter();

-- Trigger: Mandatory fight request received
CREATE OR REPLACE FUNCTION notify_fight_request()
RETURNS TRIGGER AS $$
DECLARE
    v_requester_name TEXT;
    v_target_user_id UUID;
BEGIN
    -- Only trigger for mandatory requests (check if request_type column exists, otherwise assume all are mandatory)
    -- Get requester name
    SELECT fp.name INTO v_requester_name
    FROM fighter_profiles fp
    WHERE fp.id = NEW.requester_id;
    
    -- Get target user_id
    SELECT fp.user_id INTO v_target_user_id
    FROM fighter_profiles fp
    WHERE fp.id = NEW.target_id;
    
    -- Create notification for target
    IF v_target_user_id IS NOT NULL AND v_requester_name IS NOT NULL THEN
        PERFORM create_notification(
            v_target_user_id,
            'FightRequest',
            'Mandatory Fight Request',
            v_requester_name || ' has sent you a mandatory fight request.',
            '/matchmaking'
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_notify_fight_request ON matchmaking_requests;
CREATE TRIGGER trigger_notify_fight_request
    AFTER INSERT ON matchmaking_requests
    FOR EACH ROW
    EXECUTE FUNCTION notify_fight_request();

-- Trigger: Training camp invitation received
CREATE OR REPLACE FUNCTION notify_training_camp_invitation()
RETURNS TRIGGER AS $$
DECLARE
    v_inviter_name TEXT;
    v_invitee_user_id UUID;
BEGIN
    -- Get inviter name
    SELECT fp.name INTO v_inviter_name
    FROM fighter_profiles fp
    WHERE fp.id = NEW.inviter_id;
    
    -- Get invitee user_id
    SELECT fp.user_id INTO v_invitee_user_id
    FROM fighter_profiles fp
    WHERE fp.id = NEW.invitee_id;
    
    -- Create notification for invitee
    PERFORM create_notification(
        v_invitee_user_id,
        'TrainingCamp',
        'Training Camp Invitation',
        v_inviter_name || ' has invited you to a training camp.',
        '/matchmaking'
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_notify_training_camp_invitation ON training_camp_invitations;
CREATE TRIGGER trigger_notify_training_camp_invitation
    AFTER INSERT ON training_camp_invitations
    FOR EACH ROW
    EXECUTE FUNCTION notify_training_camp_invitation();

-- Trigger: Callout request received
CREATE OR REPLACE FUNCTION notify_callout_request()
RETURNS TRIGGER AS $$
DECLARE
    v_caller_name TEXT;
    v_target_user_id UUID;
BEGIN
    -- Get caller name
    SELECT fp.name INTO v_caller_name
    FROM fighter_profiles fp
    WHERE fp.id = NEW.caller_id;
    
    -- Get target user_id
    SELECT fp.user_id INTO v_target_user_id
    FROM fighter_profiles fp
    WHERE fp.id = NEW.target_id;
    
    -- Create notification for target fighter
    IF v_target_user_id IS NOT NULL AND v_caller_name IS NOT NULL THEN
        PERFORM create_notification(
            v_target_user_id,
            'Callout',
            'Callout Request',
            v_caller_name || ' has called you out for a fight!',
            '/matchmaking'
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_notify_callout_request ON callout_requests;
CREATE TRIGGER trigger_notify_callout_request
    AFTER INSERT ON callout_requests
    FOR EACH ROW
    EXECUTE FUNCTION notify_callout_request();

-- Trigger: Dispute resolved
CREATE OR REPLACE FUNCTION notify_dispute_resolved()
RETURNS TRIGGER AS $$
DECLARE
    v_disputer_user_id UUID;
    v_opponent_user_id UUID;
    v_resolution_text TEXT;
BEGIN
    -- Only trigger when status changes to 'Resolved'
    IF NEW.status = 'Resolved' AND (OLD.status IS NULL OR OLD.status != 'Resolved') THEN
        -- Get disputer user_id
        SELECT fp.user_id INTO v_disputer_user_id
        FROM fighter_profiles fp
        WHERE fp.id = NEW.disputer_id;
        
        -- Get opponent user_id (if available)
        IF NEW.opponent_id IS NOT NULL THEN
            SELECT fp.user_id INTO v_opponent_user_id
            FROM fighter_profiles fp
            WHERE fp.id = NEW.opponent_id;
        END IF;
        
        -- Build resolution text
        v_resolution_text := 'Your dispute has been resolved. Resolution: ' || COALESCE(NEW.resolution_type, 'Resolved');
        
        -- Create notification for disputer
        IF v_disputer_user_id IS NOT NULL THEN
            PERFORM create_notification(
                v_disputer_user_id,
                'Dispute',
                'Dispute Resolved',
                v_resolution_text,
                '/disputes'
            );
        END IF;
        
        -- Create notification for opponent
        IF v_opponent_user_id IS NOT NULL THEN
            PERFORM create_notification(
                v_opponent_user_id,
                'Dispute',
                'Dispute Resolved',
                'A dispute involving you has been resolved.',
                '/disputes'
            );
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_notify_dispute_resolved ON disputes;
CREATE TRIGGER trigger_notify_dispute_resolved
    AFTER UPDATE ON disputes
    FOR EACH ROW
    EXECUTE FUNCTION notify_dispute_resolved();

-- Trigger: Fight URL Submission reviewed/approved/rejected
CREATE OR REPLACE FUNCTION notify_fight_url_submission()
RETURNS TRIGGER AS $$
DECLARE
    v_fighter_user_id UUID;
    v_status_text TEXT;
BEGIN
    -- Only trigger when status changes
    IF NEW.status != OLD.status THEN
        -- Get fighter user_id
        SELECT fp.user_id INTO v_fighter_user_id
        FROM fighter_profiles fp
        WHERE fp.id = NEW.fighter_id;
        
        -- Build status text
        IF NEW.status = 'Approved' THEN
            v_status_text := 'Your fight URL submission has been approved!';
        ELSIF NEW.status = 'Rejected' THEN
            v_status_text := 'Your fight URL submission has been rejected.';
        ELSIF NEW.status = 'In Review' THEN
            v_status_text := 'Your fight URL submission is now under review.';
        ELSE
            RETURN NEW;
        END IF;
        
        -- Create notification for fighter
        IF v_fighter_user_id IS NOT NULL THEN
            PERFORM create_notification(
                v_fighter_user_id,
                'FightUrlSubmission',
                'Fight URL Submission ' || NEW.status,
                v_status_text,
                '/fighter-profile'
            );
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_notify_fight_url_submission ON fight_url_submissions;
CREATE TRIGGER trigger_notify_fight_url_submission
    AFTER UPDATE ON fight_url_submissions
    FOR EACH ROW
    EXECUTE FUNCTION notify_fight_url_submission();

-- Trigger: Admin creates event (Fight Card or Tournament)
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
    -- Use NEW.name (events table uses 'name' field, not 'title')
    PERFORM create_notification_for_all_fighters(
        v_event_type,
        'New ' || v_event_type || ' Created',
        'A new ' || LOWER(v_event_type) || ' has been scheduled: ' || COALESCE(NEW.name, 'Event'),
        '/scheduling'
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_notify_event_created ON events;
CREATE TRIGGER trigger_notify_event_created
    AFTER INSERT ON events
    FOR EACH ROW
    EXECUTE FUNCTION notify_event_created();

-- Trigger: News/Announcement posted (with timeout protection)
CREATE OR REPLACE FUNCTION notify_news_posted()
RETURNS TRIGGER AS $$
BEGIN
    -- Use a background job or async approach to avoid blocking
    -- For now, we'll use a more efficient batch insert
    PERFORM create_notification_for_all_fighters(
        'News',
        'New Announcement',
        'A new announcement has been posted: ' || COALESCE(NEW.title, 'News'),
        '/home'
    );
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Log error but don't fail the insert
        RAISE WARNING 'Failed to create notifications: %', SQLERRM;
        RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_notify_news_posted ON news_announcements;
CREATE TRIGGER trigger_notify_news_posted
    AFTER INSERT ON news_announcements
    FOR EACH ROW
    EXECUTE FUNCTION notify_news_posted();

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION create_notification TO authenticated;
GRANT EXECUTE ON FUNCTION create_notification_for_all_fighters TO authenticated;

