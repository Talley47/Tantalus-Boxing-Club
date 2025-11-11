-- Fix fight_records method constraint to allow standard boxing method values
-- Run this in Supabase SQL Editor

-- Drop the existing method constraint if it exists
DO $$
BEGIN
    ALTER TABLE fight_records DROP CONSTRAINT IF EXISTS fight_records_method_check;
EXCEPTION
    WHEN undefined_object THEN NULL;
END $$;

-- Create method constraint with standard boxing method values
-- Frontend will normalize user input to these exact values
ALTER TABLE fight_records 
ADD CONSTRAINT fight_records_method_check 
CHECK (
    method IN (
        -- Standard abbreviations
        'UD', 'SD', 'MD', 'KO', 'TKO', 
        -- Full names (for flexibility)
        'Submission', 'DQ', 'No Contest', 'No Decision'
    )
);
