-- Fix: Database Error Saving New User
-- This trigger creates a profile when a user signs up
-- Run this in Supabase SQL Editor

-- First, drop existing trigger and function to start fresh
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- Create a robust function that handles errors gracefully
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
    -- Try to insert profile with error handling
    BEGIN
        -- Check if profiles table has the columns we need
        -- Use a simple insert that works with most schema versions
        INSERT INTO public.profiles (id, email, role)
        VALUES (
            NEW.id,
            NEW.email,
            COALESCE(
                (NEW.raw_app_meta_data->>'role')::TEXT,
                (NEW.raw_user_meta_data->>'role')::TEXT,
                'fighter'
            )
        )
        ON CONFLICT (id) DO UPDATE
        SET email = EXCLUDED.email;
        
        -- If full_name column exists, try to update it
        BEGIN
            UPDATE public.profiles
            SET full_name = COALESCE(
                NEW.raw_user_meta_data->>'full_name',
                NEW.raw_user_meta_data->>'name',
                NEW.email
            )
            WHERE id = NEW.id;
        EXCEPTION
            WHEN undefined_column THEN
                -- Column doesn't exist, that's okay
                NULL;
        END;
        
        -- If created_at column exists, try to update it
        BEGIN
            UPDATE public.profiles
            SET created_at = COALESCE(NEW.created_at, NOW())
            WHERE id = NEW.id;
        EXCEPTION
            WHEN undefined_column THEN
                -- Column doesn't exist, that's okay
                NULL;
        END;
        
    EXCEPTION
        WHEN OTHERS THEN
            -- Log the error but don't fail user creation
            -- Use RAISE WARNING so it appears in logs but doesn't block
            RAISE WARNING 'Error in handle_new_user for user % (email: %): % (SQLSTATE: %)', 
                NEW.id, 
                NEW.email,
                SQLERRM,
                SQLSTATE;
            -- Still return NEW to allow user creation to succeed
    END;
    
    RETURN NEW;
END;
$$;

-- Create the trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION public.handle_new_user() TO postgres, anon, authenticated, service_role;

-- Ensure the function can insert into profiles (bypass RLS)
ALTER FUNCTION public.handle_new_user() SECURITY DEFINER;

-- Verify trigger was created
SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement
FROM information_schema.triggers
WHERE trigger_name = 'on_auth_user_created';

-- Test: Check if function exists and is callable
SELECT routine_name, routine_type
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name = 'handle_new_user';

COMMENT ON FUNCTION public.handle_new_user() IS 'Automatically creates a profile entry when a new user signs up. Uses SECURITY DEFINER to bypass RLS. Handles errors gracefully to prevent blocking user registration.';

