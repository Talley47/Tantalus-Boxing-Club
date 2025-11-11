-- =====================================================
-- COMPLETE WORKING SCHEMA FOR TANTALUS BOXING CLUB
-- Run this ENTIRE file in Supabase SQL Editor
-- It will create all tables needed for the app to work
-- =====================================================

-- Drop existing tables if they exist (clean start)
DROP TABLE IF EXISTS public.fighter_profiles CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;

-- Create profiles table
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT,
    role TEXT DEFAULT 'fighter',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create fighter_profiles table with ALL required columns
CREATE TABLE public.fighter_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID UNIQUE NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    handle TEXT UNIQUE NOT NULL,
    birthday DATE NOT NULL,
    hometown TEXT NOT NULL,
    stance TEXT NOT NULL CHECK (stance IN ('orthodox', 'southpaw', 'switch')),
    
    -- Physical attributes (stored in imperial units as entered)
    height_feet INTEGER NOT NULL,
    height_inches INTEGER NOT NULL,
    reach INTEGER NOT NULL,
    weight INTEGER NOT NULL,
    weight_class TEXT NOT NULL,
    
    -- Training info
    trainer TEXT,
    gym TEXT,
    
    -- Stats and records
    tier TEXT DEFAULT 'bronze' CHECK (tier IN ('bronze', 'silver', 'gold', 'platinum', 'diamond', 'amateur', 'semi-pro', 'pro', 'contender', 'elite', 'champion')),
    points INTEGER DEFAULT 0,
    wins INTEGER DEFAULT 0,
    losses INTEGER DEFAULT 0,
    draws INTEGER DEFAULT 0,
    knockouts INTEGER DEFAULT 0,
    
    -- Calculated stats
    win_percentage DECIMAL(5,2) DEFAULT 0.00,
    ko_percentage DECIMAL(5,2) DEFAULT 0.00,
    current_streak INTEGER DEFAULT 0,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    last_active TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fighter_profiles ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (make script idempotent)
DO $$
BEGIN
    DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
    DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
    DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
    DROP POLICY IF EXISTS "Admins can view all profiles" ON public.profiles;
    DROP POLICY IF EXISTS "Admins can update all profiles" ON public.profiles;
    DROP POLICY IF EXISTS "Admin can view all profiles" ON public.profiles;
    DROP POLICY IF EXISTS "Admin can update all profiles" ON public.profiles;
    DROP POLICY IF EXISTS "Admin can delete profiles" ON public.profiles;
EXCEPTION
    WHEN undefined_object THEN NULL;
END $$;

-- RLS Policies for profiles
CREATE POLICY "Users can view own profile" 
    ON public.profiles FOR SELECT 
    USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" 
    ON public.profiles FOR UPDATE 
    USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" 
    ON public.profiles FOR INSERT 
    WITH CHECK (auth.uid() = id);

-- Drop existing fighter_profiles policies if they exist
DO $$
BEGIN
    DROP POLICY IF EXISTS "Users can view own fighter profile" ON public.fighter_profiles;
    DROP POLICY IF EXISTS "Users can insert own fighter profile" ON public.fighter_profiles;
    DROP POLICY IF EXISTS "Users can update own fighter profile" ON public.fighter_profiles;
    DROP POLICY IF EXISTS "Public can view all fighter profiles" ON public.fighter_profiles;
    DROP POLICY IF EXISTS "Public can view fighter profiles" ON public.fighter_profiles;
    DROP POLICY IF EXISTS "Admins can manage fighter profiles" ON public.fighter_profiles;
EXCEPTION
    WHEN undefined_object THEN NULL;
END $$;

-- RLS Policies for fighter_profiles
CREATE POLICY "Users can view own fighter profile" 
    ON public.fighter_profiles FOR SELECT 
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own fighter profile" 
    ON public.fighter_profiles FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own fighter profile" 
    ON public.fighter_profiles FOR UPDATE 
    USING (auth.uid() = user_id);

-- Public can view all fighter profiles (for rankings)
CREATE POLICY "Public can view all fighter profiles" 
    ON public.fighter_profiles FOR SELECT 
    USING (true);

-- Create indexes for performance
CREATE INDEX idx_profiles_email ON public.profiles(email);
CREATE INDEX idx_profiles_role ON public.profiles(role);
CREATE INDEX idx_fighter_profiles_user_id ON public.fighter_profiles(user_id);
CREATE INDEX idx_fighter_profiles_tier ON public.fighter_profiles(tier);
CREATE INDEX idx_fighter_profiles_points ON public.fighter_profiles(points DESC);
CREATE INDEX idx_fighter_profiles_weight_class ON public.fighter_profiles(weight_class);

-- Success message
DO $$
BEGIN
    RAISE NOTICE '═══════════════════════════════════════';
    RAISE NOTICE '✅ DATABASE SCHEMA CREATED SUCCESSFULLY!';
    RAISE NOTICE '═══════════════════════════════════════';
    RAISE NOTICE '';
    RAISE NOTICE 'Tables created:';
    RAISE NOTICE '  ✅ profiles (with email, full_name, role)';
    RAISE NOTICE '  ✅ fighter_profiles (with all required columns)';
    RAISE NOTICE '';
    RAISE NOTICE 'RLS Policies enabled:';
    RAISE NOTICE '  ✅ Users can manage their own data';
    RAISE NOTICE '  ✅ Public can view fighter profiles';
    RAISE NOTICE '';
    RAISE NOTICE 'Next steps:';
    RAISE NOTICE '  1. Run: node create-admin-proper.js';
    RAISE NOTICE '  2. Go to: http://localhost:3005';
    RAISE NOTICE '  3. Login with: tantalusboxingclub@gmail.com';
    RAISE NOTICE '  4. Test registration flow';
    RAISE NOTICE '';
    RAISE NOTICE '🎉 You can now use the app!';
    RAISE NOTICE '═══════════════════════════════════════';
END $$;


