-- Force update ALL fighter profiles to use fighterName from metadata
-- This ensures all fighters display their boxer/fighter name, not account name
-- Run this in Supabase SQL Editor

-- First, update all fighters who have fighterName in their metadata
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
);

-- Update handles to match the fighter names
UPDATE public.fighter_profiles fp
SET handle = LOWER(REPLACE(
    COALESCE(
        (SELECT au.raw_user_meta_data->>'fighterName' 
         FROM auth.users au 
         WHERE au.id = fp.user_id
         AND au.raw_user_meta_data->>'fighterName' IS NOT NULL
         AND au.raw_user_meta_data->>'fighterName' != ''),
        fp.name
    ),
    ' ', '_'
))
WHERE EXISTS (
    SELECT 1 
    FROM auth.users au 
    WHERE au.id = fp.user_id 
    AND au.raw_user_meta_data->>'fighterName' IS NOT NULL
    AND au.raw_user_meta_data->>'fighterName' != ''
);

-- Show results: List all fighters and their names
SELECT 
    fp.id,
    fp.name as fighter_name,
    fp.handle,
    au.email,
    au.raw_user_meta_data->>'fighterName' as metadata_fighter_name,
    au.raw_user_meta_data->>'name' as metadata_account_name
FROM public.fighter_profiles fp
JOIN auth.users au ON au.id = fp.user_id
ORDER BY fp.created_at DESC;

