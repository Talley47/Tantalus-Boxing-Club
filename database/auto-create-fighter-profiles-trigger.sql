-- Auto-create fighter_profiles when a user signs up with fighterName
-- This trigger ensures every new fighter gets a fighter profile automatically
-- Run this in Supabase SQL Editor

-- Create function to handle fighter profile creation after user signup
-- This runs AFTER auth.users INSERT, so we can access user metadata
CREATE OR REPLACE FUNCTION public.handle_new_fighter_profile_from_auth()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    fighter_name TEXT;
    fighter_birthday DATE;
    fighter_hometown TEXT;
    fighter_stance TEXT;
    fighter_platform TEXT;
    fighter_timezone TEXT;
    fighter_height_feet INTEGER;
    fighter_height_inches INTEGER;
    fighter_reach INTEGER;
    fighter_weight INTEGER;
    fighter_weight_class TEXT;
    fighter_trainer TEXT;
    fighter_gym TEXT;
BEGIN
    -- Only create fighter profile if user is a fighter (not admin)
    -- Check role from metadata
    IF COALESCE(
        (NEW.raw_app_meta_data->>'role')::TEXT,
        (NEW.raw_user_meta_data->>'role')::TEXT,
        'fighter'
    ) = 'fighter' THEN
        -- Extract fighter name (priority: fighterName only - do NOT use account name)
        -- The fighter name should always be provided during registration
        -- Check multiple possible field names for fighter name
        fighter_name := COALESCE(
            NULLIF(TRIM(NEW.raw_user_meta_data->>'fighterName'), ''),
            NULLIF(TRIM(NEW.raw_user_meta_data->>'fighter_name'), ''),
            NULLIF(TRIM(NEW.raw_user_meta_data->>'boxerName'), ''),
            NULLIF(TRIM(NEW.raw_user_meta_data->>'boxer_name'), ''),
            'Fighter'  -- Fallback only if fighterName is not provided (shouldn't happen)
        );
        
        -- Parse birthday
        IF NEW.raw_user_meta_data->>'birthday' IS NOT NULL THEN
            fighter_birthday := (NEW.raw_user_meta_data->>'birthday')::DATE;
        ELSE
            fighter_birthday := CURRENT_DATE - INTERVAL '25 years';
        END IF;
        
        -- Extract other fields
        fighter_hometown := COALESCE(NEW.raw_user_meta_data->>'hometown', 'Unknown');
        fighter_stance := COALESCE(
            LOWER(NEW.raw_user_meta_data->>'stance'),
            'orthodox'
        );
        -- Extract platform (default to 'PC' if not provided)
        -- The schema expects: 'PSN', 'Xbox', or 'PC'
        fighter_platform := COALESCE(
            NEW.raw_user_meta_data->>'platform',
            'PC'
        );
        -- Ensure platform is one of the valid values (schema: 'PSN', 'Xbox', 'PC')
        IF fighter_platform NOT IN ('PSN', 'Xbox', 'PC') THEN
            -- Try to normalize common variations
            IF UPPER(fighter_platform) IN ('XBOX', 'X-BOX') THEN
                fighter_platform := 'Xbox';
            ELSIF UPPER(fighter_platform) IN ('PSN', 'PLAYSTATION', 'PS4', 'PS5') THEN
                fighter_platform := 'PSN';
            ELSIF UPPER(fighter_platform) IN ('PC', 'STEAM', 'COMPUTER') THEN
                fighter_platform := 'PC';
            ELSE
                fighter_platform := 'PC'; -- Default fallback
            END IF;
        END IF;
        
        -- Extract timezone (default to 'UTC' if not provided)
        fighter_timezone := COALESCE(
            NEW.raw_user_meta_data->>'timezone',
            'UTC'
        );
        
        -- Parse height - use height_feet/height_inches from metadata if available
        IF NEW.raw_user_meta_data->>'height_feet' IS NOT NULL THEN
            fighter_height_feet := (NEW.raw_user_meta_data->>'height_feet')::INTEGER;
            fighter_height_inches := COALESCE((NEW.raw_user_meta_data->>'height_inches')::INTEGER, 0);
        ELSE
            -- Default height if not provided
            fighter_height_feet := 5;
            fighter_height_inches := 8;
        END IF;
        
        -- Parse reach (registration sends in cm, but we store in inches)
        IF NEW.raw_user_meta_data->>'reach' IS NOT NULL THEN
            -- If reach is in cm (from registration conversion), convert to inches
            fighter_reach := ROUND((NEW.raw_user_meta_data->>'reach')::NUMERIC / 2.54)::INTEGER;
        ELSE
            fighter_reach := 70;
        END IF;
        
        -- Parse weight (registration sends in kg, but we store in lbs)
        IF NEW.raw_user_meta_data->>'weight' IS NOT NULL THEN
            -- If weight is in kg (from registration conversion), convert to lbs
            fighter_weight := ROUND((NEW.raw_user_meta_data->>'weight')::NUMERIC / 0.453592)::INTEGER;
        ELSE
            fighter_weight := 150;
        END IF;
        
        fighter_weight_class := COALESCE(NEW.raw_user_meta_data->>'weightClass', 'Middleweight');
        fighter_trainer := NEW.raw_user_meta_data->>'trainer';
        fighter_gym := NEW.raw_user_meta_data->>'gym';
        
        -- Create fighter profile
        INSERT INTO public.fighter_profiles (
            user_id,
            name,
            handle,
            platform,
            platform_id,
            timezone,
            birthday,
            hometown,
            stance,
            height_feet,
            height_inches,
            reach,
            weight,
            weight_class,
            tier,
            trainer,
            gym,
            points,
            wins,
            losses,
            draws
        )
        VALUES (
            NEW.id,
            fighter_name,
            LOWER(REPLACE(fighter_name, ' ', '_')),
            fighter_platform,
            NEW.id::TEXT, -- Use user ID as platform_id initially
            fighter_timezone,
            fighter_birthday,
            fighter_hometown,
            fighter_stance,
            fighter_height_feet,
            fighter_height_inches,
            fighter_reach,
            fighter_weight,
            fighter_weight_class,
            'amateur',
            fighter_trainer,
            fighter_gym,
            0,
            0,
            0,
            0
        )
        ON CONFLICT (user_id) DO NOTHING;
    END IF;
  
    RETURN NEW;
END;
$$;

-- Create trigger on auth.users to create fighter profile after user signup
DROP TRIGGER IF EXISTS on_auth_user_created_fighter ON auth.users;

CREATE TRIGGER on_auth_user_created_fighter
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_fighter_profile_from_auth();

COMMENT ON FUNCTION public.handle_new_fighter_profile_from_auth() IS 'Automatically creates a fighter_profiles entry when a new fighter signs up';

