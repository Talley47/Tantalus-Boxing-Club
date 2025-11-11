-- Verify and fix fighter names - ensures all fighters use their boxer/fighter name
-- Run this in Supabase SQL Editor to check and fix all fighter names

-- Step 1: Check current state - see which fighters have account names vs fighter names
SELECT 
    fp.id,
    fp.name as current_fighter_profile_name,
    fp.handle,
    au.email,
    au.raw_user_meta_data->>'fighterName' as metadata_fighter_name,
    au.raw_user_meta_data->>'name' as metadata_account_name,
    au.raw_user_meta_data->>'full_name' as metadata_full_name,
    CASE 
        WHEN au.raw_user_meta_data->>'fighterName' IS NOT NULL 
             AND au.raw_user_meta_data->>'fighterName' != '' 
             AND fp.name != au.raw_user_meta_data->>'fighterName'
        THEN 'NEEDS_UPDATE'
        WHEN au.raw_user_meta_data->>'fighterName' IS NULL 
             OR au.raw_user_meta_data->>'fighterName' = ''
        THEN 'NO_FIGHTER_NAME_IN_METADATA'
        ELSE 'OK'
    END as status
FROM public.fighter_profiles fp
JOIN auth.users au ON au.id = fp.user_id
ORDER BY fp.created_at DESC;

-- Step 2: Update all fighters who have fighterName in metadata
-- This will set their fighter_profiles.name to the fighterName from metadata
UPDATE public.fighter_profiles fp
SET name = (
    SELECT au.raw_user_meta_data->>'fighterName' 
    FROM auth.users au 
    WHERE au.id = fp.user_id
    AND au.raw_user_meta_data->>'fighterName' IS NOT NULL
    AND au.raw_user_meta_data->>'fighterName' != ''
)
WHERE EXISTS (
    SELECT 1 
    FROM auth.users au 
    WHERE au.id = fp.user_id 
    AND au.raw_user_meta_data->>'fighterName' IS NOT NULL
    AND au.raw_user_meta_data->>'fighterName' != ''
    -- Update even if names match, to ensure consistency
);

-- Step 3: Update handles to match fighter names
UPDATE public.fighter_profiles fp
SET handle = LOWER(REPLACE(fp.name, ' ', '_'))
WHERE EXISTS (
    SELECT 1 
    FROM auth.users au 
    WHERE au.id = fp.user_id 
    AND au.raw_user_meta_data->>'fighterName' IS NOT NULL
    AND au.raw_user_meta_data->>'fighterName' != ''
);

-- Step 4: Verify the updates
SELECT 
    fp.id,
    fp.name as fighter_name,
    fp.handle,
    au.email,
    au.raw_user_meta_data->>'fighterName' as metadata_fighter_name
FROM public.fighter_profiles fp
JOIN auth.users au ON au.id = fp.user_id
WHERE au.raw_user_meta_data->>'fighterName' IS NOT NULL
  AND au.raw_user_meta_data->>'fighterName' != ''
ORDER BY fp.created_at DESC;

