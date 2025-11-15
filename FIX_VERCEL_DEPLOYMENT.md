# 🚨 FIX VERCEL DEPLOYMENT ERRORS

## ⚠️ The Problem

You're viewing your **Vercel deployment** (`tantalus-boxing-club-xxp2.vercel.app`), not localhost. 

**Two issues:**
1. ❌ **Missing Supabase environment variables** - Need to set in Vercel Dashboard
2. ❌ **CSP error** - `vercel.json` needs to be updated and redeployed

---

## ✅ FIX 1: Set Environment Variables in Vercel

### Step 1: Go to Vercel Dashboard
1. Visit: https://vercel.com/dashboard
2. Sign in
3. Find your project: **Tantalus-Boxing-Club** or **tantalus-boxing-club**

### Step 2: Add Environment Variables
1. Click on your project
2. Go to **Settings** tab
3. Click **Environment Variables** (left sidebar)
4. Click **"Add New"** button

**Add Variable 1:**
- **Key:** `REACT_APP_SUPABASE_URL`
- **Value:** `https://andmtvsqqomgwphotdwf.supabase.co`
- **Environment:** ✅ Production, ✅ Preview, ✅ Development
- Click **Save**

**Add Variable 2:**
- **Key:** `REACT_APP_SUPABASE_ANON_KEY`
- **Value:** `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFuZG10dnNxcW9tZ3dwaG90ZHdmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5OTQwMTcsImV4cCI6MjA3ODM1NDAxN30.KMkOUaaf61Wsfk3HoMgbDTetBj-dhgtJsj453aCrJSo`
- **Environment:** ✅ Production, ✅ Preview, ✅ Development
- Click **Save**

### Step 3: Redeploy
1. Go to **Deployments** tab
2. Click **"..."** (three dots) on the latest deployment
3. Click **"Redeploy"**
4. **Uncheck:** "Use existing Build Cache" (important!)
5. Click **"Redeploy"**
6. Wait for deployment to complete (2-3 minutes)

---

## ✅ FIX 2: CSP Error (Already Fixed in Code)

The `vercel.json` file already includes `https://vercel.live` in the CSP. After you redeploy (Step 3 above), the CSP error will be fixed.

---

## 🔍 Verify It Worked

After redeployment completes:

1. **Visit:** `https://tantalus-boxing-club-xxp2.vercel.app`
2. **Open console** (F12)
3. **Look for:**
   ```
   🔍 Supabase Configuration Check:
     URL: ✅ Set
     Anon Key: ✅ Set (208 chars)
   ```
4. **Check for errors:**
   - ❌ Supabase error should be GONE
   - ❌ CSP error should be GONE (or reduced)

---

## 📋 Quick Checklist

- [ ] Added `REACT_APP_SUPABASE_URL` in Vercel Dashboard
- [ ] Added `REACT_APP_SUPABASE_ANON_KEY` in Vercel Dashboard
- [ ] Selected all environments (Production, Preview, Development)
- [ ] Redeployed with cache cleared
- [ ] Waited for deployment to complete
- [ ] Verified errors are gone

---

## 🆘 If Errors Persist

### Check 1: Are variables set correctly?
- Go to Vercel Dashboard → Settings → Environment Variables
- Verify both variables exist
- Verify they're enabled for "Production"

### Check 2: Did you redeploy?
- Environment variables only apply to NEW deployments
- You MUST redeploy after adding variables

### Check 3: Did you clear build cache?
- When redeploying, uncheck "Use existing Build Cache"
- This ensures the build uses new environment variables

---

## 💡 Local vs Vercel

- **Local development** (`localhost:3000`): Uses `.env.local` file
- **Vercel deployment** (`*.vercel.app`): Uses Vercel Dashboard environment variables

You need to set environment variables in **both places** if you use both!

