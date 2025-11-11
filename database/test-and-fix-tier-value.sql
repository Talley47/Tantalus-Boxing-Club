-- Simple test and fix for tier constraint
-- Run this FIRST to see what your constraint expects

-- 1. Show the constraint
SELECT 
    'Your constraint expects:' as info,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint
WHERE conrelid = 'fighter_profiles'::regclass
AND conname = 'fighter_profiles_tier_check';

-- 2. Test which value works (this won't change any data)
DO $$
BEGIN
    RAISE NOTICE 'Testing tier values...';
    
    -- Try capitalized
    BEGIN
        UPDATE fighter_profiles SET tier = 'Amateur' WHERE FALSE;
        RAISE NOTICE '✅ RESULT: Your constraint accepts "Amateur" (capitalized)';
        RAISE NOTICE '   → Use this value in the functions below';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE '❌ RESULT: Your constraint does NOT accept "Amateur" (capitalized)';
    END;
    
    -- Try lowercase
    BEGIN
        UPDATE fighter_profiles SET tier = 'amateur' WHERE FALSE;
        RAISE NOTICE '✅ RESULT: Your constraint accepts "amateur" (lowercase)';
        RAISE NOTICE '   → Use this value in the functions below';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE '❌ RESULT: Your constraint does NOT accept "amateur" (lowercase)';
    END;
END $$;

-- 3. Based on the results above, run ONE of these:

-- OPTION A: If constraint accepts "Amateur" (capitalized), run this:
/*
CREATE OR REPLACE FUNCTION reset_all_fighters_records()
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_count INTEGER;
BEGIN
    -- Admin check here...
    UPDATE fighter_profiles
    SET tier = 'Amateur', wins = 0, losses = 0, draws = 0, knockouts = 0, points = 0
    WHERE TRUE;
    RETURN json_build_object('success', true);
END;
$$;
*/

-- OPTION B: If constraint accepts "amateur" (lowercase), run this:
/*
CREATE OR REPLACE FUNCTION reset_all_fighters_records()
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_count INTEGER;
BEGIN
    -- Admin check here...
    UPDATE fighter_profiles
    SET tier = 'amateur', wins = 0, losses = 0, draws = 0, knockouts = 0, points = 0
    WHERE TRUE;
    RETURN json_build_object('success', true);
END;
$$;
*/

-- After running the test above, tell me which value worked and I'll give you the complete function



