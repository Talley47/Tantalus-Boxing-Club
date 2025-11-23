-- Setup Supabase Storage bucket for championship belt images
-- IMPORTANT: First create the bucket in Supabase Dashboard > Storage
-- 1. Go to Storage in Supabase Dashboard
-- 2. Click "New bucket"
-- 3. Name: championship-belts
-- 4. Public bucket: Yes
-- 5. File size limit: 10MB
-- 6. Allowed MIME types: image/jpeg, image/jpg, image/png, image/gif, image/webp
-- Then run this script to set up the RLS policies

-- Drop existing policies if they exist
DO $$
BEGIN
    DROP POLICY IF EXISTS "Allow admins to upload championship belts" ON storage.objects;
    DROP POLICY IF EXISTS "Allow admins to update championship belts" ON storage.objects;
    DROP POLICY IF EXISTS "Allow admins to delete championship belts" ON storage.objects;
    DROP POLICY IF EXISTS "Allow public to read championship belts" ON storage.objects;
EXCEPTION
    WHEN undefined_object THEN NULL;
END $$;

-- Allow admins to upload to championship-belts bucket
CREATE POLICY "Allow admins to upload championship belts"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'championship-belts' AND
    EXISTS (
        SELECT 1 FROM public.profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role = 'admin'
    )
);

-- Allow admins to update championship belts
CREATE POLICY "Allow admins to update championship belts"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
    bucket_id = 'championship-belts' AND
    EXISTS (
        SELECT 1 FROM public.profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role = 'admin'
    )
)
WITH CHECK (
    bucket_id = 'championship-belts' AND
    EXISTS (
        SELECT 1 FROM public.profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role = 'admin'
    )
);

-- Allow admins to delete championship belts
CREATE POLICY "Allow admins to delete championship belts"
ON storage.objects
FOR DELETE
TO authenticated
USING (
    bucket_id = 'championship-belts' AND
    EXISTS (
        SELECT 1 FROM public.profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role = 'admin'
    )
);

-- Allow public to read championship belts (for display on fighter profiles)
CREATE POLICY "Allow public to read championship belts"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'championship-belts');

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✅ Championship belts storage policies created successfully!';
    RAISE NOTICE '   - Bucket: championship-belts';
    RAISE NOTICE '   - Admin upload/update/delete: Enabled';
    RAISE NOTICE '   - Public read: Enabled';
    RAISE NOTICE '';
    RAISE NOTICE '⚠️  Don''t forget to create the "championship-belts" bucket in Supabase Dashboard > Storage!';
END $$;

