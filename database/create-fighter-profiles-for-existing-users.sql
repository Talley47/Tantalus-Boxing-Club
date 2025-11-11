-- Create fighter_profiles for existing users who don't have one
-- Run this in Supabase SQL Editor to create fighter profiles for all existing auth users

-- First, check how many users need fighter profiles
SELECT 
    COUNT(*) as users_without_profiles
FROM auth.users u
LEFT JOIN public.fighter_profiles fp ON u.id = fp.user_id
WHERE fp.id IS NULL
AND COALESCE(
    (u.raw_app_meta_data->>'role')::TEXT,
    (u.raw_user_meta_data->>'role')::TEXT,
    'fighter'
) = 'fighter';

-- Create fighter profiles for users who don't have one
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
    trainer,
    gym,
    points,
    wins,
    losses,
    draws
)
SELECT 
    u.id as user_id,
    COALESCE(
        u.raw_user_meta_data->>'fighterName',
        u.raw_user_meta_data->>'name',
        u.raw_user_meta_data->>'full_name',
        split_part(u.email, '@', 1) || ' Fighter'
    ) as name,
    LOWER(REPLACE(
        COALESCE(
            u.raw_user_meta_data->>'fighterName',
            u.raw_user_meta_data->>'name',
            u.raw_user_meta_data->>'full_name',
            split_part(u.email, '@', 1)
        ),
        ' ', '_'
    )) as handle,
    COALESCE(
        (u.raw_user_meta_data->>'birthday')::DATE,
        CURRENT_DATE - INTERVAL '25 years'
    ) as birthday,
    COALESCE(
        u.raw_user_meta_data->>'hometown',
        'Unknown'
    ) as hometown,
    COALESCE(
        LOWER(u.raw_user_meta_data->>'stance'),
        'orthodox'
    ) as stance,
    COALESCE(
        (u.raw_user_meta_data->>'heightFeet')::INTEGER,
        5
    ) as height_feet,
    COALESCE(
        (u.raw_user_meta_data->>'heightInches')::INTEGER,
        10
    ) as height_inches,
    COALESCE(
        (u.raw_user_meta_data->>'reach')::INTEGER,
        70
    ) as reach,
    COALESCE(
        CASE 
            WHEN u.raw_user_meta_data->>'weight' IS NOT NULL THEN
                ROUND((u.raw_user_meta_data->>'weight')::NUMERIC / 0.453592)::INTEGER
            ELSE 150
        END,
        150
    ) as weight,
    COALESCE(
        u.raw_user_meta_data->>'weightClass',
        'Middleweight'
    ) as weight_class,
    'amateur' as tier,
    u.raw_user_meta_data->>'trainer' as trainer,
    u.raw_user_meta_data->>'gym' as gym,
    0 as points,
    0 as wins,
    0 as losses,
    0 as draws
FROM auth.users u
LEFT JOIN public.fighter_profiles fp ON u.id = fp.user_id
WHERE fp.id IS NULL
AND COALESCE(
    (u.raw_app_meta_data->>'role')::TEXT,
    (u.raw_user_meta_data->>'role')::TEXT,
    'fighter'
) = 'fighter'
ON CONFLICT (user_id) DO NOTHING;

-- Verify the results
SELECT 
    COUNT(*) as total_users,
    COUNT(fp.id) as users_with_profiles,
    COUNT(*) - COUNT(fp.id) as users_without_profiles
FROM auth.users u
LEFT JOIN public.fighter_profiles fp ON u.id = fp.user_id
WHERE COALESCE(
    (u.raw_app_meta_data->>'role')::TEXT,
    (u.raw_user_meta_data->>'role')::TEXT,
    'fighter'
) = 'fighter';

-- Show created profiles
SELECT 
    fp.id,
    fp.user_id,
    fp.name,
    fp.handle,
    fp.tier,
    fp.weight_class,
    fp.points,
    u.email
FROM public.fighter_profiles fp
JOIN auth.users u ON fp.user_id = u.id
ORDER BY fp.created_at DESC
LIMIT 10;

