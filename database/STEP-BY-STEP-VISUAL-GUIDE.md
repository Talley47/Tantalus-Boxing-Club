# 📸 Step-by-Step Visual Guide

## ⚡ QUICK FIX (Copy-Paste - 2 minutes)

### ✅ Step 1: Open Supabase Dashboard
```
1. Go to: https://supabase.com/dashboard
2. Sign in if needed
3. Click on YOUR PROJECT NAME
4. Click "SQL Editor" in left sidebar (looks like: </>)
```

### ✅ Step 2: Open the SQL File
```
1. In your code editor, open: database/COPY-THIS-AND-RUN.sql
2. Press Ctrl+A (Windows) or Cmd+A (Mac) to SELECT ALL
3. Press Ctrl+C (Windows) or Cmd+C (Mac) to COPY
```

### ✅ Step 3: Paste in Supabase
```
1. In Supabase SQL Editor, click "New Query" button
2. Click in the text area
3. Press Ctrl+V (Windows) or Cmd+V (Mac) to PASTE
```

### ✅ Step 4: Run the SQL
```
1. Click the green "Run" button (bottom right)
   OR
2. Press Ctrl+Enter (Windows) or Cmd+Enter (Mac)
```

### ✅ Step 5: Check Results
You should see TWO result tables:

**Table 1:**
```
status: "✅ SUCCESS - RLS FIXED!"
total_fighters: [your number]
fighters_with_user_id: [your number]
```

**Table 2:**
```
Two rows showing:
- "Authenticated users can view fighter profiles"
- "Anonymous users can view fighter profiles"
```

### ✅ Step 6: Refresh Your App
```
1. Go back to your app
2. Press Ctrl+Shift+R (Windows) or Cmd+Shift+R (Mac)
   (This does a hard refresh)
```

**🎉 Fighters should now appear!**

---

## 🆘 If You See an Error

### Error: "permission denied"
→ You need admin access to your Supabase project. Make sure you're logged in as the project owner.

### Error: "relation does not exist"
→ The table name might be different. Run this first:
```sql
SELECT tablename FROM pg_tables WHERE schemaname = 'public' AND tablename LIKE '%fighter%';
```

### Error: "syntax error"
→ Make sure you copied the ENTIRE file, including all lines from `--` comments to the end.

---

## 🧪 Test If It Worked

After running the SQL, test it:

1. Go to Supabase SQL Editor
2. Run this query:
```sql
SELECT COUNT(*) FROM public.fighter_profiles;
```
3. If you see a number > 0, it worked! ✅
4. If you see 0 or an error, something is wrong ❌

---

## 📞 Still Need Help?

Run the diagnostic script:
1. Open: `database/CHECK-FIGHTER-PROFILES-RLS-NOW.sql`
2. Copy ALL content
3. Paste in Supabase SQL Editor
4. Click "Run"
5. Share the output

