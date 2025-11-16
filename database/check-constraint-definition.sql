-- Check what the tier constraint actually expects
-- Run this FIRST to see the problem

-- Check if tier column exists
SELECT 
    'Column Check' as info,
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'fighter_profiles' 
            AND column_name = 'tier'
        ) THEN 'tier column EXISTS'
        ELSE 'tier column DOES NOT EXIST'
    END as value;

-- Check constraint
SELECT 
    'Constraint Name' as info,
    COALESCE(conname, 'NOT FOUND') as value
FROM pg_constraint
WHERE conrelid = 'fighter_profiles'::regclass
AND conname = 'fighter_profiles_tier_check'

UNION ALL

SELECT 
    'Constraint Definition' as info,
    COALESCE(pg_get_constraintdef(oid), 'NOT FOUND') as value
FROM pg_constraint
WHERE conrelid = 'fighter_profiles'::regclass
AND conname = 'fighter_profiles_tier_check';

-- Check current tier values (only if column exists)
DO $$
DECLARE
    r RECORD;
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'fighter_profiles' 
        AND column_name = 'tier'
    ) THEN
        RAISE NOTICE '=== Current Tier Values ===';
        FOR r IN 
            SELECT tier, COUNT(*) as cnt
            FROM fighter_profiles
            GROUP BY tier
            ORDER BY tier
        LOOP
            RAISE NOTICE '  %: % fighters', r.tier, r.cnt;
        END LOOP;
    ELSE
        RAISE NOTICE '⚠️ tier column does not exist in fighter_profiles table';
    END IF;
END $$;

