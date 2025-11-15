# 🔍 Diagnose "Invalid API Key" Error

## ⚡ **Quick Diagnostic Steps**

Follow these steps **in order** to find and fix the issue:

---

## ✅ **STEP 1: Check Browser Console (30 seconds)**

1. **Open your app** in the browser (http://localhost:3000)
2. **Open browser console** (Press `F12` or Right-click → Inspect → Console tab)
3. **Look for these messages** when the page loads:

### **✅ GOOD - You should see:**
```
🔍 Supabase Configuration Check:
  URL: ✅ Set
  Anon Key: ✅ Set (208 chars)
  Key starts with: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
🆕 Creating new Supabase client instance
```

**If you see this:** Environment variables ARE loading. Go to **STEP 2**.

### **❌ BAD - If you DON'T see the above:**
The server wasn't restarted. Go to **STEP 3** immediately.

---

## ✅ **STEP 2: Check What Key Is Being Used (30 seconds)**

If you saw the debug logs in Step 1:

1. **In browser console**, type this command:
   ```javascript
   window.__CHECK_SUPABASE_KEY__()
   ```
2. **Press Enter**
3. **Copy the first 30 characters** of the key shown
4. **Compare with Supabase Dashboard:**
   - Go to: https://supabase.com/dashboard
   - Select project: `andmtvsqqomgwphotdwf`
   - Go to: Settings → API
   - Check if the "anon public" key starts with the same characters

### **If keys match:**
- The key format is correct, but Supabase is rejecting it
- **Possible causes:**
  - Key was rotated in Supabase
  - Project was reset
  - Wrong project selected
- **Solution:** Get a FRESH key from Supabase Dashboard and update `.env.local`

### **If keys DON'T match:**
- The wrong key is in `.env.local`
- **Solution:** Update `.env.local` with the correct key from Supabase Dashboard

---

## ✅ **STEP 3: Restart Dev Server (1 minute)**

**⚠️ CRITICAL:** React apps only load environment variables at startup!

1. **Stop the server:**
   - Go to terminal/command prompt where `npm start` is running
   - Press `Ctrl+C`
   - **Wait** until it fully stops (you'll see the prompt again)

2. **Start it again:**
   ```bash
   cd C:\Users\mahad\TantalusBoxingClubExpo\tantalus-boxing-club
   npm start
   ```

3. **Wait for app to load** (watch terminal - it will say "Compiled successfully!")

4. **Refresh browser** (F5)

5. **Check console again** - You should now see the debug logs from Step 1

6. **Try logging in** - Should work if key is correct

---

## ✅ **STEP 4: Get Fresh API Key from Supabase (2 minutes)**

If restarting didn't fix it, get a fresh key:

1. **Go to Supabase Dashboard:**
   - Visit: **https://supabase.com/dashboard**
   - Sign in

2. **Select Your Project:**
   - Find: **`andmtvsqqomgwphotdwf`**
   - Click on it

3. **Get API Key:**
   - Click: **Settings** (gear icon)
   - Click: **API** tab
   - Find: **"anon public"** key
   - **Click the copy button** (📋 icon)
   - **Copy the ENTIRE key**

4. **Update `.env.local`:**
   - Open: `C:\Users\mahad\TantalusBoxingClubExpo\tantalus-boxing-club\.env.local`
   - Find: `REACT_APP_SUPABASE_ANON_KEY=...`
   - **Delete everything after the `=`**
   - **Paste the NEW key** (no spaces!)
   - Should look like: `REACT_APP_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`
   - **Save** (Ctrl+S)

5. **Restart dev server** (Step 3 again)

6. **Try logging in**

---

## 🔍 **Common Issues**

### **Issue 1: "I don't see any debug logs"**
- **Cause:** Server wasn't restarted
- **Fix:** Stop server (Ctrl+C), start again (`npm start`)

### **Issue 2: "Debug logs show key, but still getting error"**
- **Cause:** Key in `.env.local` doesn't match Supabase
- **Fix:** Get fresh key from Supabase Dashboard, update `.env.local`, restart server

### **Issue 3: "Key has spaces or quotes"**
- **Cause:** Incorrect format in `.env.local`
- **Fix:** Remove all spaces and quotes. Should be: `KEY=value` (no spaces)

### **Issue 4: "Wrong project"**
- **Cause:** Key from different Supabase project
- **Fix:** Make sure you're copying key from project `andmtvsqqomgwphotdwf`

---

## 📋 **Complete Checklist**

- [ ] Opened browser console (F12)
- [ ] Checked for debug logs on page load
- [ ] Ran `window.__CHECK_SUPABASE_KEY__()` in console
- [ ] Compared key with Supabase Dashboard
- [ ] Stopped dev server (Ctrl+C)
- [ ] Restarted dev server (`npm start`)
- [ ] Waited for "Compiled successfully!"
- [ ] Refreshed browser
- [ ] Saw debug logs in console
- [ ] Got fresh key from Supabase Dashboard
- [ ] Updated `.env.local` with correct key
- [ ] Saved `.env.local`
- [ ] Restarted dev server again
- [ ] Tried logging in

---

## 🆘 **Still Not Working?**

If you've done all steps above and still getting errors:

1. **Check `.env.local` file location:**
   - Must be in: `tantalus-boxing-club/` directory (same folder as `package.json`)
   - NOT in `src/` or any subfolder

2. **Check file format:**
   - Must be named exactly: `.env.local` (with the dot at the start)
   - No `.txt` extension
   - Each line: `KEY=value` (no spaces around `=`)

3. **Verify Supabase project is active:**
   - Go to Supabase Dashboard
   - Check project status (should be "Active")
   - If paused, resume it

4. **Try clearing browser cache:**
   - Press `Ctrl+Shift+Delete`
   - Clear cached images and files
   - Refresh page

---

**Status:** 🔴 **FOLLOW STEPS ABOVE** - Start with Step 1 (check console)

