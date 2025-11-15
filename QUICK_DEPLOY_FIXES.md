# ⚡ Quick Deploy - Fix All Errors

## 🎯 The Problem

You're seeing errors because **the deployed version on Vercel still has the old configuration**. The fixes are ready locally but need to be deployed.

## ✅ What's Fixed Locally

1. ✅ CSP now allows `https://vercel.live` scripts
2. ✅ Manifest.json routing fixed
3. ✅ Manifest.json headers configured for public access

## 🚀 Deploy in 3 Steps

### Step 1: Open Terminal

Open PowerShell or Command Prompt in the `tantalus-boxing-club` folder.

### Step 2: Run These Commands

```powershell
# Navigate to project (if not already there)
cd tantalus-boxing-club

# Check what changed
git status

# Add the fixed files
git add vercel.json public/_headers

# Commit the changes
git commit -m "Fix CSP for Vercel Live and manifest.json access"

# Push to trigger Vercel deployment
git push
```

### Step 3: Wait & Test

1. **Wait 1-2 minutes** for Vercel to deploy
2. **Go to Vercel Dashboard**: https://vercel.com/dashboard
3. **Check deployment status** - should show "Ready" when done
4. **Hard refresh browser**: Press `Ctrl+Shift+R` (or test in incognito)

---

## 🔧 Fix Environment Variables (Still Needed)

### For Local Development:

Create `.env.local` in `tantalus-boxing-club/` folder:

```env
REACT_APP_SUPABASE_URL=https://andmtvsqqomgwphotdwf.supabase.co
REACT_APP_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFuZG10dnNxcW9tZ3dwaG90ZHdmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5OTQwMTcsImV4cCI6MjA3ODM1NDAxN30.KMkOUaaf61Wsfk3HoMgbDTetBj-dhgtJsj453aCrJSo
```

Then restart: `Ctrl+C` then `npm start`

### For Production (Vercel):

1. Go to: https://vercel.com/dashboard
2. Select project: **Tantalus-Boxing-Club**
3. Click: **Settings** → **Environment Variables**
4. Add these (if not already added):

   **Variable 1:**
   - Key: `REACT_APP_SUPABASE_URL`
   - Value: `https://andmtvsqqomgwphotdwf.supabase.co`
   - ✅ Check all environments

   **Variable 2:**
   - Key: `REACT_APP_SUPABASE_ANON_KEY`
   - Value: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFuZG10dnNxcW9tZ3dwaG90ZHdmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5OTQwMTcsImV4cCI6MjA3ODM1NDAxN30.KMkOUaaf61Wsfk3HoMgbDTetBj-dhgtJsj453aCrJSo`
   - ✅ Check all environments

5. **Redeploy** after adding variables

---

## ✅ After Deployment - Verify Fixes

Open browser DevTools (F12) and check:

1. **No CSP errors** - Console should not show vercel.live violations
2. **No Supabase errors** - Should not see "Missing required Supabase environment variables"
3. **No manifest.json 401** - Network tab should show manifest.json loads with 200 status

---

## 🆘 If Still Seeing Errors

1. **Clear browser cache completely**:
   - Chrome: `Ctrl+Shift+Delete` → Clear cached images and files
   - Or use **Incognito mode** to test

2. **Check Vercel deployment logs**:
   - Go to Vercel Dashboard → Your Project → Deployments
   - Click on latest deployment → View logs
   - Look for any errors

3. **Verify CSP in browser**:
   - Open DevTools (F12)
   - Go to Network tab
   - Reload page
   - Click on the main document request
   - Check Response Headers
   - Look for `Content-Security-Policy` header
   - Should include `https://vercel.live`

---

## 📝 Summary

**The fixes are ready!** You just need to:
1. ✅ Commit and push `vercel.json` and `public/_headers`
2. ✅ Wait for Vercel to deploy
3. ✅ Create `.env.local` for local dev
4. ✅ Set environment variables in Vercel Dashboard

After deployment, all three errors should be resolved! 🎉

