-- Setup Supabase Storage bucket for fight submissions (scorecards)
-- IMPORTANT: First create the bucket in Supabase Dashboard > Storage
-- 1. Go to Storage in Supabase Dashboard
-- 2. Click "New bucket"
-- 3. Name: fight-submissions
-- 4. Public bucket: Yes
-- 5. File size limit: 10MB
-- 6. Allowed MIME types: image/jpeg, image/jpg, image/png, image/gif, image/webp
-- Then run this script to set up the RLS policies

-- Drop existing policies if they exist
DO $$
BEGIN
    DROP POLICY IF EXISTS "Allow authenticated to upload to fight-submissions" ON storage.objects;
    DROP POLICY IF EXISTS "Allow authenticated to update fight-submissions" ON storage.objects;
    DROP POLICY IF EXISTS "Allow authenticated to delete fight-submissions" ON storage.objects;
    DROP POLICY IF EXISTS "Allow public to read fight-submissions" ON storage.objects;
    DROP POLICY IF EXISTS "Fighters can upload scorecards" ON storage.objects;
    DROP POLICY IF EXISTS "Fighters can view their own scorecards" ON storage.objects;
    DROP POLICY IF EXISTS "Public can view scorecards" ON storage.objects;
    DROP POLICY IF EXISTS "Admins can view all scorecards" ON storage.objects;
    DROP POLICY IF EXISTS "Admins can delete scorecards" ON storage.objects;
EXCEPTION
    WHEN undefined_object THEN NULL;
END $$;

-- Allow authenticated users to upload to fight-submissions bucket
-- Path structure: {fighter_id}/{filename}
CREATE POLICY "Allow authenticated to upload to fight-submissions"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'fight-submissions');

-- Allow authenticated users to update their own uploads
CREATE POLICY "Allow authenticated to update fight-submissions"
ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'fight-submissions')
WITH CHECK (bucket_id = 'fight-submissions');

-- Allow authenticated users to delete their own uploads
CREATE POLICY "Allow authenticated to delete fight-submissions"
ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'fight-submissions');

-- Allow public read access (for displaying scorecards in admin panel and fighter profiles)
CREATE POLICY "Allow public to read fight-submissions"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'fight-submissions');

