-- ============================================================================
-- CREATE FIGHTER PROFILES FOR ALL EXISTING USERS
-- This script creates fighter profiles for all 32 users in auth.users
-- ============================================================================

-- Step 1: Create fighter profiles for all users who don't have one yet
-- Uses default values that satisfy all NOT NULL constraints
INSERT INTO public.fighter_profiles (
    user_id,
    name,
    handle,
    birthday,
    hometown,
    stance,
    height_feet,
    height_inches,
    reach,
    weight,
    weight_class,
    tier,
    points,
    wins,
    losses,
    draws,
    knockouts
)
SELECT 
    u.id as user_id,
    -- Use email username as name, or "Fighter" + number if email is null
    COALESCE(
        SPLIT_PART(u.email, '@', 1),
        'Fighter ' || ROW_NUMBER() OVER (ORDER BY u.created_at)
    ) as name,
    -- Create unique handle from email or user ID (ensure uniqueness with UUID suffix)
    -- Use first 12 chars of UUID (without dashes) to guarantee uniqueness
    COALESCE(
        LOWER(REGEXP_REPLACE(SPLIT_PART(u.email, '@', 1), '[^a-z0-9]', '_', 'g')),
        'fighter'
    ) || '_' || REPLACE(SUBSTRING(u.id::TEXT, 1, 13), '-', '') as handle,
    -- Default birthday: 25 years ago
    (CURRENT_DATE - INTERVAL '25 years')::DATE as birthday,
    -- Default hometown
    'New York, NY' as hometown,
    -- Random stance (default to orthodox)
    'orthodox' as stance,
    -- Default height: 5'10"
    5 as height_feet,
    10 as height_inches,
    -- Default reach: 72 inches
    72 as reach,
    -- Default weight: 170 lbs (middleweight)
    170 as weight,
    -- Default weight class
    'Middleweight' as weight_class,
    -- Default tier: 'amateur' (valid tier value)
    'amateur' as tier,
    -- Default stats
    0 as points,
    0 as wins,
    0 as losses,
    0 as draws,
    0 as knockouts
FROM auth.users u
LEFT JOIN public.fighter_profiles fp ON u.id = fp.user_id
WHERE fp.user_id IS NULL  -- Only create for users without fighter profiles
  AND u.deleted_at IS NULL  -- Skip deleted users
ON CONFLICT (user_id) DO NOTHING;  -- Skip if somehow already exists

-- Step 2: Verify the results
SELECT 
    '✅ SUCCESS' as status,
    COUNT(*) as total_users_in_auth,
    (SELECT COUNT(*) FROM public.fighter_profiles) as total_fighter_profiles,
    (SELECT COUNT(*) FROM public.fighter_profiles WHERE user_id IS NOT NULL) as profiles_with_user_id
FROM auth.users
WHERE deleted_at IS NULL;

-- Step 3: Show sample of created profiles
SELECT 
    fp.user_id,
    fp.name,
    fp.handle,
    fp.tier,
    fp.points,
    u.email
FROM public.fighter_profiles fp
JOIN auth.users u ON fp.user_id = u.id
ORDER BY fp.created_at DESC
LIMIT 10;

