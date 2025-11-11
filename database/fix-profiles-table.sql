-- Fix profiles table to add missing columns
-- Run this in Supabase SQL Editor

-- First, check what columns exist
DO $$
BEGIN
    RAISE NOTICE 'Checking existing profiles table structure...';
END $$;

-- Add missing columns to profiles table if they don't exist
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS email TEXT,
ADD COLUMN IF NOT EXISTS full_name TEXT,
ADD COLUMN IF NOT EXISTS role TEXT DEFAULT 'fighter',
ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW(),
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- Add unique constraint on email if not exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'profiles_email_key'
    ) THEN
        ALTER TABLE public.profiles ADD CONSTRAINT profiles_email_key UNIQUE (email);
    END IF;
END $$;

-- Update existing profile with email if it's NULL
UPDATE public.profiles 
SET email = (SELECT email FROM auth.users WHERE id = profiles.id),
    updated_at = NOW()
WHERE email IS NULL;

-- Fix fighter_profiles table columns
ALTER TABLE public.fighter_profiles
ADD COLUMN IF NOT EXISTS height_feet INTEGER,
ADD COLUMN IF NOT EXISTS height_inches INTEGER,
ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW(),
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✅ profiles table fixed!';
    RAISE NOTICE '✅ email, full_name, role columns added';
    RAISE NOTICE '✅ fighter_profiles table updated';
    RAISE NOTICE '🚀 Run: node create-admin-proper.js to create admin profile';
END $$;


