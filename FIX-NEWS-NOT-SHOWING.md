# Fix: News & Announcements Not Showing on Home Page

## Issue
The "News & Announcements" tab is visible but shows "No news or announcements at the moment."

## Possible Causes

1. **No news items exist in database**
   - Admin hasn't created any news items yet
   - Solution: Create news items in Admin Panel

2. **News items are unpublished**
   - News items exist but have `is_published = FALSE`
   - Solution: Publish news items or set `is_published = TRUE`

3. **RLS policies blocking access**
   - Row Level Security policies are preventing read access
   - Solution: Run RLS fix script

4. **Missing `is_published` column**
   - Column doesn't exist in database
   - Solution: Run schema migration

5. **Query errors being silently caught**
   - Errors are being caught and returning empty array
   - Solution: Check browser console for errors

## Diagnostic Steps

### Step 1: Run Diagnostic Script
Run `database/DIAGNOSE-NEWS-ITEMS.sql` in Supabase SQL Editor to check:
- How many news items exist
- How many are published
- RLS policy status
- Column existence

### Step 2: Check Browser Console
1. Open browser Developer Tools (F12)
2. Go to Console tab
3. Look for errors related to:
   - `news_announcements`
   - `NewsService`
   - `getNewsItems`
   - RLS policy errors

### Step 3: Verify News Items Exist
1. Login as Admin
2. Go to Admin Panel → Content Management → News Management
3. Check if any news items exist
4. If they exist, check if "Published" toggle is ON

## Solutions

### Solution 1: Create News Items (If None Exist)
1. Login as Admin
2. Go to Admin Panel → Content Management → News Management
3. Click "Create News"
4. Fill in:
   - Title
   - Content
   - Type (news, announcement, blog, fight_result)
   - Make sure "Published" toggle is ON
5. Click "Save"

### Solution 2: Publish Existing News Items
1. Login as Admin
2. Go to Admin Panel → Content Management → News Management
3. Find unpublished news items
4. Click "Edit"
5. Turn ON "Published" toggle
6. Click "Save"

### Solution 3: Fix RLS Policies
Run one of these scripts in Supabase SQL Editor:
- `database/fix-news-rls-policy.sql` (Recommended)
- `database/FIX-NEWS-500-ERROR-SIMPLE.sql` (Simpler version)

### Solution 4: Fix Missing Column
If `is_published` column doesn't exist:
```sql
ALTER TABLE news_announcements 
ADD COLUMN IF NOT EXISTS is_published BOOLEAN DEFAULT TRUE;
```

### Solution 5: Check for Query Errors
1. Open browser Developer Tools (F12)
2. Go to Network tab
3. Filter by "news"
4. Look for failed requests
5. Check error messages in response

## Expected Behavior After Fix

1. ✅ News items appear in "News & Announcements" tab
2. ✅ News items are displayed with:
   - Title
   - Content
   - Author
   - Date
   - Type badge
   - Priority badge
   - Featured image (if available)
   - Emoji reactions

## Testing

1. **Create a test news item:**
   - Login as Admin
   - Create a news item with title "Test News"
   - Make sure it's published
   - Save

2. **Verify it appears:**
   - Login as a fighter
   - Go to Home Page
   - Click "News & Announcements" tab
   - Should see "Test News" item

3. **Check notification:**
   - After creating news, fighter should receive notification
   - Notification bell should show badge
   - Clicking notification should navigate to News tab

## Files Modified

- `src/services/newsService.ts` - Added better error logging
- `src/components/HomePage/HomePage.tsx` - Added debug logging for news loading

## Next Steps

1. Run `database/DIAGNOSE-NEWS-ITEMS.sql` to identify the issue
2. Follow the appropriate solution based on diagnostic results
3. Test by creating a news item and verifying it appears
4. Check browser console for any remaining errors

