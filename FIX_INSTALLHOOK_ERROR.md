# 🚨 Fix installHook.js Error

## ⚠️ The Problem

The `installHook.js:1` error means you're viewing a **cached build** or **service worker** that has old code without environment variables.

## ✅ Solution: Determine Where You're Viewing the App

### Are you on localhost or Vercel?

**Check the URL in your browser:**
- `http://localhost:3000` → **Local development** (use Solution A)
- `https://*.vercel.app` → **Vercel deployment** (use Solution B)

---

## Solution A: If Viewing Localhost (localhost:3000)

### Step 1: Stop Dev Server
- Find terminal running `npm start`
- Press `Ctrl+C` to stop

### Step 2: Clear Browser Cache & Service Workers
1. **Open browser console** (F12)
2. **Run this:**
```javascript
navigator.serviceWorker.getRegistrations().then(r => r.forEach(reg => reg.unregister()));
caches.keys().then(names => names.forEach(name => caches.delete(name)));
localStorage.clear();
sessionStorage.clear();
console.log('✅ Cleared - now close browser');
```
3. **Close ALL browser tabs**
4. **Press `Ctrl+Shift+Delete`** → Clear all data → Close browser

### Step 3: Verify .env.local
```powershell
cd C:\Users\mahad\TantalusBoxingClubExpo\tantalus-boxing-club
node verify-env-setup.js
```

Should show all ✅ checks.

### Step 4: Restart Dev Server
```powershell
npm start
```

### Step 5: Use Fresh Browser
1. **Open NEW browser window**
2. **Go to:** `http://localhost:3000`
3. **Check console** (F12) for: `🔍 Supabase Configuration Check: ✅ Set`

---

## Solution B: If Viewing Vercel (*.vercel.app)

### Step 1: Set Environment Variables in Vercel Dashboard

1. **Go to:** https://vercel.com/dashboard
2. **Project:** Tantalus-Boxing-Club
3. **Settings** → **Environment Variables**
4. **Add:**

**Variable 1:**
- Key: `REACT_APP_SUPABASE_URL`
- Value: `https://andmtvsqqomgwphotdwf.supabase.co`
- Environment: Production, Preview, Development (all)
- Save

**Variable 2:**
- Key: `REACT_APP_SUPABASE_ANON_KEY`
- Value: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFuZG10dnNxcW9tZ3dwaG90ZHdmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5OTQwMTcsImV4cCI6MjA3ODM1NDAxN30.KMkOUaaf61Wsfk3HoMgbDTetBj-dhgtJsj453aCrJSo`
- Environment: Production, Preview, Development (all)
- Save

### Step 2: Redeploy
1. **Deployments** tab
2. **Click "..."** on latest deployment
3. **Redeploy**
4. **Uncheck** "Use existing Build Cache"
5. **Redeploy**
6. **Wait 2-3 minutes**

### Step 3: Clear Browser Cache
1. **Hard refresh:** `Ctrl+Shift+R`
2. **Or clear cache:** `Ctrl+Shift+Delete` → Clear all

---

## 🔍 Why installHook.js Error Happens

The `installHook.js` file is from:
- A **service worker** serving cached code
- A **production build** that was built before `.env.local` existed
- **Browser cache** with old JavaScript

---

## ✅ Success Indicators

After fixing:
- ✅ No "Missing required Supabase environment variables" error
- ✅ Console shows: `🔍 Supabase Configuration Check: ✅ Set`
- ✅ No `installHook.js` errors
- ✅ App works correctly

---

**Choose Solution A if on localhost, Solution B if on Vercel!**

