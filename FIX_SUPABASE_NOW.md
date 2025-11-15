# 🚨 FIX SUPABASE CONFIGURATION - IMMEDIATE ACTION REQUIRED

## ⚠️ The Error You're Seeing

```
🚨 CRITICAL: Supabase not configured! Please check REGISTRATION_FIX_GUIDE.md for setup instructions.
```

This error appears because the Supabase environment variables are **missing or contain placeholder values**.

---

## ✅ QUICK FIX (2 Minutes)

### Step 1: Create `.env.local` File

**Location:** Create this file in the `tantalus-boxing-club` directory (same folder as `package.json`)

**File Name:** `.env.local` (exactly this name, including the dot at the beginning)

**File Content:**
```env
REACT_APP_SUPABASE_URL=https://andmtvsqqomgwphotdwf.supabase.co
REACT_APP_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFuZG10dnNxcW9tZ3dwaG90ZHdmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5OTQwMTcsImV4cCI6MjA3ODM1NDAxN30.KMkOUaaf61Wsfk3HoMgbDTetBj-dhgtJsj453aCrJSo
```

### Step 2: Restart Your Development Server

**IMPORTANT:** Environment variables are only loaded when the server starts!

1. **Stop the server**: Press `Ctrl+C` in the terminal where `npm start` is running
2. **Start again**: Run `npm start`
3. **Wait** for the app to load
4. **Refresh** your browser

---

## 🔍 How to Verify It Worked

After restarting:

1. **Open browser console** (F12)
2. **Look for this message** (should appear on startup):
   ```
   🔍 Supabase Configuration Check:
     URL: ✅ Set
     Anon Key: ✅ Set (XXX chars)
   ```

3. **The error message should disappear** from the registration page

4. **Try registering** - it should work now!

---

## 🌐 For Production (Vercel)

If you're deploying to Vercel, you also need to set these environment variables in the Vercel Dashboard:

1. **Go to**: https://vercel.com/dashboard
2. **Select your project**: Tantalus-Boxing-Club
3. **Click**: Settings → Environment Variables
4. **Add these two variables**:

   **Variable 1:**
   - Key: `REACT_APP_SUPABASE_URL`
   - Value: `https://andmtvsqqomgwphotdwf.supabase.co`
   - ✅ Check: Production, Preview, Development

   **Variable 2:**
   - Key: `REACT_APP_SUPABASE_ANON_KEY`
   - Value: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFuZG10dnNxcW9tZ3dwaG90ZHdmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5OTQwMTcsImV4cCI6MjA3ODM1NDAxN30.KMkOUaaf61Wsfk3HoMgbDTetBj-dhgtJsj453aCrJSo`
   - ✅ Check: Production, Preview, Development

5. **Redeploy** after adding variables

---

## 🆘 Troubleshooting

### If the error persists after creating `.env.local`:

1. **Verify file location**: The `.env.local` file must be in `tantalus-boxing-club/` (same folder as `package.json`)
2. **Check file name**: Must be exactly `.env.local` (with the dot at the beginning)
3. **Verify no typos**: Copy the values exactly as shown above
4. **Restart server**: You MUST restart after creating/editing `.env.local`
5. **Check console**: Look for any other error messages

### If you see "Invalid API key":

- The anon key might have changed
- Go to: https://supabase.com/dashboard → Your Project → Settings → API
- Copy the new "anon public" key
- Update `.env.local` with the new key
- Restart server

### If registration still fails:

- Check that the database schema is set up
- See `REGISTRATION_FIX_GUIDE.md` for database setup instructions

---

## 📝 File Structure

Your project should look like this:

```
tantalus-boxing-club/
  ├── .env.local          ← CREATE THIS FILE HERE
  ├── package.json
  ├── src/
  ├── public/
  └── ...
```

---

## ✅ Success Checklist

After following these steps, you should have:

- [ ] `.env.local` file created in `tantalus-boxing-club/` directory
- [ ] Both environment variables set with correct values
- [ ] Development server restarted
- [ ] No "Supabase not configured" error
- [ ] Console shows "✅ Set" for both URL and Anon Key
- [ ] Registration page loads without errors

---

**The fix is simple: Create `.env.local` with the values above, then restart your server!** 🚀

