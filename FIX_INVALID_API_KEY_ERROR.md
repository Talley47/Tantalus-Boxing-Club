# 🔧 Fix: "Invalid API key" Error

## 🎯 **Problem**

You're getting `AuthApiError: Invalid API key` when trying to log in. This happens because:

1. **React dev server needs restart** - Environment variables are only loaded at startup
2. **OR** - The API key in `.env.local` doesn't match your Supabase project

---

## ✅ **Solution: Step-by-Step Fix**

### **Step 1: Verify Environment Variables**

Your `.env.local` file exists and has the correct format. ✅

**Current values:**
- `REACT_APP_SUPABASE_URL`: `https://andmtvsqqomgwphotdwf.supabase.co`
- `REACT_APP_SUPABASE_ANON_KEY`: Set (208 characters, valid JWT format)

---

### **Step 2: Restart Your React Dev Server**

**⚠️ CRITICAL:** React apps only load environment variables when they start!

1. **Stop your current dev server:**
   - Press `Ctrl+C` in the terminal where `npm start` is running
   - Wait for it to fully stop

2. **Start it again:**
   ```bash
   npm start
   ```

3. **Wait for the app to load** (usually takes 10-30 seconds)

4. **Try logging in again**

---

### **Step 3: If Still Getting Error - Verify API Key**

If restarting doesn't fix it, the API key might be incorrect:

1. **Go to Supabase Dashboard:**
   - Visit: https://supabase.com/dashboard
   - Sign in
   - Select your project: `andmtvsqqomgwphotdwf`

2. **Get the Current Anon Key:**
   - Go to: **Settings** → **API**
   - Find: **"anon public"** key section
   - **Copy the entire key** (it's a long JWT token)

3. **Update `.env.local`:**
   - Open: `tantalus-boxing-club/.env.local`
   - Replace the `REACT_APP_SUPABASE_ANON_KEY` value with the new key
   - Save the file

4. **Restart dev server again:**
   ```bash
   # Stop server (Ctrl+C)
   npm start
   ```

---

## 🔍 **Verify It's Working**

After restarting:

1. **Open browser console** (F12)
2. **Check for errors** - should not see "Invalid API key"
3. **Try logging in** - should work now

---

## 📋 **Quick Checklist**

- [ ] Stopped dev server (Ctrl+C)
- [ ] Restarted dev server (`npm start`)
- [ ] Waited for app to fully load
- [ ] Tried logging in again
- [ ] If still failing: Verified API key in Supabase Dashboard
- [ ] If still failing: Updated `.env.local` with correct key
- [ ] Restarted dev server again after updating key

---

## 🆘 **Still Not Working?**

### **Check Browser Console:**

Open browser console (F12) and check:

1. **Are environment variables loaded?**
   - Look for any errors about missing env vars
   - The app should load without throwing errors

2. **What's the exact error?**
   - Copy the full error message
   - Check if it's still "Invalid API key" or something else

### **Common Issues:**

1. **Multiple `.env` files:**
   - Make sure you're editing `.env.local` (not `.env` or `.env.development`)
   - React Scripts prioritizes `.env.local`

2. **Key has extra spaces:**
   - Make sure there are no spaces before/after the key value
   - Should be: `REACT_APP_SUPABASE_ANON_KEY=eyJhbGci...` (no spaces)

3. **Wrong project:**
   - Verify the URL matches your Supabase project
   - URL should match: `https://andmtvsqqomgwphotdwf.supabase.co`

---

## ✅ **Expected Result**

After fixing:
- ✅ No "Invalid API key" errors in console
- ✅ Login form submits successfully
- ✅ User is authenticated and redirected
- ✅ App works normally

---

**Status:** 🔧 **ACTION REQUIRED** - Restart dev server first, then verify API key if needed

