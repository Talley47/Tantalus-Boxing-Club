# 🚨 QUICK FIX: Invalid API Key Error

## ⚡ **IMMEDIATE ACTION REQUIRED**

You're getting `Invalid API key` because the React app hasn't loaded your environment variables.

---

## ✅ **STEP 1: Restart Dev Server (30 seconds)**

**This is the #1 fix - do this first!**

1. **Stop the server:**
   - Go to terminal where `npm start` is running
   - Press `Ctrl+C`
   - Wait for it to fully stop

2. **Start it again:**
   ```bash
   cd C:\Users\mahad\TantalusBoxingClubExpo\tantalus-boxing-club
   npm start
   ```

3. **Wait for app to load** (10-30 seconds)

4. **Check browser console** - You should now see:
   ```
   🔍 Supabase Configuration Check:
     URL: ✅ Set
     Anon Key: ✅ Set (208 chars)
     Key starts with: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
   ```

5. **Try logging in again** - Should work now!

---

## 🔍 **STEP 2: Verify API Key (If Step 1 Doesn't Work)**

If restarting didn't fix it, verify your API key is correct:

1. **Go to Supabase Dashboard:**
   - https://supabase.com/dashboard
   - Sign in
   - Select project: `andmtvsqqomgwphotdwf`

2. **Get Current Anon Key:**
   - Click: **Settings** → **API**
   - Find: **"anon public"** key
   - **Copy the entire key**

3. **Compare with `.env.local`:**
   - Open: `tantalus-boxing-club/.env.local`
   - Check if `REACT_APP_SUPABASE_ANON_KEY` matches what you copied
   - If different, update it

4. **Restart dev server again** after updating

---

## 🛠️ **STEP 3: Clear Cached Client (If Still Failing)**

If you've restarted but still getting errors, clear the cached client:

1. **Open browser console** (F12)
2. **Run this command:**
   ```javascript
   window.__CLEAR_SUPABASE_CLIENT__()
   ```
3. **Page will reload** with fresh client

---

## 📋 **Checklist**

- [ ] Stopped dev server (Ctrl+C)
- [ ] Restarted dev server (`npm start`)
- [ ] Saw debug logs in console showing config
- [ ] Tried logging in
- [ ] If failed: Verified API key in Supabase Dashboard
- [ ] If failed: Updated `.env.local` with correct key
- [ ] Restarted dev server again
- [ ] If still failed: Cleared cached client

---

## 🆘 **Still Not Working?**

### **Check Browser Console:**

Look for these messages when the app loads:

**✅ Good (should see this):**
```
🔍 Supabase Configuration Check:
  URL: ✅ Set
  Anon Key: ✅ Set (208 chars)
  Key starts with: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
🆕 Creating new Supabase client instance
```

**❌ Bad (if you see this):**
```
❌ Missing
```

If you see "Missing", the environment variables aren't loading. Check:
1. `.env.local` file exists in `tantalus-boxing-club/` directory
2. File has correct format (no spaces, no quotes)
3. Dev server was restarted after creating/updating file

---

## 💡 **Why This Happens**

React apps load environment variables **only at startup**. If you:
- Created `.env.local` after starting the server
- Updated `.env.local` while server was running
- Changed environment variables

**You MUST restart the dev server** for changes to take effect!

---

**Status:** 🔴 **DO THIS NOW** - Restart your dev server!

