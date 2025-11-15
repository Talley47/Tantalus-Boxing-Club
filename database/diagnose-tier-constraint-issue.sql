-- Comprehensive diagnostic for tier constraint issue
-- Run this to see exactly what's happening

-- 1. Check what the constraint actually expects
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint
WHERE conrelid = 'fighter_profiles'::regclass
AND contype = 'c'
AND (conname LIKE '%tier%' OR pg_get_constraintdef(oid) LIKE '%tier%');

-- 2. Check what tier values currently exist
SELECT 
    tier,
    COUNT(*) as count
FROM fighter_profiles
GROUP BY tier
ORDER BY tier;

-- 3. Check for any triggers on fighter_profiles that might set tier
SELECT 
    tgname as trigger_name,
    pg_get_triggerdef(oid) as trigger_definition
FROM pg_trigger
WHERE tgrelid = 'fighter_profiles'::regclass
AND tgisinternal = false
ORDER BY tgname;

-- 4. Check what the reset_all_fighters_records function currently uses
SELECT 
    prosrc as function_source
FROM pg_proc
WHERE proname = 'reset_all_fighters_records';

-- 5. Test what happens if we try to set tier to different values
-- (This will show which values are valid)
DO $$
DECLARE
    test_values TEXT[] := ARRAY['amateur', 'Amateur', 'AMATEUR', 'semi-pro', 'Semi-Pro'];
    test_val TEXT;
    is_valid BOOLEAN;
BEGIN
    RAISE NOTICE 'Testing which tier values are valid:';
    FOREACH test_val IN ARRAY test_values
    LOOP
        BEGIN
            -- Try to update a test row (if any exist)
            UPDATE fighter_profiles
            SET tier = test_val
            WHERE id = (SELECT id FROM fighter_profiles LIMIT 1)
            AND FALSE; -- Never actually update, just check constraint
            
            is_valid := TRUE;
        EXCEPTION
            WHEN check_violation THEN
                is_valid := FALSE;
            WHEN OTHERS THEN
                is_valid := NULL;
        END;
        
        IF is_valid IS NULL THEN
            RAISE NOTICE '  %: Could not test (no rows or other error)', test_val;
        ELSIF is_valid THEN
            RAISE NOTICE '  %: VALID', test_val;
        ELSE
            RAISE NOTICE '  %: INVALID', test_val;
        END IF;
    END LOOP;
END $$;

-- 6. Show the actual constraint check expression
SELECT 
    conname,
    pg_get_constraintdef(oid) as definition,
    CASE 
        WHEN pg_get_constraintdef(oid) LIKE '%amateur%' THEN 'Contains amateur'
        WHEN pg_get_constraintdef(oid) LIKE '%Amateur%' THEN 'Contains Amateur'
        ELSE 'No amateur found'
    END as case_check
FROM pg_constraint
WHERE conrelid = 'fighter_profiles'::regclass
AND conname = 'fighter_profiles_tier_check';








