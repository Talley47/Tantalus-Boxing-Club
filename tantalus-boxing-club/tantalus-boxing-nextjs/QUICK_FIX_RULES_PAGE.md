# Quick Fix: Rules Page Not Showing in Production

## ⚠️ Important: Rules Page URL

The Rules page is **NOT** on the login page. It's a separate route:

- ✅ **Correct URL:** https://tantalus-boxing-club.vercel.app/rules
- ❌ **Wrong URL:** https://tantalus-boxing-club.vercel.app/login (this is the login page)

## Most Likely Issue: Vercel Root Directory

Your Next.js app is located at:
```
tantalus-boxing-club/tantalus-boxing-club/tantalus-boxing-nextjs/
```

But Vercel might be deploying from the repository root, which means it can't find your Next.js app!

## 🔧 Fix: Configure Vercel Root Directory

### Step 1: Go to Vercel Dashboard

1. Visit: https://vercel.com/dashboard
2. Select your project: **Tantalus-Boxing-Club**
3. Click **Settings** (top navigation)
4. Click **General** (left sidebar)

### Step 2: Set Root Directory

1. Scroll down to **Root Directory** section
2. Click **Edit**
3. Enter: `tantalus-boxing-club/tantalus-boxing-club/tantalus-boxing-nextjs`
4. Click **Save**

### Step 3: Redeploy

1. Go to **Deployments** tab
2. Find the latest deployment
3. Click **"..."** (three dots) → **Redeploy**
4. Wait 2-3 minutes for deployment to complete

### Step 4: Test

1. Visit: https://tantalus-boxing-club.vercel.app/rules
2. The Rules page should now load!

## ✅ Verification Checklist

After fixing:

- [ ] Root Directory set in Vercel dashboard
- [ ] Latest deployment shows commit `ba358b5` or later
- [ ] Build logs show `/rules` route compiled
- [ ] Direct URL `/rules` works (not 404)
- [ ] Homepage shows "Rules & Guidelines" button
- [ ] Navigation shows "Rules" link (when logged in)

## 📋 Alternative: Check Current Configuration

If you want to verify what Vercel is currently configured to:

1. Go to Vercel Dashboard → Your Project → Settings → General
2. Check **Root Directory**:
   - If it's **empty** or shows `/` → This is the problem!
   - If it shows `tantalus-boxing-club/tantalus-boxing-club/tantalus-boxing-nextjs` → Configuration is correct, check build logs

3. Check **Build & Development Settings**:
   - **Framework Preset:** Should be "Next.js"
   - **Build Command:** Should be `next build` (or auto-detected)
   - **Output Directory:** Should be `.next` (or auto-detected)

## 🚨 If Root Directory is Already Correct

If the root directory is already set correctly, check:

1. **Build Logs:**
   - Go to Deployments → Latest → Build Logs
   - Look for: `✓ Compiled /rules`
   - If you see errors, share them

2. **Browser Cache:**
   - Hard refresh: `Ctrl+Shift+R` (Windows) or `Cmd+Shift+R` (Mac)
   - Or use incognito/private window

3. **Direct URL Test:**
   - Visit: https://tantalus-boxing-club.vercel.app/rules
   - Check if it returns 200 OK or 404

## 📞 Need Help?

If the Rules page still doesn't appear after setting the root directory:

1. Check Vercel build logs for errors
2. Verify the latest deployment includes commit `ba358b5`
3. Test the direct URL: `/rules` (not `/login`)
4. Share the build logs if you see any errors

---

**Remember:** The Rules page is at `/rules`, not `/login`! 🎯

