-- Check if fighter_profiles table has data and if users need profiles created
-- Run this in Supabase SQL Editor

-- 1. Count total fighter profiles
SELECT COUNT(*) as total_fighter_profiles FROM fighter_profiles;

-- 2. Count users who have profiles vs don't have profiles
SELECT 
    (SELECT COUNT(*) FROM auth.users) as total_users,
    (SELECT COUNT(*) FROM fighter_profiles) as users_with_fighter_profiles,
    (SELECT COUNT(*) FROM auth.users) - (SELECT COUNT(*) FROM fighter_profiles) as users_missing_profiles;

-- 3. List users who don't have fighter profiles yet
SELECT 
    u.id,
    u.email,
    u.created_at,
    CASE 
        WHEN fp.id IS NULL THEN '❌ Missing Fighter Profile'
        ELSE '✅ Has Fighter Profile'
    END as profile_status
FROM auth.users u
LEFT JOIN fighter_profiles fp ON fp.user_id = u.id
ORDER BY u.created_at DESC
LIMIT 20;

-- 4. Show sample fighter profiles if any exist
SELECT 
    id,
    user_id,
    name,
    handle,
    weight_class,
    tier,
    points,
    wins,
    losses,
    draws
FROM fighter_profiles
ORDER BY points DESC
LIMIT 10;

