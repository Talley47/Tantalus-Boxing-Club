# How to Verify the Storage Bucket Exists

## Quick Check

1. Go to **Supabase Dashboard** → **Storage**
2. Look for a bucket named: `championship-belts`
3. It should show as **"Public"**

## If You Don't See It

The bucket doesn't exist yet. You need to create it.

## Step-by-Step Creation

### 1. Open Supabase Dashboard
- URL: https://supabase.com/dashboard
- Select your project

### 2. Go to Storage
- Click **"Storage"** in the left sidebar (folder icon)

### 3. Create New Bucket
- Click **"New bucket"** button (top right, usually green)

### 4. Fill in the Form

**Bucket Name:**
```
championship-belts
```
⚠️ Must be exactly this: lowercase, with hyphen, no spaces

**Public bucket:**
☑️ **CHECK THIS BOX** (very important!)

**File size limit:**
```
10
```
(Unit: MB)

**Allowed MIME types:**
```
image/jpeg, image/jpg, image/png, image/gif, image/webp
```

### 5. Create
- Click **"Create bucket"** button

### 6. Verify It Was Created
- You should see `championship-belts` in the buckets list
- Status should show as **"Public"**

### 7. Run Storage Policies
1. Go to **SQL Editor**
2. Open: `database/setup-championship-belts-storage.sql`
3. Copy all contents
4. Paste into SQL Editor
5. Click **"Run"**

### 8. Test Upload
- Go back to your app
- Try uploading a championship belt image
- It should work now! ✅

## Common Mistakes

❌ **Wrong bucket name:**
- `Championship-Belts` (capital letters)
- `championship_belts` (underscore instead of hyphen)
- `championship belts` (space instead of hyphen)
- `championshipbelts` (no hyphen)

✅ **Correct:** `championship-belts`

❌ **Bucket is Private**
- Must be set to **Public** for images to display

❌ **Forgot to run SQL policies**
- Must run `setup-championship-belts-storage.sql` after creating bucket

## Still Having Issues?

1. **Check you're in the correct Supabase project**
   - Your project URL should be: `andmtvsqqomgwphotdwf.supabase.co`

2. **Refresh your browser** after creating the bucket

3. **Check bucket permissions**
   - Go to Storage → championship-belts → Policies
   - Should see policies for admin upload/delete and public read

4. **Verify you're logged in as admin**
   - Check your user role in the `profiles` table

