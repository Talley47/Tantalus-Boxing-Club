-- ============================================================================
-- DIAGNOSE FIGHTER NAME ISSUES
-- ============================================================================
-- This script checks:
-- 1. Which fighters have NULL or empty names
-- 2. What names are currently stored
-- 3. What fighterName is in user metadata
-- 4. Whether names need to be updated from metadata
-- ============================================================================

-- Step 1: Check fighters with NULL or empty names
SELECT 
  'Step 1: Fighters with NULL or Empty Names' as step,
  fp.id,
  fp.user_id,
  fp.name as current_name,
  fp.handle,
  au.email,
  CASE 
    WHEN fp.name IS NULL THEN 'NULL'
    WHEN TRIM(fp.name) = '' THEN 'EMPTY'
    ELSE 'OK'
  END as name_status
FROM public.fighter_profiles fp
JOIN auth.users au ON au.id = fp.user_id
WHERE fp.name IS NULL OR TRIM(fp.name) = ''
ORDER BY fp.created_at DESC;

-- Step 2: Show all fighters and their names vs metadata
SELECT 
  'Step 2: All Fighters - Name Comparison' as step,
  fp.id,
  fp.user_id,
  fp.name as profile_name,
  fp.handle,
  au.email,
  au.raw_user_meta_data->>'fighterName' as metadata_fighter_name,
  au.raw_user_meta_data->>'name' as metadata_account_name,
  CASE 
    WHEN fp.name IS NULL OR TRIM(fp.name) = '' THEN '❌ MISSING'
    WHEN au.raw_user_meta_data->>'fighterName' IS NOT NULL 
         AND fp.name != au.raw_user_meta_data->>'fighterName' THEN '⚠️ MISMATCH'
    WHEN fp.name = SPLIT_PART(au.email, '@', 1) THEN '⚠️ USING EMAIL (should use fighterName)'
    ELSE '✅ OK'
  END as status
FROM public.fighter_profiles fp
JOIN auth.users au ON au.id = fp.user_id
ORDER BY 
  CASE 
    WHEN fp.name IS NULL OR TRIM(fp.name) = '' THEN 1
    WHEN au.raw_user_meta_data->>'fighterName' IS NOT NULL 
         AND fp.name != au.raw_user_meta_data->>'fighterName' THEN 2
    WHEN fp.name = SPLIT_PART(au.email, '@', 1) THEN 3
    ELSE 4
  END,
  fp.created_at DESC;

-- Step 3: Count issues
SELECT 
  'Step 3: Summary' as step,
  COUNT(*) as total_fighters,
  COUNT(CASE WHEN fp.name IS NULL OR TRIM(fp.name) = '' THEN 1 END) as missing_names,
  COUNT(CASE 
    WHEN au.raw_user_meta_data->>'fighterName' IS NOT NULL 
         AND fp.name != au.raw_user_meta_data->>'fighterName' THEN 1 
  END) as mismatched_names,
  COUNT(CASE 
    WHEN fp.name = SPLIT_PART(au.email, '@', 1) 
         AND au.raw_user_meta_data->>'fighterName' IS NOT NULL THEN 1 
  END) as using_email_instead_of_fighter_name
FROM public.fighter_profiles fp
JOIN auth.users au ON au.id = fp.user_id;

-- ============================================================================
-- NEXT STEP: If you see issues, run FIX-FIGHTER-NAMES.sql
-- ============================================================================
