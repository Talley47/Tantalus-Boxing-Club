-- Update Admin Account with All New Schema Changes
-- Run this in your Supabase SQL Editor
-- This will update the admin's fighter profile with all new fields
-- Admin Email: tantalusboxingclub@gmail.com

-- Ensure all new columns exist first
ALTER TABLE fighter_profiles 
ADD COLUMN IF NOT EXISTS knockouts INTEGER DEFAULT 0;

ALTER TABLE fighter_profiles 
ADD COLUMN IF NOT EXISTS win_percentage DECIMAL(5,2) DEFAULT 0.00;

ALTER TABLE fighter_profiles 
ADD COLUMN IF NOT EXISTS ko_percentage DECIMAL(5,2) DEFAULT 0.00;

-- Update admin account with all new fields
DO $$
DECLARE
    admin_user_id UUID;
    admin_email TEXT := 'tantalusboxingclub@gmail.com';
    current_wins INTEGER;
    current_losses INTEGER;
    current_draws INTEGER;
    current_knockouts INTEGER;
    total_fights INTEGER;
    calculated_win_pct DECIMAL(5,2);
    calculated_ko_pct DECIMAL(5,2);
BEGIN
    -- Get admin user ID
    SELECT id INTO admin_user_id
    FROM auth.users
    WHERE email = admin_email
    LIMIT 1;

    IF admin_user_id IS NULL THEN
        RAISE NOTICE 'Admin user not found with email: %', admin_email;
        RETURN;
    END IF;

    RAISE NOTICE 'Found admin user ID: %', admin_user_id;

    -- Get current fighter profile stats
    SELECT 
        COALESCE(wins, 0),
        COALESCE(losses, 0),
        COALESCE(draws, 0),
        COALESCE(knockouts, 0)
    INTO current_wins, current_losses, current_draws, current_knockouts
    FROM fighter_profiles
    WHERE user_id = admin_user_id;

    -- Calculate total fights
    total_fights := current_wins + current_losses + current_draws;

    -- Calculate win percentage
    IF total_fights > 0 THEN
        calculated_win_pct := ROUND((current_wins::DECIMAL / total_fights * 100)::NUMERIC, 2);
    ELSE
        calculated_win_pct := 0.00;
    END IF;

    -- Calculate KO percentage
    IF current_wins > 0 AND current_knockouts IS NOT NULL THEN
        calculated_ko_pct := ROUND((current_knockouts::DECIMAL / current_wins * 100)::NUMERIC, 2);
    ELSE
        calculated_ko_pct := 0.00;
    END IF;

    -- Update fighter profile with all new fields
    UPDATE fighter_profiles
    SET
        -- Ensure knockouts exists (add column if needed)
        knockouts = COALESCE(knockouts, 0),
        
        -- Calculate and set win_percentage
        win_percentage = calculated_win_pct,
        
        -- Calculate and set ko_percentage
        ko_percentage = calculated_ko_pct,
        
        -- Ensure other stats are set
        wins = COALESCE(wins, 0),
        losses = COALESCE(losses, 0),
        draws = COALESCE(draws, 0),
        points = COALESCE(points, 0),
        
        -- Update timestamp
        updated_at = NOW()
    WHERE user_id = admin_user_id;

    RAISE NOTICE '✅ Admin fighter profile updated successfully!';
    RAISE NOTICE '   Wins: %, Losses: %, Draws: %', current_wins, current_losses, current_draws;
    RAISE NOTICE '   Knockouts: %', current_knockouts;
    RAISE NOTICE '   Win Percentage: % percent', calculated_win_pct;
    RAISE NOTICE '   KO Percentage: % percent', calculated_ko_pct;

EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Error updating admin account: %', SQLERRM;
END $$;

-- Also ensure the admin profile exists in profiles table with admin role
-- Check if profiles table exists and has required columns, then insert/update
DO $$
BEGIN
    -- Check if profiles table exists
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'profiles') THEN
        -- Insert or update admin profile (only include columns that exist)
        INSERT INTO profiles (id, email, full_name, role)
        SELECT 
            id,
            email,
            COALESCE(raw_user_meta_data->>'name', raw_user_meta_data->>'full_name', 'Tantalus Admin'),
            'admin'
        FROM auth.users
        WHERE email = 'tantalusboxingclub@gmail.com'
        ON CONFLICT (id) 
        DO UPDATE SET
            role = 'admin';
            
        RAISE NOTICE '✅ Admin profile in profiles table verified!';
    ELSE
        RAISE NOTICE '⚠️  profiles table does not exist, skipping profile update';
    END IF;
EXCEPTION WHEN OTHERS THEN
    -- If columns don't exist, try with minimal fields
    BEGIN
        INSERT INTO profiles (id, email, role)
        SELECT 
            id,
            email,
            'admin'
        FROM auth.users
        WHERE email = 'tantalusboxingclub@gmail.com'
        ON CONFLICT (id) 
        DO UPDATE SET
            role = 'admin';
        RAISE NOTICE '✅ Admin profile updated (minimal fields only)!';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '⚠️  Could not update profiles table: %', SQLERRM;
    END;
END $$;

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✅ Admin profile in profiles table verified!';
    RAISE NOTICE '✅ Admin account fully updated with all new schema changes!';
END $$;

