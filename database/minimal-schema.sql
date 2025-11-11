-- MINIMAL SCHEMA - Just enough to make the app load
-- Run this in Supabase SQL Editor to get the app working

-- Create profiles table
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT,
    role TEXT DEFAULT 'fighter',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create fighter_profiles table
CREATE TABLE IF NOT EXISTS public.fighter_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    handle TEXT UNIQUE,
    birthday DATE,
    hometown TEXT,
    stance TEXT CHECK (stance IN ('orthodox', 'southpaw', 'switch')),
    height_feet INTEGER,
    height_inches INTEGER,
    reach INTEGER,
    weight INTEGER,
    weight_class TEXT,
    trainer TEXT,
    gym TEXT,
    tier TEXT DEFAULT 'bronze',
    points INTEGER DEFAULT 0,
    wins INTEGER DEFAULT 0,
    losses INTEGER DEFAULT 0,
    draws INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fighter_profiles ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (make script idempotent)
DO $$
BEGIN
    DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
    DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
    DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
    DROP POLICY IF EXISTS "Users can view own fighter profile" ON public.fighter_profiles;
    DROP POLICY IF EXISTS "Users can update own fighter profile" ON public.fighter_profiles;
    DROP POLICY IF EXISTS "Users can insert own fighter profile" ON public.fighter_profiles;
    DROP POLICY IF EXISTS "Public can view fighter profiles" ON public.fighter_profiles;
EXCEPTION
    WHEN undefined_object THEN NULL;
END $$;

-- Basic RLS policies
CREATE POLICY "Users can view own profile" ON public.profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON public.profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can view own fighter profile" ON public.fighter_profiles
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own fighter profile" ON public.fighter_profiles
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own fighter profile" ON public.fighter_profiles
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Public read for rankings
CREATE POLICY "Public can view fighter profiles" ON public.fighter_profiles
    FOR SELECT USING (true);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles(email);
CREATE INDEX IF NOT EXISTS idx_fighter_profiles_user_id ON public.fighter_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_fighter_profiles_tier ON public.fighter_profiles(tier);
CREATE INDEX IF NOT EXISTS idx_fighter_profiles_points ON public.fighter_profiles(points DESC);

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✅ Minimal schema created successfully!';
    RAISE NOTICE '✅ You can now login to the app';
    RAISE NOTICE '🚀 Next: Run create-admin-proper.js to create admin profile';
END $$;


