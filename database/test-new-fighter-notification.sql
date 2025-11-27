-- Test query to check if NewFighter notifications have correct action_url
-- Run this to see what action_url values are being set

SELECT 
    id,
    type,
    title,
    message,
    action_url,
    created_at,
    is_read
FROM notifications
WHERE type = 'NewFighter'
ORDER BY created_at DESC
LIMIT 10;

-- Check if action_url format is correct
SELECT 
    id,
    type,
    title,
    action_url,
    CASE 
        WHEN action_url LIKE '/fighter/%' THEN '✅ Correct format'
        WHEN action_url IS NULL THEN '❌ Missing action_url'
        ELSE '⚠️ Wrong format: ' || action_url
    END as url_status
FROM notifications
WHERE type = 'NewFighter'
ORDER BY created_at DESC
LIMIT 10;

