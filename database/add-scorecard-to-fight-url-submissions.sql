-- Add scorecard_url field to fight_url_submissions table
-- This allows fighters to upload scorecard screenshots along with fight URLs

-- Add the scorecard_url column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'fight_url_submissions' 
        AND column_name = 'scorecard_url'
    ) THEN
        ALTER TABLE fight_url_submissions 
        ADD COLUMN scorecard_url TEXT;
        
        -- Add comment for documentation
        COMMENT ON COLUMN fight_url_submissions.scorecard_url IS 'URL to the scorecard screenshot uploaded by the fighter';
    END IF;
END $$;

