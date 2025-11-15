# 🔑 Get Correct Supabase API Key

## 🚨 **CRITICAL: Your API Key May Be Invalid**

You're getting "Invalid API key" errors. This means the key in `.env.local` doesn't match your Supabase project.

---

## ✅ **STEP 1: Get Current API Key from Supabase (2 minutes)**

1. **Go to Supabase Dashboard:**
   - Visit: **https://supabase.com/dashboard**
   - Sign in to your account

2. **Select Your Project:**
   - Find and click: **`andmtvsqqomgwphotdwf`**

3. **Navigate to API Settings:**
   - Click: **Settings** (gear icon in left sidebar)
   - Click: **API** tab

4. **Copy the Anon Key:**
   - Find section: **"Project API keys"**
   - Find: **"anon public"** key
   - **Click the copy icon** next to the key
   - **Copy the ENTIRE key** (it's a long JWT token starting with `eyJ...`)

---

## ✅ **STEP 2: Update .env.local (1 minute)**

1. **Open `.env.local` file:**
   - Path: `C:\Users\mahad\TantalusBoxingClubExpo\tantalus-boxing-club\.env.local`

2. **Replace the anon key:**
   - Find line: `REACT_APP_SUPABASE_ANON_KEY=...`
   - **Delete the old key value**
   - **Paste the NEW key** you copied from Supabase
   - Make sure there are **NO SPACES** before or after the `=`
   - Should look like: `REACT_APP_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

3. **Save the file** (Ctrl+S)

---

## ✅ **STEP 3: Restart Dev Server (30 seconds)**

**⚠️ CRITICAL:** React apps only load environment variables at startup!

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

4. **Check browser console** - You should see:
   ```
   🔍 Supabase Configuration Check:
     URL: ✅ Set
     Anon Key: ✅ Set (208 chars)
     Key starts with: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
   ```

5. **Try logging in** - Should work now!

---

## 🔍 **Verify Key Format**

The anon key should:
- ✅ Start with `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9`
- ✅ Be a long JWT token (about 200+ characters)
- ✅ Have NO spaces or quotes around it
- ✅ Match EXACTLY what's in Supabase Dashboard

**❌ Wrong format:**
```
REACT_APP_SUPABASE_ANON_KEY= "eyJ..."  # Has quotes and space
REACT_APP_SUPABASE_ANON_KEY = eyJ...   # Has spaces around =
```

**✅ Correct format:**
```
REACT_APP_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

---

## 🆘 **If Still Getting Errors**

### **Check 1: Is the key loading?**

Open browser console (F12) and look for:
```
🔍 Supabase Configuration Check:
```

- **If you DON'T see this:** Server wasn't restarted → Restart it
- **If you DO see this:** Key is loading but invalid → Get new key from Supabase

### **Check 2: Compare Keys**

1. **In Supabase Dashboard:** Copy the anon key
2. **In `.env.local`:** Check what's there
3. **Compare:** They should match EXACTLY (character by character)

### **Check 3: Key Was Rotated**

If you rotated the JWT secret in Supabase, ALL old keys are invalid. You MUST:
1. Get the NEW anon key from Supabase Dashboard
2. Update `.env.local` with the new key
3. Restart dev server

---

## 📋 **Quick Checklist**

- [ ] Opened Supabase Dashboard
- [ ] Selected project: `andmtvsqqomgwphotdwf`
- [ ] Went to Settings → API
- [ ] Copied current "anon public" key
- [ ] Opened `.env.local` file
- [ ] Replaced `REACT_APP_SUPABASE_ANON_KEY` value
- [ ] Saved `.env.local`
- [ ] Stopped dev server (Ctrl+C)
- [ ] Restarted dev server (`npm start`)
- [ ] Saw debug logs in console
- [ ] Tried logging in

---

## 💡 **Why This Happens**

Supabase API keys can become invalid if:
1. **JWT secret was rotated** - All old keys stop working
2. **Key was regenerated** - Old key is replaced
3. **Project was reset** - New keys are generated
4. **Wrong project** - Key from different project

**Solution:** Always get the current key directly from Supabase Dashboard!

---

**Status:** 🔴 **DO THIS NOW** - Get current key from Supabase and update `.env.local`

