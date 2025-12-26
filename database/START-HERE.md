# 🚨 START HERE - Fix Fighters Not Showing

## You're seeing: "NO FIGHTERS RETURNED FROM QUERY"

**This means:** Database security (RLS) is blocking access to fighter data.

---

## ✅ THE FIX (3 Steps, 2 Minutes)

### 1️⃣ Open Supabase SQL Editor
- Go to: https://supabase.com/dashboard
- Click your project
- Click **"SQL Editor"** (left sidebar)

### 2️⃣ Copy & Run This File
- Open: **`database/COPY-THIS-AND-RUN.sql`**
- **Select ALL** (Ctrl+A)
- **Copy** (Ctrl+C)
- **Paste** in Supabase SQL Editor (Ctrl+V)
- Click **"Run"**

### 3️⃣ Refresh Your App
- Press **Ctrl+Shift+R** (hard refresh)
- Fighters should appear! 🎉

---

## ✅ How to Know It Worked

After running the SQL, you should see:
- ✅ `status: "✅ SUCCESS - RLS FIXED!"`
- ✅ `total_fighters: [a number]`
- ✅ Two policies listed

After refreshing your app:
- ✅ No more "NO FIGHTERS RETURNED FROM QUERY" error
- ✅ Fighters appear on homepage

---

## 🔍 Still Not Working?

Run this test script to see what's wrong:
1. Open: **`database/TEST-IF-FIX-WORKED.sql`**
2. Copy ALL (Ctrl+A, Ctrl+C)
3. Paste in Supabase SQL Editor
4. Click "Run"
5. Check the output - it will tell you exactly what's wrong

---

## 📋 What This Does

The fix script:
- ✅ Grants read permissions to both logged-in and logged-out users
- ✅ Keeps security enabled (RLS stays on)
- ✅ Removes blocking policies
- ✅ Creates permissive policies allowing public read access

**Safe to run** - only allows reading fighter profiles, not modifying them.

