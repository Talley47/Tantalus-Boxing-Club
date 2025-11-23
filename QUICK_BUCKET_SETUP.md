# 🚨 URGENT: Create Storage Bucket

## The Error You're Seeing
```
Error: Storage bucket "championship-belts" not found
```

This means the storage bucket hasn't been created yet in Supabase.

## ⚡ Quick Fix (2 minutes)

### Step 1: Open Supabase Dashboard
1. Go to: **https://supabase.com/dashboard**
2. Click on your project (the one with URL: `andmtvsqqomgwphotdwf.supabase.co`)

### Step 2: Navigate to Storage
1. In the left sidebar, click **"Storage"** (it has a folder icon)
2. You should see a list of buckets (might be empty)

### Step 3: Create the Bucket
1. Click the **"New bucket"** button (usually top right, green button)
2. A dialog/form will appear

### Step 4: Fill in the Form
**IMPORTANT: Copy these EXACT values:**

- **Name**: `championship-belts`
  - ⚠️ Must be exactly this: lowercase, with hyphen, no spaces
  
- **Public bucket**: ✅ **CHECK THIS BOX** (very important!)
  - This allows images to be displayed on fighter profiles

- **File size limit**: `10`
  - Unit: MB (megabytes)

- **Allowed MIME types**: 
  ```
  image/jpeg, image/jpg, image/png, image/gif, image/webp
  ```
  - Copy and paste this exact text

### Step 5: Create
1. Click **"Create bucket"** button
2. You should see the bucket appear in the list

### Step 6: Verify
- Look for `championship-belts` in your Storage buckets list
- It should show as **"Public"** (not Private)

### Step 7: Run Storage Policies SQL
1. Go to **SQL Editor** in Supabase Dashboard
2. Open file: `tantalus-boxing-club/database/setup-championship-belts-storage.sql`
3. Copy all contents
4. Paste into SQL Editor
5. Click **"Run"** (or press Ctrl+Enter)

### Step 8: Test
1. Refresh your app
2. Try uploading a championship belt image again
3. It should work now! ✅

## Still Not Working?

### Check These:
1. ✅ Bucket name is exactly: `championship-belts` (no typos)
2. ✅ Bucket is set to **Public** (not Private)
3. ✅ You ran the `setup-championship-belts-storage.sql` script
4. ✅ You're logged in as an admin user
5. ✅ Refresh your browser after creating the bucket

### Visual Guide:
```
Supabase Dashboard
├── Storage (click here)
│   ├── [List of buckets]
│   └── [+ New bucket] ← Click this
│       ├── Name: championship-belts
│       ├── ☑️ Public bucket
│       ├── File size: 10 MB
│       └── MIME types: image/jpeg, image/jpg, image/png, image/gif, image/webp
```

## Need Help?
If you're still stuck, check:
- The bucket appears in your Storage list
- The bucket shows "Public" status
- You have admin permissions in your Supabase project

