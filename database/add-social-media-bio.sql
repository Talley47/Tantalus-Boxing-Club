-- Add social media bio field to fighter_profiles table
-- This allows fighters to add a bio for their Tantalus Ring Magazine Media profile

-- Add social_media_bio column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'fighter_profiles' 
        AND column_name = 'social_media_bio'
    ) THEN
        ALTER TABLE fighter_profiles 
        ADD COLUMN social_media_bio TEXT;
        
        RAISE NOTICE '✅ Added social_media_bio column to fighter_profiles';
    ELSE
        RAISE NOTICE '✅ social_media_bio column already exists';
    END IF;
END $$;

-- Success message
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '✅ Social media bio field added successfully!';
    RAISE NOTICE '   Fighters can now add a bio for their Tantalus Ring Magazine Media profile.';
    RAISE NOTICE '';
END $$;

