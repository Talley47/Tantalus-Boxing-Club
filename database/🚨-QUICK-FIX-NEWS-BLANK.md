# Quick Fix: News & Announcements Blank

## Problem
News and Announcements section shows "No news or announcements at the moment" even though admin can see posts.

## Root Cause
RLS (Row Level Security) policies are likely blocking authenticated users from reading news items.

## Solution Steps

### Step 1: Run Diagnostic Script
Run `🔍-DIAGNOSE-NEWS-ISSUE.sql` in Supabase SQL Editor to check:
- ✅ Do news items exist?
- ✅ Are they published (`is_published = TRUE`)?
- ✅ Are RLS policies correct?

### Step 2: Run Fix Script
Run `🔧-FIX-NEWS-RLS-FOR-AUTHENTICATED.sql` in Supabase SQL Editor.

This will:
1. Check current RLS policies
2. Drop all existing SELECT policies
3. Create policy for `anon` role (unauthenticated users)
4. Create policy for `authenticated` role (logged-in users) ← **THIS IS THE KEY FIX**
5. Verify policies are correct

### Step 3: Check Browser Console
After refreshing the page, open browser console (F12) and look for:
- `🔐 Auth status for news query:` - Shows if user is authenticated
- `📰 News query result:` - Shows how many items were fetched
- `✅ After filtering:` - Shows how many published items remain
- `❌ Error fetching news items:` - Shows any errors

### Step 4: Verify News Items Are Published
1. Login as Admin
2. Go to Admin Panel → News Management
3. Check that news items have "Published" toggle ON
4. If not, edit each news item and turn ON the "Published" toggle

## Expected Console Output (After Fix)

**If working correctly:**
```
🔐 Auth status for news query: { isAuthenticated: true, userId: '...' }
📰 News query result: { totalFetched: 5, publishedCount: 5, ... }
✅ After filtering: { totalPublished: 5, willReturn: 5 }
```

**If RLS is blocking:**
```
❌ Error fetching news items: { code: '42501', message: 'permission denied...' }
🚫 RLS Policy Error - User may not have permission to read news_announcements
```

**If items are unpublished:**
```
📰 News query result: { totalFetched: 5, publishedCount: 0, unpublishedCount: 5 }
✅ After filtering: { totalPublished: 0, willReturn: 0 }
```

## Still Not Working?

1. **Check if you ran the SQL scripts** - They must be run in Supabase SQL Editor
2. **Check browser console** - Look for the diagnostic messages above
3. **Verify news items exist** - Run the diagnostic SQL script
4. **Check RLS is enabled** - The diagnostic script will show this
5. **Try logging out and back in** - Sometimes auth state needs refresh

## Common Issues

### Issue: "No policies found"
- **Solution**: RLS might be disabled. The fix script will re-enable it.

### Issue: "Permission denied"
- **Solution**: Run the fix script to add the `authenticated` role policy.

### Issue: "Items fetched but filtered out"
- **Solution**: Check that `is_published = TRUE` in the database. Use Admin Panel to publish items.

### Issue: "Query returns 0 items"
- **Solution**: Either no news items exist, or RLS is blocking. Run diagnostic script to check.

