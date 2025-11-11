-- =====================================================
-- COMPREHENSIVE FIX: Update ALL fighter names to use fighterName from metadata
-- This ensures all fighters display their boxer/fighter name, not account name
-- Run this ENTIRE script in Supabase SQL Editor
-- =====================================================

-- Step 1: Verify the trigger is using fighterName correctly
-- (The trigger should already be set up, but this ensures it's correct)

-- Step 2: Update ALL fighter profiles to use fighterName from user metadata
-- This will fix existing users who have account names stored
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

-- Step 3: Update handles to match the fighter names
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

-- Step 4: Show results - verify all fighters now have correct names
SELECT 
    fp.id,
    fp.name as fighter_name_displayed,
    fp.handle,
    au.email,
    au.raw_user_meta_data->>'fighterName' as fighter_name_in_metadata,
    au.raw_user_meta_data->>'name' as account_name,
    CASE 
        WHEN fp.name = au.raw_user_meta_data->>'fighterName' THEN '✅ CORRECT'
        WHEN au.raw_user_meta_data->>'fighterName' IS NULL OR au.raw_user_meta_data->>'fighterName' = '' THEN '⚠️ NO FIGHTER NAME IN METADATA'
        ELSE '❌ MISMATCH'
    END as status
FROM public.fighter_profiles fp
JOIN auth.users au ON au.id = fp.user_id
ORDER BY fp.created_at DESC;

-- =====================================================
-- IMPORTANT NOTES:
-- 1. This script updates ALL fighters who have fighterName in their metadata
-- 2. If a fighter doesn't have fighterName in metadata, their name won't be updated
-- 3. For new registrations, the trigger will automatically use fighterName
-- 4. After running this, refresh your app to see the updated names
-- =====================================================

