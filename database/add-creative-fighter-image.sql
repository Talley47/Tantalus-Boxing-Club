-- Add creative_fighter_image_url field to fighter_profiles table
-- This allows fighters to upload a picture of their Creative Fighter

-- Add the creative_fighter_image_url column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'fighter_profiles' 
        AND column_name = 'creative_fighter_image_url'
    ) THEN
        ALTER TABLE fighter_profiles 
        ADD COLUMN creative_fighter_image_url TEXT;
        
        -- Add comment for documentation
        COMMENT ON COLUMN fighter_profiles.creative_fighter_image_url IS 'URL to the Creative Fighter image uploaded by the fighter';
    END IF;
END $$;

