-- Quick check and fix for tier constraint
-- Run this to see what the constraint expects and get a fix

-- 1. Show the constraint definition
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint
WHERE conrelid = 'fighter_profiles'::regclass
AND conname = 'fighter_profiles_tier_check';

-- 2. Show what tier values currently exist
SELECT 
    tier,
    COUNT(*) as count
FROM fighter_profiles
GROUP BY tier
ORDER BY tier;

-- 3. Based on the constraint above, run the appropriate fix:
-- If constraint shows 'Amateur' (capitalized), run: fix-reset-functions-smart.sql
-- If constraint shows 'amateur' (lowercase), the script will auto-detect it

-- The fix-reset-functions-smart.sql script will automatically detect
-- which case your constraint expects and update the functions accordingly.




