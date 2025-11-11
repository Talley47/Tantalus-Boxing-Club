-- Add original_weight_class column to fighter_profiles table
-- This stores the weight class the fighter registered with
-- Fighters can move ±3 weight classes from their original

-- Add original_weight_class column if it doesn't exist
ALTER TABLE fighter_profiles 
ADD COLUMN IF NOT EXISTS original_weight_class TEXT;

-- Set original_weight_class for existing fighters (use current weight_class as original)
UPDATE fighter_profiles 
SET original_weight_class = weight_class 
WHERE original_weight_class IS NULL AND weight_class IS NOT NULL;

-- Add comment to explain the column
COMMENT ON COLUMN fighter_profiles.original_weight_class IS 
'Original weight class from registration. Fighters can move up or down 3 weight classes from this.';

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✅ original_weight_class column added to fighter_profiles table';
    RAISE NOTICE '✅ Existing fighters updated with their current weight class as original';
    RAISE NOTICE '';
    RAISE NOTICE 'Weight Class Movement Rules:';
    RAISE NOTICE '  - Fighters can move up or down 3 weight classes from their original';
    RAISE NOTICE '  - Example: If original is Welterweight, allowed range is:';
    RAISE NOTICE '    Lightweight → Welterweight → Middleweight → Light Heavyweight → Cruiserweight';
END $$;

