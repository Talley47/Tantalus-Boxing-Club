-- Diagnostic script to see what's wrong with notifications constraint
-- Run this FIRST to see what we're dealing with

-- 1. Check what constraints exist on notifications table
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint
WHERE conrelid = 'notifications'::regclass
AND contype = 'c'
ORDER BY conname;

-- 2. Check what notification types currently exist
SELECT 
    type,
    COUNT(*) as count
FROM notifications
GROUP BY type
ORDER BY type;

-- 3. Check which types are INVALID (not in the allowed list)
SELECT 
    type,
    COUNT(*) as count
FROM notifications
WHERE type NOT IN (
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
ORDER BY type;

-- 4. Count total invalid rows
SELECT COUNT(*) as total_invalid_rows
FROM notifications
WHERE type NOT IN (
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
);

