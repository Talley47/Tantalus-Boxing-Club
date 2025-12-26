# 🚨 READ THIS FIRST

## Your fighters aren't showing because database security is blocking access.

## ✅ THE FIX (Copy-Paste, 30 seconds)

### Step 1: Open Supabase
Go to: **https://supabase.com/dashboard** → Your Project → **SQL Editor**

### Step 2: Copy This File
Open: **`database/COPY-THIS-AND-RUN.sql`**  
Press: **Ctrl+A** (select all)  
Press: **Ctrl+C** (copy)

### Step 3: Run It
In Supabase SQL Editor:  
Press: **Ctrl+V** (paste)  
Click: **"Run"** button

### Step 4: Refresh App
Press: **Ctrl+Shift+R** (hard refresh)

**Done! Fighters should appear.** 🎉

---

## ✅ How to Know It Worked

After running the SQL, you'll see:
- ✅ `status: "✅ SUCCESS - RLS FIXED!"`
- ✅ A number showing your fighter count
- ✅ Two policies listed

After refreshing your app:
- ✅ No more "NO FIGHTERS RETURNED FROM QUERY" error
- ✅ Fighters appear on homepage

---

## 🔍 Still Not Working?

Run: **`database/TEST-IF-FIX-WORKED.sql`** in Supabase SQL Editor  
It will tell you exactly what's wrong.

