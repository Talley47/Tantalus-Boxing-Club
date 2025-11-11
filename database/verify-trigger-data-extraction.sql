-- Debug script to check what data is in user metadata
-- Run this to see what data is actually being stored in raw_user_meta_data
-- Replace 'USER_EMAIL_HERE' with an actual user email

SELECT 
    id,
    email,
    raw_user_meta_data->>'fighterName' as fighter_name,
    raw_user_meta_data->>'name' as account_name,
    raw_user_meta_data->>'height_feet' as height_feet,
    raw_user_meta_data->>'height_inches' as height_inches,
    raw_user_meta_data->>'weight' as weight_kg,
    raw_user_meta_data->>'reach' as reach_cm,
    raw_user_meta_data->>'hometown' as hometown,
    raw_user_meta_data->>'stance' as stance,
    raw_user_meta_data->>'weightClass' as weight_class,
    raw_user_meta_data->>'trainer' as trainer,
    raw_user_meta_data->>'gym' as gym,
    raw_user_meta_data->>'platform' as platform,
    raw_user_meta_data->>'timezone' as timezone,
    raw_user_meta_data->>'birthday' as birthday,
    created_at
FROM auth.users
WHERE email = 'USER_EMAIL_HERE'  -- Replace with actual email
ORDER BY created_at DESC
LIMIT 1;

-- Also check the fighter profile that was created
SELECT 
    fp.id,
    fp.user_id,
    fp.name as fighter_name,
    fp.handle,
    fp.height_feet,
    fp.height_inches,
    fp.weight,
    fp.reach,
    fp.hometown,
    fp.stance,
    fp.weight_class,
    fp.trainer,
    fp.gym,
    fp.platform,
    fp.timezone,
    fp.birthday,
    fp.created_at
FROM public.fighter_profiles fp
JOIN auth.users u ON fp.user_id = u.id
WHERE u.email = 'USER_EMAIL_HERE'  -- Replace with actual email
ORDER BY fp.created_at DESC
LIMIT 1;

