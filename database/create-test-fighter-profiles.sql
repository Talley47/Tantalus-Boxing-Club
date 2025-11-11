-- Create test fighter profiles for development
-- WARNING: This creates test data. Run in Supabase SQL Editor only if you want test data.

-- First, check if you have users to create profiles for
DO $$
DECLARE
    user_count INTEGER;
    first_user_id UUID;
BEGIN
    -- Count users
    SELECT COUNT(*) INTO user_count FROM auth.users;
    
    IF user_count = 0 THEN
        RAISE EXCEPTION 'No users found! Please register/create accounts first through the app.';
    END IF;
    
    -- Get first user ID
    SELECT id INTO first_user_id FROM auth.users ORDER BY created_at ASC LIMIT 1;
    
    RAISE NOTICE 'Found % users. Creating test fighter profiles...', user_count;
    
    -- Create fighter profiles for existing users who don't have one
    -- Include all required NOT NULL fields with default values
    INSERT INTO fighter_profiles (
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
        draws
    )
    SELECT 
        u.id,
        COALESCE(u.raw_user_meta_data->>'full_name', split_part(u.email, '@', 1)) || ' Fighter',
        COALESCE(u.raw_user_meta_data->>'handle', 'fighter_' || substr(u.id::text, 1, 8)),
        (CURRENT_DATE - INTERVAL '25 years' - (random() * INTERVAL '10 years'))::DATE, -- Random birthday 18-35 years ago
        'Unknown', -- Default hometown
        CASE floor(random() * 3)::INTEGER
            WHEN 0 THEN 'orthodox'
            WHEN 1 THEN 'southpaw'
            ELSE 'switch'
        END, -- Random stance
        5 + floor(random() * 2)::INTEGER, -- Random height: 5-7 feet
        floor(random() * 12)::INTEGER, -- Random inches: 0-11
        70 + floor(random() * 10)::INTEGER, -- Random reach: 70-79 inches
        150 + floor(random() * 50)::INTEGER, -- Random weight: 150-199 lbs
        'Middleweight', -- Default weight class
        'bronze', -- Default tier (valid values: bronze, silver, gold, platinum, diamond, amateur, semi-pro, pro, contender, elite, champion)
        floor(random() * 500)::INTEGER, -- Random points between 0-500
        floor(random() * 10)::INTEGER, -- Random wins 0-10
        floor(random() * 5)::INTEGER, -- Random losses 0-5
        floor(random() * 2)::INTEGER -- Random draws 0-2
    FROM auth.users u
    WHERE NOT EXISTS (
        SELECT 1 FROM fighter_profiles fp WHERE fp.user_id = u.id
    )
    ON CONFLICT (user_id) DO NOTHING;
    
    RAISE NOTICE 'Test fighter profiles created successfully!';
END $$;

-- Verify creation
SELECT 
    COUNT(*) as total_fighters_created,
    AVG(points)::INTEGER as avg_points,
    SUM(wins) as total_wins
FROM fighter_profiles;

-- Show created profiles
SELECT 
    name,
    handle,
    weight_class,
    tier,
    points,
    wins,
    losses,
    draws
FROM fighter_profiles
ORDER BY points DESC;

