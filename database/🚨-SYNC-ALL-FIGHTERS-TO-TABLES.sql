-- ============================================================================
-- 🚨 SYNC ALL FIGHTERS TO RELATED TABLES
-- ============================================================================
-- This script ensures data consistency between `fighter_profiles` and `profiles`
-- tables, which is critical for authentication, RLS, and admin checks.
-- It will:
-- 1. Identify fighters in `fighter_profiles` that do NOT have a corresponding
--    entry in `public.profiles`.
-- 2. Create missing `public.profiles` entries for these fighters.
-- 3. Update existing `public.profiles` entries to ensure `full_name` and `email`
--    match `fighter_profiles.name` and `auth.users.email`.
-- 4. Provide verification queries.
--
-- Note: Other tables like `fight_records`, `scheduled_fights`, `championship_belts`
-- etc., are typically populated by user actions or specific business logic,
-- not by a general "import all fighters" script. This script focuses on
-- the core `fighter_profiles` <-> `profiles` relationship.
-- ============================================================================
-- Copy ALL of this into Supabase SQL Editor and run it
-- ============================================================================

DO $$
DECLARE
  fighter_rec RECORD;
  auth_email TEXT;
  created_count INTEGER := 0;
  updated_count INTEGER := 0;
BEGIN
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '🚨 STARTING FIGHTER TO PROFILE SYNC';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '';

  -- Step 1: Iterate through all fighter_profiles
  FOR fighter_rec IN
    SELECT fp.id as fighter_profile_id, fp.user_id, fp.name, au.email
    FROM public.fighter_profiles fp
    JOIN auth.users au ON fp.user_id = au.id
  LOOP
    -- Check if a corresponding profile exists
    IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = fighter_rec.user_id) THEN
      -- Create a new profile entry
      INSERT INTO public.profiles (id, email, full_name, role)
      VALUES (fighter_rec.user_id, fighter_rec.email, fighter_rec.name, 'fighter');
      RAISE NOTICE '  ✅ Created profile for fighter: % (User ID: %)', fighter_rec.name, fighter_rec.user_id;
      created_count := created_count + 1;
    ELSE
      -- Update existing profile to ensure consistency
      UPDATE public.profiles
      SET
        email = fighter_rec.email,
        full_name = fighter_rec.name,
        updated_at = NOW()
      WHERE id = fighter_rec.user_id
        AND (email IS DISTINCT FROM fighter_rec.email OR full_name IS DISTINCT FROM fighter_rec.name);
      
      IF FOUND THEN
        RAISE NOTICE '  🔄 Updated profile for fighter: % (User ID: %)', fighter_rec.name, fighter_rec.user_id;
        updated_count := updated_count + 1;
      END IF;
    END IF;
  END LOOP;

  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '📊 SYNC SUMMARY:';
  RAISE NOTICE '  Total fighters processed: %', (SELECT COUNT(*) FROM public.fighter_profiles);
  RAISE NOTICE '  New profiles created: %', created_count;
  RAISE NOTICE '  Existing profiles updated: %', updated_count;
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '✅ FIGHTER TO PROFILE SYNC COMPLETE';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '  All fighters in fighter_profiles should now have corresponding entries in public.profiles.';
  RAISE NOTICE '  This resolves potential issues with authentication and role-based access checks.';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';

EXCEPTION WHEN OTHERS THEN
  RAISE WARNING '❌ CRITICAL ERROR during fighter to profile sync: %', SQLERRM;
  RAISE;
END $$;

-- ============================================================================
-- VERIFICATION: Check sync status (run outside DO block to display results)
-- ============================================================================

-- Verify all fighter_profiles have a corresponding profile entry
SELECT
  'Verification 1: Fighters without Profiles' as check_type,
  COUNT(fp.user_id) as fighters_missing_profiles,
  array_agg(fp.name) FILTER (WHERE p.id IS NULL) as missing_fighter_names
FROM public.fighter_profiles fp
LEFT JOIN public.profiles p ON fp.user_id = p.id
WHERE p.id IS NULL;

-- Verify profile data matches (sample)
SELECT
  'Verification 2: Sample Profile Data' as check_type,
  fp.name as fighter_name,
  p.full_name as profile_full_name,
  p.email as profile_email,
  p.role as profile_role,
  CASE
    WHEN fp.name = p.full_name AND au.email = p.email THEN '✅ Synced'
    ELSE '❌ Mismatch'
  END as sync_status
FROM public.fighter_profiles fp
JOIN public.profiles p ON fp.user_id = p.id
JOIN auth.users au ON fp.user_id = au.id
LIMIT 5;

-- ============================================================================
-- INFORMATIONAL: Other tables referencing fighter_profiles
-- ============================================================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE 'ℹ️  INFORMATIONAL: Tables referencing fighter_profiles';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
END $$;

SELECT
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM
    information_schema.table_constraints AS tc
    JOIN information_schema.key_column_usage AS kcu
      ON tc.constraint_name = kcu.constraint_name
      AND tc.table_schema = kcu.table_schema
    JOIN information_schema.constraint_column_usage AS ccu
      ON ccu.constraint_name = tc.constraint_name
      AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND ccu.table_name = 'fighter_profiles'
  AND tc.table_schema = 'public';

DO $$
BEGIN
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  RAISE NOTICE '  These tables typically get populated through application logic (e.g., when a fight is scheduled, a belt is awarded, etc.).';
  RAISE NOTICE '  They are not automatically "synced" by importing fighters, but rather link to existing fighter_profiles entries.';
  RAISE NOTICE '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
END $$;

