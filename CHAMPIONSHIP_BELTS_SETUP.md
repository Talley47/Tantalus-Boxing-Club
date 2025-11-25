# Championship Belts Feature Setup Guide

## Prerequisites
Before using the Championship Belts feature, you need to set up the database and storage bucket.

## Step 1: Create the Database Table

1. Go to your Supabase Dashboard: https://supabase.com/dashboard
2. Select your project
3. Navigate to **SQL Editor** (left sidebar)
4. Open the file: `tantalus-boxing-club/database/create-championship-belts-table.sql`
5. Copy the entire contents of the file
6. Paste it into the SQL Editor
7. Click **Run** (or press Ctrl+Enter)
8. You should see a success message: "✅ Championship belts table created successfully!"

## Step 2: Create the Storage Bucket

1. In Supabase Dashboard, navigate to **Storage** (left sidebar)
2. Click **New bucket** button (top right)
3. Configure the bucket:
   - **Name**: `championship-belts` (must be exactly this name)
   - **Public bucket**: ✅ **Yes** (check this box - important!)
   - **File size limit**: `10` MB
   - **Allowed MIME types**: 
     ```
     image/jpeg, image/jpg, image/png, image/gif, image/webp
     ```
4. Click **Create bucket**

## Step 3: Set Up Storage Policies

1. Go back to **SQL Editor** in Supabase Dashboard
2. Open the file: `tantalus-boxing-club/database/setup-championship-belts-storage.sql`
3. Copy the entire contents of the file
4. Paste it into the SQL Editor
5. Click **Run** (or press Ctrl+Enter)
6. You should see a success message: "✅ Championship belts storage policies created successfully!"

## Step 4: Verify Setup

After completing all steps, you should be able to:

1. Go to the Admin Panel in your app
2. Click **Manage Championship Belts**
3. Select a fighter
4. Choose a governing body
5. Upload a belt image
6. The image should upload successfully without errors

## Troubleshooting

### Error: "Bucket not found"
- Make sure you created the bucket with the exact name: `championship-belts`
- Verify the bucket is set to **Public**

### Error: "Storage bucket RLS policy error"
- Make sure you ran the `setup-championship-belts-storage.sql` script
- Check that your user has admin role in the `profiles` table

### Error: "Permission denied"
- Verify you're logged in as an admin user
- Check that the RLS policies were created successfully

### Images not displaying
- Ensure the bucket is set to **Public**
- Check that the image URLs are accessible (try opening them in a new tab)

## Governing Bodies Supported

The following championship belts can be assigned:

1. **TBA Tantalus Boxing Amateur Association** (TBA_AMATEUR)
2. **TBA Tantalus Boxing Association** (TBA_ASSOCIATION)
3. **TBC Tantalus Boxing Council** (TBC_COUNCIL)
4. **TBF Tantalus Boxing Federation** (TBF_FEDERATION)
5. **TBO Tantalus Boxing Organization** (TBO_WORLD)
6. **Tantalus Ring Magazine** (RING_MAGAZINE)

## Notes

- Each fighter can have **one belt per governing body** (enforced by database constraint)
- Belt images are stored in Supabase Storage
- Images are publicly accessible for display on fighter profiles
- Only admins can upload, assign, and delete championship belts

