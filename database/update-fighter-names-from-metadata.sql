-- Update fighter_profiles.name to use fighterName from user metadata if available
-- This fixes existing users who may have the account name instead of fighter name
-- Run this in Supabase SQL Editor

-- Update ALL fighter profiles to use fighterName from auth.users metadata if it exists
-- This ensures all fighters display their boxer/fighter name, not their account name
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
    -- Update if fighterName exists, regardless of current name
    -- This ensures all fighters get their correct fighter name
);

-- Also update handle to match the new fighter name for all updated profiles
UPDATE public.fighter_profiles fp
SET handle = LOWER(REPLACE(fp.name, ' ', '_'))
WHERE EXISTS (
    SELECT 1 
    FROM auth.users au 
    WHERE au.id = fp.user_id 
    AND au.raw_user_meta_data->>'fighterName' IS NOT NULL
    AND au.raw_user_meta_data->>'fighterName' != ''
);

COMMENT ON FUNCTION public.handle_new_fighter_profile_from_auth() IS 'Automatically creates a fighter_profiles entry when a new fighter signs up. Uses fighterName from metadata, not account name.';

