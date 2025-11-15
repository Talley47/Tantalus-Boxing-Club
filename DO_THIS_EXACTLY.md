# 🚨 DO THIS EXACTLY - Fix Invalid API Key

## ⚠️ **The Problem**
Your `.env.local` file has an API key that Supabase doesn't recognize. You need to get the CURRENT key from Supabase and update the file.

---

## ✅ **STEP-BY-STEP FIX (5 minutes)**

### **STEP 1: Get Current API Key from Supabase (2 minutes)**

1. **Open:** https://supabase.com/dashboard
2. **Sign in** (if needed)
3. **Click:** Project `andmtvsqqomgwphotdwf`
4. **Click:** **Settings** (gear icon in left sidebar)
5. **Click:** **API** tab
6. **Find:** Section called **"Project API keys"**
7. **Find:** **"anon public"** key (NOT "service_role")
8. **Click:** Copy button (📋 icon) next to the key
9. **Copy the ENTIRE key** - it's a long string starting with `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

**✅ You now have the correct key**

---

### **STEP 2: Update .env.local File (1 minute)**

1. **Open this file:**
   ```
   C:\Users\mahad\TantalusBoxingClubExpo\tantalus-boxing-club\.env.local
   ```

2. **Find this line:**
   ```
   REACT_APP_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
   ```

3. **Delete everything after the `=`** (the old key)

4. **Paste the NEW key** you copied from Step 1

5. **Make sure it looks like this** (no spaces, no quotes):
   ```
   REACT_APP_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
   ```

6. **Save the file** (Press `Ctrl+S`)

**✅ File updated**

---

### **STEP 3: Restart Dev Server (2 minutes)**

**⚠️ CRITICAL:** React apps ONLY load environment variables when they START!

1. **Stop the server:**
   - Go to terminal/command prompt where `npm start` is running
   - Press `Ctrl+C`
   - **WAIT** until you see your command prompt again (server is stopped)

2. **Start it again:**
   ```bash
   cd C:\Users\mahad\TantalusBoxingClubExpo\tantalus-boxing-club
   npm start
   ```

3. **Wait for compilation:**
   - Watch the terminal
   - Wait for: `Compiled successfully!`
   - This takes 10-30 seconds

4. **Open browser:**
   - Go to: http://localhost:3000
   - Press `F5` to refresh

5. **Check console:**
   - Press `F12` to open browser console
   - Look for this message:
     ```
     🔍 Supabase Configuration Check:
       URL: ✅ Set
       Anon Key: ✅ Set (208 chars)
       Key starts with: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
     ```

6. **Try logging in** - Should work now!

---

## 🔍 **Verify It's Working**

After completing all 3 steps:

1. **Open browser console** (F12)
2. **You should see:** The debug logs showing configuration
3. **Try logging in** - Should succeed!

**If you still get "Invalid API key":**
- Run this in browser console: `window.__CHECK_SUPABASE_KEY__()`
- Compare the key shown with what's in Supabase Dashboard
- They must match EXACTLY

---

## ❌ **Common Mistakes**

1. **Didn't restart server** ← Most common! Must restart after updating `.env.local`
2. **Added spaces** - Should be `KEY=value` not `KEY = value`
3. **Added quotes** - Should be `KEY=value` not `KEY="value"`
4. **Copied wrong key** - Must be "anon public" NOT "service_role"
5. **Wrong project** - Must be project `andmtvsqqomgwphotdwf`

---

## 📋 **Checklist**

- [ ] Opened Supabase Dashboard
- [ ] Selected project: `andmtvsqqomgwphotdwf`
- [ ] Went to Settings → API
- [ ] Copied "anon public" key (NOT service_role)
- [ ] Opened `.env.local` file
- [ ] Replaced `REACT_APP_SUPABASE_ANON_KEY` value
- [ ] Saved file (Ctrl+S)
- [ ] Stopped dev server (Ctrl+C)
- [ ] Waited for server to stop
- [ ] Started dev server (`npm start`)
- [ ] Waited for "Compiled successfully!"
- [ ] Refreshed browser (F5)
- [ ] Checked console for debug logs
- [ ] Tried logging in

---

## 🆘 **Still Not Working?**

If you've done all 3 steps and still getting errors:

1. **Verify key format in `.env.local`:**
   - Open the file
   - Should be: `REACT_APP_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`
   - NO spaces before/after `=`
   - NO quotes around the key

2. **Check file location:**
   - Must be: `tantalus-boxing-club\.env.local`
   - Same folder as `package.json`

3. **Verify Supabase project:**
   - Make sure project `andmtvsqqomgwphotdwf` is active
   - Check project status in Supabase Dashboard

4. **Clear browser cache:**
   - Press `Ctrl+Shift+Delete`
   - Clear cached files
   - Refresh page

---

**Status:** 🔴 **DO ALL 3 STEPS ABOVE** - Start with Step 1 (get key from Supabase)

