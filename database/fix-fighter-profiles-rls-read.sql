-- Fix RLS policies for fighter_profiles to allow public/authenticated read access
-- This will allow the app to display fighters on the Home page, Rankings, etc.

-- 1. Enable RLS (if not already enabled)
ALTER TABLE fighter_profiles ENABLE ROW LEVEL SECURITY;

-- 2. Drop existing read policies that might be blocking
DROP POLICY IF EXISTS "Public can view all fighter profiles" ON fighter_profiles;
DROP POLICY IF EXISTS "Anyone can view fighter profiles" ON fighter_profiles;
DROP POLICY IF EXISTS "Public read access" ON fighter_profiles;
DROP POLICY IF EXISTS "Users can view all fighter profiles" ON fighter_profiles;
DROP POLICY IF EXISTS "Authenticated users can view all fighter profiles" ON fighter_profiles;

-- 3. Create a public read policy (allows anyone to read fighter profiles)
CREATE POLICY "Public can view all fighter profiles" ON fighter_profiles
    FOR SELECT
    USING (true);  -- Allow anyone to read all fighter profiles

-- 4. Verify the policy was created
DO $$
DECLARE
    policy_exists BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'fighter_profiles' 
        AND policyname = 'Public can view all fighter profiles'
    ) INTO policy_exists;
    
    IF policy_exists THEN
        RAISE NOTICE '✅ Successfully created public read policy for fighter_profiles';
    ELSE
        RAISE WARNING '❌ Failed to create policy';
    END IF;
END $$;

-- 5. Also ensure fight_records can be read (for rankings, analytics)
ALTER TABLE fight_records ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public can view fight records" ON fight_records;
DROP POLICY IF EXISTS "Anyone can view fight records" ON fight_records;

CREATE POLICY "Public can view fight records" ON fight_records
    FOR SELECT
    USING (true);

-- 6. Also ensure scheduled_fights can be read
ALTER TABLE scheduled_fights ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public can view scheduled fights" ON scheduled_fights;
DROP POLICY IF EXISTS "Anyone can view scheduled fights" ON scheduled_fights;

CREATE POLICY "Public can view scheduled fights" ON scheduled_fights
    FOR SELECT
    USING (true);

-- 7. Test query (should return data if fighters exist)
SELECT 
    COUNT(*) as total_fighters,
    COUNT(DISTINCT weight_class) as unique_weight_classes
FROM fighter_profiles
WHERE user_id IS NOT NULL;

-- 8. Show sample data
SELECT 
    user_id,
    name,
    handle,
    tier,
    points,
    weight_class,
    wins,
    losses
FROM fighter_profiles
WHERE user_id IS NOT NULL
ORDER BY points DESC
LIMIT 5;

