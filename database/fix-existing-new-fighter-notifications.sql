-- Fix existing NewFighter notifications that are missing action_url
-- This updates notifications to include the correct fighter profile URL

-- First, let's see what we're working with
SELECT 
    id,
    type,
    title,
    message,
    action_url,
    created_at
FROM notifications
WHERE type = 'NewFighter'
  AND (action_url IS NULL OR action_url = '' OR action_url NOT LIKE '/fighter/%')
ORDER BY created_at DESC
LIMIT 10;

-- Update notifications to extract user_id from message and set action_url
-- The message format is: "{fighter_name} has joined the club!"
-- We need to find the fighter by name and get their user_id
-- This handles cases where action_url is NULL, empty, wrong format, or points to /rankings
-- Uses case-insensitive matching
UPDATE notifications n
SET action_url = '/fighter/' || fp.user_id::text
FROM fighter_profiles fp
WHERE n.type = 'NewFighter'
  AND (
    n.action_url IS NULL 
    OR n.action_url = '' 
    OR n.action_url NOT LIKE '/fighter/%'
    OR n.action_url = '/rankings'  -- Fix notifications that incorrectly point to rankings
  )
  AND n.message LIKE '% has joined the club!'
  AND LOWER(TRIM(SPLIT_PART(n.message, ' has joined the club!', 1))) = LOWER(fp.name)
  AND fp.user_id IS NOT NULL;

-- Verify the updates
SELECT 
    id,
    type,
    title,
    message,
    action_url,
    CASE 
        WHEN action_url LIKE '/fighter/%' THEN '✅ Fixed'
        WHEN action_url IS NULL THEN '❌ Still missing'
        ELSE '⚠️ Wrong format'
    END as status
FROM notifications
WHERE type = 'NewFighter'
ORDER BY created_at DESC
LIMIT 10;

-- Success message
DO $$
DECLARE
    updated_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO updated_count
    FROM notifications
    WHERE type = 'NewFighter'
      AND action_url LIKE '/fighter/%';
    
    RAISE NOTICE '';
    RAISE NOTICE '✅ Updated NewFighter notifications!';
    RAISE NOTICE '   - Notifications with correct action_url: %', updated_count;
    RAISE NOTICE '';
END $$;

