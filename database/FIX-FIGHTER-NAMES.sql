-- ============================================================================
-- FIX FIGHTER NAMES FROM METADATA
-- ============================================================================
-- This script updates fighter_profiles.name to use fighterName from metadata
-- Run DIAGNOSE-FIGHTER-NAMES.sql first to see what needs fixing
-- ============================================================================

-- Step 1: Update fighters who have fighterName in metadata but wrong name in profile
UPDATE public.fighter_profiles fp
SET name = (
    SELECT au.raw_user_meta_data->>'fighterName' 
    FROM auth.users au 
    WHERE au.id = fp.user_id
    AND au.raw_user_meta_data->>'fighterName' IS NOT NULL
    AND TRIM(au.raw_user_meta_data->>'fighterName') != ''
)
WHERE EXISTS (
    SELECT 1 
    FROM auth.users au 
    WHERE au.id = fp.user_id 
    AND au.raw_user_meta_data->>'fighterName' IS NOT NULL
    AND TRIM(au.raw_user_meta_data->>'fighterName') != ''
    AND (
        -- Update if name is NULL, empty, or doesn't match fighterName
        fp.name IS NULL 
        OR TRIM(fp.name) = ''
        OR fp.name != au.raw_user_meta_data->>'fighterName'
    )
);

-- Step 2: Update handles to match the new fighter names
UPDATE public.fighter_profiles fp
SET handle = LOWER(REPLACE(
    REGEXP_REPLACE(
        COALESCE(
            (SELECT au.raw_user_meta_data->>'fighterName' 
             FROM auth.users au 
             WHERE au.id = fp.user_id
             AND au.raw_user_meta_data->>'fighterName' IS NOT NULL
             AND TRIM(au.raw_user_meta_data->>'fighterName') != ''),
            fp.name
        ),
        '[^a-zA-Z0-9 ]', '', 'g'
    ),
    ' ', '_'
))
WHERE EXISTS (
    SELECT 1 
    FROM auth.users au 
    WHERE au.id = fp.user_id 
    AND au.raw_user_meta_data->>'fighterName' IS NOT NULL
    AND TRIM(au.raw_user_meta_data->>'fighterName') != ''
);

-- Step 3: Verify the fix
SELECT 
  'Step 3: Verification - After Fix' as step,
  fp.id,
  fp.user_id,
  fp.name as profile_name,
  fp.handle,
  au.email,
  au.raw_user_meta_data->>'fighterName' as metadata_fighter_name,
  CASE 
    WHEN fp.name IS NULL OR TRIM(fp.name) = '' THEN '❌ STILL MISSING'
    WHEN au.raw_user_meta_data->>'fighterName' IS NOT NULL 
         AND fp.name = au.raw_user_meta_data->>'fighterName' THEN '✅ FIXED'
    WHEN au.raw_user_meta_data->>'fighterName' IS NULL THEN '⚠️ NO METADATA (using profile name)'
    ELSE '⚠️ STILL MISMATCHED'
  END as status
FROM public.fighter_profiles fp
JOIN auth.users au ON au.id = fp.user_id
ORDER BY fp.created_at DESC;

-- ============================================================================
-- ✅ DONE!
-- ============================================================================
-- After running this:
-- 1. Hard refresh your browser (Ctrl+Shift+R)
-- 2. Fighter names should now display correctly
-- ============================================================================
