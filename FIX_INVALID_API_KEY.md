# 🔐 Fix: Invalid API Key Error

## ⚠️ **Problem**

You're getting `Invalid API key` error because:
- You rotated the Supabase JWT secret (which invalidated ALL old keys)
- The app is using the **OLD anon key** instead of the **NEW one**

---

## ✅ **Solution: Update to NEW Anon Key**

### **Step 1: Get NEW Anon Key from Supabase**

1. **Go to:** https://supabase.com/dashboard
2. **Select:** Your project (`andmtvsqqomgwphotdwf`)
3. **Go to:** **Settings** → **API**
4. **Find:** **"anon public"** key section
5. **Copy the NEW key** (it's different from the old one!)

**The NEW key should start with:** `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

**⚠️ IMPORTANT:** After rotating JWT secret, BOTH keys changed:
- ✅ New anon key (for client-side)
- ✅ New service role key (for server-side)

---

### **Step 2: Update Local Environment (.env.local)**

**If running locally:**

1. **Open:** `tantalus-boxing-club/.env.local`
2. **Update** the anon key:
   ```env
   REACT_APP_SUPABASE_URL=https://andmtvsqqomgwphotdwf.supabase.co
   REACT_APP_SUPABASE_ANON_KEY=your-NEW-anon-key-here
   SUPABASE_SERVICE_ROLE_KEY=your-NEW-service-role-key-here
   ```
3. **Save** the file
4. **Restart** your development server:
   ```bash
   # Stop the server (Ctrl+C)
   # Then restart:
   npm start
   ```

---

### **Step 3: Update Vercel Environment Variables**

**If deployed on Vercel:**

1. **Go to:** https://vercel.com/dashboard → Your Project → **Settings**
2. **Click:** **"Environment Variables"**
3. **Find:** `REACT_APP_SUPABASE_ANON_KEY`
4. **Click:** **"Edit"** (or delete and recreate)
5. **Update** with the NEW anon key from Step 1
6. **Save**
7. **Redeploy:**
   - Go to **"Deployments"** tab
   - Click **"..."** → **"Redeploy"**
   - Uncheck "Use existing Build Cache"
   - Click **"Redeploy"**

---

## 🔍 **Verify Keys Are Correct**

### **Check Current Keys:**

**Old Key (INVALID - don't use):**
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFuZG10dnNxcW9tZ3dwaG90ZHdmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjEzNDYwNTIsImV4cCI6MjA3NjkyMjA1Mn0.qIGPbceA5xPchQb3wtQu3OU0ngoMc7TjcTCxUQo9C5o
```
(This was invalidated when you rotated the JWT secret)

**New Key (VALID - use this):**
- Get from Supabase Dashboard → Settings → API → anon public key
- Should have timestamp `1762994017` (newer than old one)

---

## 📋 **Quick Checklist**

- [ ] Got NEW anon key from Supabase Dashboard
- [ ] Updated `.env.local` with NEW anon key (if running locally)
- [ ] Updated Vercel environment variables with NEW anon key (if deployed)
- [ ] Restarted dev server (if local)
- [ ] Redeployed Vercel (if deployed)
- [ ] Tested login - should work now

---

## ✅ **After Updating**

1. **Clear browser cache** (or use incognito mode)
2. **Try logging in again**
3. **Should work** with the new key

---

## 🆘 **If Still Getting Errors**

### **Check Environment Variables:**

**In browser console, check:**
```javascript
console.log('Supabase URL:', process.env.REACT_APP_SUPABASE_URL);
console.log('Has Anon Key:', !!process.env.REACT_APP_SUPABASE_ANON_KEY);
```

**Should show:**
- URL: `https://andmtvsqqomgwphotdwf.supabase.co`
- Has Anon Key: `true`

### **Verify Key Format:**

The anon key should:
- Start with `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9`
- Be a long JWT token
- Match exactly what's in Supabase Dashboard

---

**Status:** 🔴 **ACTION REQUIRED** - Update to NEW anon key from Supabase



