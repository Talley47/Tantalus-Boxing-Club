-- Check what the tier constraint actually expects
-- Run this to see the constraint definition

SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint
WHERE conrelid = 'fighter_profiles'::regclass
AND contype = 'c'
AND (conname LIKE '%tier%' OR pg_get_constraintdef(oid) LIKE '%tier%');

-- Also show what tier values currently exist in the database
SELECT 
    tier,
    COUNT(*) as count
FROM fighter_profiles
GROUP BY tier
ORDER BY tier;





