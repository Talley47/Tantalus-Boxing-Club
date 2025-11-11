-- Diagnostic: Find all notification types and identify violations
-- Run this FIRST to see what's in your database

-- 1. Show all distinct notification types with counts
SELECT 
    type,
    COUNT(*) as count,
    LENGTH(type) as length,
    type = TRIM(type) as is_trimmed
FROM notifications
GROUP BY type, LENGTH(type)
ORDER BY count DESC;

-- 2. Show which types would violate the new constraint
-- (assuming the new constraint uses these values)
SELECT 
    type,
    COUNT(*) as count
FROM notifications
WHERE type IS NOT NULL
AND type NOT IN (
    'Match', 
    'Tournament', 
    'Tier', 
    'Dispute', 
    'Award', 
    'General',
    'FightRequest',
    'TrainingCamp',
    'Callout',
    'FightUrlSubmission',
    'Event',
    'News',
    'NewFighter'
)
GROUP BY type
ORDER BY count DESC;

-- 3. Show sample rows with invalid types
SELECT 
    id,
    type,
    title,
    created_at
FROM notifications
WHERE type IS NOT NULL
AND type NOT IN (
    'Match', 
    'Tournament', 
    'Tier', 
    'Dispute', 
    'Award', 
    'General',
    'FightRequest',
    'TrainingCamp',
    'Callout',
    'FightUrlSubmission',
    'Event',
    'News',
    'NewFighter'
)
LIMIT 20;

-- 4. Check what the current constraint allows
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint
WHERE conrelid = 'notifications'::regclass
AND contype = 'c'
ORDER BY conname;

