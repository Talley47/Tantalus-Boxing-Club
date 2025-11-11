-- Auto-create profiles when users sign up
-- This trigger ensures every auth.users entry has a corresponding profiles entry
-- Run this in Supabase SQL Editor

-- Create function to handle new user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    has_created_at BOOLEAN;
    has_full_name BOOLEAN;
    has_updated_at BOOLEAN;
BEGIN
    -- Check which columns exist
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'profiles' 
        AND column_name = 'created_at'
    ) INTO has_created_at;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'profiles' 
        AND column_name = 'full_name'
    ) INTO has_full_name;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'profiles' 
        AND column_name = 'updated_at'
    ) INTO has_updated_at;

    -- Build dynamic INSERT based on existing columns
    IF has_created_at AND has_full_name AND has_updated_at THEN
        INSERT INTO public.profiles (id, email, full_name, role, created_at, updated_at)
        VALUES (
          NEW.id,
          NEW.email,
          COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', ''),
          COALESCE((NEW.raw_app_meta_data->>'role')::TEXT, (NEW.raw_user_meta_data->>'role')::TEXT, 'fighter'),
          NEW.created_at,
          NOW()
        )
        ON CONFLICT (id) DO UPDATE
        SET 
          email = EXCLUDED.email,
          updated_at = NOW();
    ELSIF has_created_at AND has_full_name THEN
        INSERT INTO public.profiles (id, email, full_name, role, created_at)
        VALUES (
          NEW.id,
          NEW.email,
          COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', ''),
          COALESCE((NEW.raw_app_meta_data->>'role')::TEXT, (NEW.raw_user_meta_data->>'role')::TEXT, 'fighter'),
          NEW.created_at
        )
        ON CONFLICT (id) DO UPDATE
        SET email = EXCLUDED.email;
    ELSIF has_full_name THEN
        INSERT INTO public.profiles (id, email, full_name, role)
        VALUES (
          NEW.id,
          NEW.email,
          COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', ''),
          COALESCE((NEW.raw_app_meta_data->>'role')::TEXT, 'fighter')
        )
        ON CONFLICT (id) DO UPDATE
        SET email = EXCLUDED.email;
    ELSE
        -- Minimal insert - just id, email, role
        INSERT INTO public.profiles (id, email, role)
        VALUES (
          NEW.id,
          NEW.email,
          COALESCE((NEW.raw_app_meta_data->>'role')::TEXT, 'fighter')
        )
        ON CONFLICT (id) DO UPDATE
        SET email = EXCLUDED.email;
    END IF;
  
  RETURN NEW;
END;
$$;

-- Create trigger to call function on new user creation
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- Also create a function to sync last_sign_in_at
CREATE OR REPLACE FUNCTION public.handle_user_signin()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    has_last_sign_in_at BOOLEAN;
    has_updated_at BOOLEAN;
BEGIN
    -- Check if columns exist
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'profiles' 
        AND column_name = 'last_sign_in_at'
    ) INTO has_last_sign_in_at;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'profiles' 
        AND column_name = 'updated_at'
    ) INTO has_updated_at;

    -- Update profiles based on what columns exist
    IF has_last_sign_in_at AND has_updated_at THEN
        UPDATE public.profiles
        SET last_sign_in_at = NEW.last_sign_in_at,
            updated_at = NOW()
        WHERE id = NEW.id;
    ELSIF has_last_sign_in_at THEN
        UPDATE public.profiles
        SET last_sign_in_at = NEW.last_sign_in_at
        WHERE id = NEW.id;
    ELSIF has_updated_at THEN
        UPDATE public.profiles
        SET updated_at = NOW()
        WHERE id = NEW.id;
    END IF;
  
  RETURN NEW;
END;
$$;

-- Create trigger for sign-in updates
DROP TRIGGER IF EXISTS on_auth_user_signin ON auth.users;

CREATE TRIGGER on_auth_user_signin
  AFTER UPDATE OF last_sign_in_at ON auth.users
  FOR EACH ROW
  WHEN (OLD.last_sign_in_at IS DISTINCT FROM NEW.last_sign_in_at)
  EXECUTE FUNCTION public.handle_user_signin();

-- Backfill existing users: Create profiles for any existing auth.users without profiles
-- First check which columns exist in profiles table
DO $$
DECLARE
    has_created_at BOOLEAN;
    has_is_active BOOLEAN;
    has_full_name BOOLEAN;
BEGIN
    -- Check if created_at column exists
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'profiles' 
        AND column_name = 'created_at'
    ) INTO has_created_at;

    -- Check if is_active column exists
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'profiles' 
        AND column_name = 'is_active'
    ) INTO has_is_active;

    -- Check if full_name column exists
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'profiles' 
        AND column_name = 'full_name'
    ) INTO has_full_name;

    -- Backfill users with columns that exist
    IF has_created_at AND has_is_active AND has_full_name THEN
        -- All columns exist
        INSERT INTO public.profiles (id, email, full_name, role, created_at, is_active)
        SELECT 
          u.id,
          u.email,
          COALESCE(u.raw_user_meta_data->>'full_name', u.raw_user_meta_data->>'name', ''),
          COALESCE((u.raw_app_meta_data->>'role')::TEXT, 'fighter'),
          u.created_at,
          TRUE
        FROM auth.users u
        WHERE NOT EXISTS (
          SELECT 1 FROM public.profiles p WHERE p.id = u.id
        )
        ON CONFLICT (id) DO NOTHING;
    ELSIF has_created_at AND has_full_name THEN
        -- created_at and full_name exist, but not is_active
        INSERT INTO public.profiles (id, email, full_name, role, created_at)
        SELECT 
          u.id,
          u.email,
          COALESCE(u.raw_user_meta_data->>'full_name', u.raw_user_meta_data->>'name', ''),
          COALESCE((u.raw_app_meta_data->>'role')::TEXT, 'fighter'),
          u.created_at
        FROM auth.users u
        WHERE NOT EXISTS (
          SELECT 1 FROM public.profiles p WHERE p.id = u.id
        )
        ON CONFLICT (id) DO NOTHING;
    ELSIF has_full_name THEN
        -- Only full_name exists
        INSERT INTO public.profiles (id, email, full_name, role)
        SELECT 
          u.id,
          u.email,
          COALESCE(u.raw_user_meta_data->>'full_name', u.raw_user_meta_data->>'name', ''),
          COALESCE((u.raw_app_meta_data->>'role')::TEXT, 'fighter')
        FROM auth.users u
        WHERE NOT EXISTS (
          SELECT 1 FROM public.profiles p WHERE p.id = u.id
        )
        ON CONFLICT (id) DO NOTHING;
    ELSE
        -- Minimal columns only
        INSERT INTO public.profiles (id, email, role)
        SELECT 
          u.id,
          u.email,
          COALESCE((u.raw_app_meta_data->>'role')::TEXT, 'fighter')
        FROM auth.users u
        WHERE NOT EXISTS (
          SELECT 1 FROM public.profiles p WHERE p.id = u.id
        )
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT INSERT, UPDATE ON public.profiles TO authenticated;

COMMENT ON FUNCTION public.handle_new_user() IS 'Automatically creates a profile entry when a new user signs up';
COMMENT ON FUNCTION public.handle_user_signin() IS 'Syncs last_sign_in_at from auth.users to profiles';

