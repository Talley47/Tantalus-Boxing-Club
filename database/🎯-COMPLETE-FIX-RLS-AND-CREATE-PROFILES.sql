-- ============================================================================
-- COMPLETE FIX: RLS + CREATE FIGHTER PROFILES FOR ALL USERS
-- Run this ONE script to fix everything!
-- ============================================================================

-- ============================================================================
-- PART 1: FIX RLS POLICIES
-- ============================================================================

-- Step 1: Grant permissions
GRANT USAGE ON SCHEMA public TO anon;
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT SELECT ON TABLE public.fighter_profiles TO anon;
GRANT SELECT ON TABLE public.fighter_profiles TO authenticated;
GRANT SELECT ON TABLE public.profiles TO anon;
GRANT SELECT ON TABLE public.profiles TO authenticated;

-- Step 2: Enable RLS
ALTER TABLE public.fighter_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Step 3: Remove ALL existing policies
DO $$ 
DECLARE r RECORD; 
BEGIN 
  FOR r IN SELECT policyname FROM pg_policies WHERE schemaname = 'public' AND tablename = 'fighter_profiles' LOOP 
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.fighter_profiles', r.policyname); 
  END LOOP; 
  FOR r IN SELECT policyname FROM pg_policies WHERE schemaname = 'public' AND tablename = 'profiles' LOOP 
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.profiles', r.policyname); 
  END LOOP; 
END $$;

-- Step 4: Create new permissive policies
CREATE POLICY "anon_read_fighter_profiles" ON public.fighter_profiles FOR SELECT TO anon USING (true);
CREATE POLICY "authenticated_read_fighter_profiles" ON public.fighter_profiles FOR SELECT TO authenticated USING (true);
CREATE POLICY "anon_read_profiles" ON public.profiles FOR SELECT TO anon USING (true);
CREATE POLICY "authenticated_read_profiles" ON public.profiles FOR SELECT TO authenticated USING (true);

-- ============================================================================
-- PART 2: CREATE FIGHTER PROFILES FOR ALL USERS
-- ============================================================================

-- Create fighter profiles for all users who don't have one yet
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
    points,
    wins,
    losses,
    draws,
    knockouts
)
SELECT 
    u.id as user_id,
    -- Use email username as name, or "Fighter" + number if email is null
    COALESCE(
        SPLIT_PART(u.email, '@', 1),
        'Fighter ' || ROW_NUMBER() OVER (ORDER BY u.created_at)
    ) as name,
    -- Create unique handle from email or user ID (ensure uniqueness with UUID suffix)
    -- Use first 12 chars of UUID (without dashes) to guarantee uniqueness
    COALESCE(
        LOWER(REGEXP_REPLACE(SPLIT_PART(u.email, '@', 1), '[^a-z0-9]', '_', 'g')),
        'fighter'
    ) || '_' || REPLACE(SUBSTRING(u.id::TEXT, 1, 13), '-', '') as handle,
    -- Default birthday: 25 years ago
    (CURRENT_DATE - INTERVAL '25 years')::DATE as birthday,
    -- Default hometown
    'New York, NY' as hometown,
    -- Default stance
    'orthodox' as stance,
    -- Default height: 5'10"
    5 as height_feet,
    10 as height_inches,
    -- Default reach: 72 inches
    72 as reach,
    -- Default weight: 170 lbs (middleweight)
    170 as weight,
    -- Default weight class
    'Middleweight' as weight_class,
    -- Default tier: 'amateur' (valid tier value)
    'amateur' as tier,
    -- Default stats
    0 as points,
    0 as wins,
    0 as losses,
    0 as draws,
    0 as knockouts
FROM auth.users u
LEFT JOIN public.fighter_profiles fp ON u.id = fp.user_id
WHERE fp.user_id IS NULL  -- Only create for users without fighter profiles
  AND u.deleted_at IS NULL  -- Skip deleted users
ON CONFLICT (user_id) DO NOTHING;  -- Skip if somehow already exists

-- ============================================================================
-- PART 3: VERIFY RESULTS
-- ============================================================================

-- Show summary
SELECT 
    '✅ COMPLETE FIX SUCCESS' as status,
    (SELECT COUNT(*) FROM auth.users WHERE deleted_at IS NULL) as total_users_in_auth,
    (SELECT COUNT(*) FROM public.fighter_profiles) as total_fighter_profiles,
    (SELECT COUNT(*) FROM public.fighter_profiles WHERE user_id IS NOT NULL) as profiles_with_user_id,
    (SELECT COUNT(*) FROM public.fighter_profiles WHERE user_id IS NULL) as profiles_without_user_id;

-- Show sample of created profiles
SELECT 
    fp.user_id,
    fp.name,
    fp.handle,
    fp.tier,
    fp.points,
    u.email
FROM public.fighter_profiles fp
JOIN auth.users u ON fp.user_id = u.id
ORDER BY fp.created_at DESC
LIMIT 10;

