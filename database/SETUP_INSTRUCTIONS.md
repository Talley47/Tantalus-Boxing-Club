# Database Setup Instructions

## ⚠️ Current Issues

1. **News Announcements Timeout (500 Error)** - Query is timing out
2. **Boxing Sanctions Not Working** - Fighters can't join sanctions

## 🔧 Quick Fix - Run These Scripts in Order

### Step 1: Fix News Announcements Timeout

Run this script in Supabase SQL Editor:

```sql
-- File: database/QUICK_FIX_NEWS_TIMEOUT.sql
```

**What it does:**
- Creates optimized indexes for the news query
- Fixes the timeout error
- Should make news load instantly

### Step 2: Create Fighter Sanctions Table

Run this script in Supabase SQL Editor:

```sql
-- File: database/create-fighter-sanctions-table.sql
```

**What it does:**
- Creates the `fighter_sanctions` table
- Sets up RLS policies
- Enables fighters to join/leave sanctions

### Step 3: Verify Setup

Run this script to check everything is set up correctly:

```sql
-- File: database/check-fighter-sanctions-setup.sql
```

## 📋 Step-by-Step Instructions

1. **Open Supabase Dashboard**
   - Go to your Supabase project
   - Click on "SQL Editor" in the left sidebar

2. **Fix News Timeout**
   - Open `database/QUICK_FIX_NEWS_TIMEOUT.sql`
   - Copy the entire contents
   - Paste into SQL Editor
   - Click "Run" or press Ctrl+Enter
   - Wait for success message

3. **Create Sanctions Table**
   - Open `database/create-fighter-sanctions-table.sql`
   - Copy the entire contents
   - Paste into SQL Editor
   - Click "Run" or press Ctrl+Enter
   - Wait for success message

4. **Verify**
   - Open `database/check-fighter-sanctions-setup.sql`
   - Copy and run it
   - Check the output - should show ✅ for all items

5. **Test in App**
   - Refresh your browser
   - News should load without timeout
   - Try joining a sanction - should work now

## 🐛 Troubleshooting

### News Still Timing Out?
- Make sure you ran `QUICK_FIX_NEWS_TIMEOUT.sql`
- Check if indexes were created: Run `SELECT indexname FROM pg_indexes WHERE tablename = 'news_announcements';`
- If indexes exist but still timing out, the table might be very large - consider archiving old news

### Sanctions Still Not Working?
- Verify table exists: Run `SELECT * FROM information_schema.tables WHERE table_name = 'fighter_sanctions';`
- Check RLS policies: Run the check script
- Check browser console for specific error messages
- Make sure you're logged in as a fighter (not admin)

### Permission Errors?
- Make sure RLS policies were created
- Check that your user has a fighter profile
- Verify you're authenticated (logged in)

## ✅ Success Indicators

After running the scripts, you should see:
- ✅ News loads quickly without timeout
- ✅ Join buttons are enabled (not grayed out)
- ✅ Can successfully join a sanction
- ✅ Can view fighters in a sanction
- ✅ No console errors

## 📞 Still Having Issues?

If problems persist after running all scripts:
1. Check browser console for specific error messages
2. Check Supabase logs for database errors
3. Verify your user has a fighter profile
4. Make sure you're running scripts in the correct order

