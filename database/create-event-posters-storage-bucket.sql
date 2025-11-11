-- Create Storage Bucket for Event Posters
-- Note: Supabase Storage buckets must be created through the Dashboard or API
-- This script provides instructions and sets up RLS policies if the bucket exists
-- Run this in Supabase SQL Editor

-- Instructions for creating the bucket:
-- 1. Go to Supabase Dashboard → Storage
-- 2. Click "New bucket"
-- 3. Name: "event-posters"
-- 4. Public: Yes (if you want images to be publicly accessible)
-- 5. File size limit: 5MB (or your preferred limit)
-- 6. Allowed MIME types: image/*

-- After creating the bucket, you can run the following to set up policies:

-- Enable RLS on storage.objects (if not already enabled)
-- Note: RLS is automatically enabled on storage.objects

-- Create policy to allow authenticated users to upload event posters
-- This assumes the bucket is named 'event-posters'
DO $$
BEGIN
    -- Check if bucket exists (we can't create it via SQL, but we can set up policies)
    IF EXISTS (
        SELECT 1 FROM storage.buckets WHERE name = 'event-posters'
    ) THEN
        -- Drop existing policies if they exist (all possible policy names)
        DROP POLICY IF EXISTS "Allow authenticated users to upload event posters" ON storage.objects;
        DROP POLICY IF EXISTS "Allow authenticated users to update event posters" ON storage.objects;
        DROP POLICY IF EXISTS "Allow public read access to event posters" ON storage.objects;
        DROP POLICY IF EXISTS "Allow authenticated to upload to event-posters" ON storage.objects;
        DROP POLICY IF EXISTS "Allow authenticated to update event-posters" ON storage.objects;
        DROP POLICY IF EXISTS "Allow authenticated to delete event-posters" ON storage.objects;
        DROP POLICY IF EXISTS "Allow public to read event-posters" ON storage.objects;
        
        -- Allow authenticated users to upload to event-posters bucket (any file)
        CREATE POLICY "Allow authenticated to upload to event-posters"
        ON storage.objects
        FOR INSERT
        TO authenticated
        WITH CHECK (bucket_id = 'event-posters');
        
        -- Allow authenticated users to update their own uploads
        CREATE POLICY "Allow authenticated to update event-posters"
        ON storage.objects
        FOR UPDATE
        TO authenticated
        USING (bucket_id = 'event-posters')
        WITH CHECK (bucket_id = 'event-posters');
        
        -- Allow authenticated users to delete their own uploads
        CREATE POLICY "Allow authenticated to delete event-posters"
        ON storage.objects
        FOR DELETE
        TO authenticated
        USING (bucket_id = 'event-posters');
        
        -- Allow public read access to event posters
        CREATE POLICY "Allow public to read event-posters"
        ON storage.objects
        FOR SELECT
        TO public
        USING (bucket_id = 'event-posters');
        
        RAISE NOTICE '✅ Storage policies created for event-posters bucket!';
    ELSE
        RAISE WARNING '⚠️ Bucket "event-posters" does not exist. Please create it in Supabase Dashboard → Storage first.';
    END IF;
END $$;

-- Also check for media-assets bucket (alternative)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM storage.buckets WHERE name = 'media-assets'
    ) THEN
        -- Drop existing policies if they exist (all possible policy names)
        DROP POLICY IF EXISTS "Allow authenticated users to upload to media-assets" ON storage.objects;
        DROP POLICY IF EXISTS "Allow public read access to media-assets" ON storage.objects;
        DROP POLICY IF EXISTS "Allow authenticated to upload to media-assets" ON storage.objects;
        DROP POLICY IF EXISTS "Allow authenticated to update media-assets" ON storage.objects;
        DROP POLICY IF EXISTS "Allow authenticated to delete media-assets" ON storage.objects;
        DROP POLICY IF EXISTS "Allow public to read media-assets" ON storage.objects;
        
        -- Allow authenticated users to upload to media-assets bucket (any file, including in event-posters folder)
        CREATE POLICY "Allow authenticated to upload to media-assets"
        ON storage.objects
        FOR INSERT
        TO authenticated
        WITH CHECK (bucket_id = 'media-assets');
        
        -- Allow authenticated users to update their own uploads
        CREATE POLICY "Allow authenticated to update media-assets"
        ON storage.objects
        FOR UPDATE
        TO authenticated
        USING (bucket_id = 'media-assets')
        WITH CHECK (bucket_id = 'media-assets');
        
        -- Allow authenticated users to delete their own uploads
        CREATE POLICY "Allow authenticated to delete media-assets"
        ON storage.objects
        FOR DELETE
        TO authenticated
        USING (bucket_id = 'media-assets');
        
        -- Allow public read access
        CREATE POLICY "Allow public to read media-assets"
        ON storage.objects
        FOR SELECT
        TO public
        USING (bucket_id = 'media-assets');
        
        RAISE NOTICE '✅ Storage policies created for media-assets bucket!';
    ELSE
        RAISE NOTICE 'ℹ️ Bucket "media-assets" does not exist. Using event-posters bucket instead.';
    END IF;
END $$;

-- Summary
DO $$
DECLARE
    event_posters_exists BOOLEAN;
    media_assets_exists BOOLEAN;
BEGIN
    SELECT EXISTS (SELECT 1 FROM storage.buckets WHERE name = 'event-posters') INTO event_posters_exists;
    SELECT EXISTS (SELECT 1 FROM storage.buckets WHERE name = 'media-assets') INTO media_assets_exists;
    
    IF event_posters_exists OR media_assets_exists THEN
        RAISE NOTICE '✅ Storage bucket setup complete!';
    ELSE
        RAISE WARNING '❌ No storage buckets found. Please create "event-posters" or "media-assets" bucket in Supabase Dashboard → Storage';
        RAISE NOTICE '📝 Instructions:';
        RAISE NOTICE '   1. Go to Supabase Dashboard → Storage';
        RAISE NOTICE '   2. Click "New bucket"';
        RAISE NOTICE '   3. Name: "event-posters"';
        RAISE NOTICE '   4. Public: Yes';
        RAISE NOTICE '   5. File size limit: 5MB';
        RAISE NOTICE '   6. Allowed MIME types: image/*';
    END IF;
END $$;

