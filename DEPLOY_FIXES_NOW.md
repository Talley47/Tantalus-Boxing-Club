# 🚀 Deploy Fixes Now - Step by Step

## ⚠️ Current Situation

You're seeing errors because the **deployed version on Vercel** still has the old CSP configuration. The fixes have been made locally but need to be deployed.

## ✅ What Was Fixed Locally

1. ✅ **CSP Updated** - Added `https://vercel.live` to allow Vercel Live scripts
2. ✅ **Rewrite Rules Updated** - Fixed manifest.json routing
3. ⚠️ **Environment Variables** - Still need to be set (see below)

## 📋 Steps to Deploy Fixes

### Step 1: Verify Local Changes

The following files were updated:
- ✅ `vercel.json` - CSP now includes `https://vercel.live`
- ✅ `public/_headers` - CSP now includes `https://vercel.live`

### Step 2: Commit and Push Changes

Open your terminal in the `tantalus-boxing-club` directory and run:

```bash
# Navigate to the project directory
cd tantalus-boxing-club

# Check what files changed
git status

# Add the changed files
git add vercel.json public/_headers

# Commit the changes
git commit -m "Fix CSP to allow Vercel Live scripts and fix manifest.json routing"

# Push to trigger Vercel deployment
git push
```

### Step 3: Wait for Vercel Deployment

1. Go to your Vercel dashboard: https://vercel.com/dashboard
2. Find your project: `Tantalus-Boxing-Club`
3. Wait for the deployment to complete (usually 1-2 minutes)
4. The deployment will automatically use the new `vercel.json` configuration

### Step 4: Clear Browser Cache

After deployment completes:
1. **Hard refresh** your browser: `Ctrl+Shift+R` (Windows) or `Cmd+Shift+R` (Mac)
2. Or open in **Incognito/Private mode** to test

### Step 5: Verify Fixes

After deployment, you should see:
- ✅ No CSP violation errors for `vercel.live`
- ✅ No manifest.json 401 errors (or they should be resolved)

---

## 🔧 For Local Development: Create .env.local

**You still need to create `.env.local` for local development:**

1. Create a file named `.env.local` in the `tantalus-boxing-club` directory
2. Add these lines:

```env
REACT_APP_SUPABASE_URL=https://andmtvsqqomgwphotdwf.supabase.co
REACT_APP_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFuZG10dnNxcW9tZ3dwaG90ZHdmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5OTQwMTcsImV4cCI6MjA3ODM1NDAxN30.KMkOUaaf61Wsfk3HoMgbDTetBj-dhgtJsj453aCrJSo
```

3. **Restart your dev server** (if running locally):
   - Press `Ctrl+C` to stop
   - Run `npm start` again

---

## 🌐 For Production: Set Vercel Environment Variables

**If you haven't already, set environment variables in Vercel:**

1. Go to: https://vercel.com/dashboard
2. Select your project: `Tantalus-Boxing-Club`
3. Click: **Settings** → **Environment Variables**
4. Add these two variables:

   **Variable 1:**
   - Key: `REACT_APP_SUPABASE_URL`
   - Value: `https://andmtvsqqomgwphotdwf.supabase.co`
   - Environments: ✅ Production, ✅ Preview, ✅ Development

   **Variable 2:**
   - Key: `REACT_APP_SUPABASE_ANON_KEY`
   - Value: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFuZG10dnNxcW9tZ3dwaG90ZHdmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5OTQwMTcsImV4cCI6MjA3ODM1NDAxN30.KMkOUaaf61Wsfk3HoMgbDTetBj-dhgtJsj453aCrJSo`
   - Environments: ✅ Production, ✅ Preview, ✅ Development

5. **Redeploy** after adding variables:
   - Go to **Deployments** tab
   - Click **"..."** on latest deployment
   - Click **"Redeploy"**

---

## 🔍 Understanding the Errors

### Error 1: CSP Violation
**What it means:** The browser is blocking a script from `vercel.live` because it's not in the allowed list.

**Why you still see it:** The deployed version on Vercel has the old CSP. After you push the changes and Vercel redeploys, this will be fixed.

### Error 2: Missing Supabase Variables
**What it means:** The app can't connect to Supabase because environment variables are missing.

**Fix:** Create `.env.local` locally AND set variables in Vercel Dashboard (see steps above).

### Error 3: Manifest.json 401
**What it means:** The browser can't fetch the manifest.json file (used for PWA features).

**Why it happens:** Could be routing issue or authentication middleware. The rewrite rule fix should help, but you need to deploy it first.

---

## ✅ Quick Checklist

- [ ] Commit and push `vercel.json` and `public/_headers` changes
- [ ] Wait for Vercel deployment to complete
- [ ] Create `.env.local` for local development
- [ ] Set environment variables in Vercel Dashboard (if not done)
- [ ] Clear browser cache or test in incognito
- [ ] Verify errors are gone

---

## 🆘 If Errors Persist After Deployment

1. **Check Vercel deployment logs** for any errors
2. **Verify the CSP in browser DevTools:**
   - Open DevTools (F12)
   - Go to Network tab
   - Look at response headers for `Content-Security-Policy`
   - Should include `https://vercel.live`
3. **Check environment variables are set** in Vercel Dashboard
4. **Try a hard refresh** or clear browser cache completely

---

**Note:** The fixes are ready locally. You just need to deploy them to Vercel for the production errors to go away!

