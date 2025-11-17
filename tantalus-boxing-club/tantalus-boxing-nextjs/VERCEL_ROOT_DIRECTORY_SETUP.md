# Vercel Root Directory Setup - Step by Step

## 🎯 Goal: Configure Vercel to Deploy from Correct Directory

Your Next.js app is located at:
```
tantalus-boxing-club/tantalus-boxing-club/tantalus-boxing-nextjs/
```

## 📋 Step-by-Step Instructions

### Step 1: Access Vercel Dashboard

1. Open your browser
2. Go to: **https://vercel.com/dashboard**
3. Sign in if needed
4. Find and click on your project: **Tantalus-Boxing-Club**

### Step 2: Navigate to Settings

1. In your project dashboard, click **"Settings"** (top navigation bar)
2. In the left sidebar, click **"General"**

### Step 3: Configure Root Directory

1. Scroll down to find **"Root Directory"** section
2. Click the **"Edit"** button (or pencil icon) next to Root Directory
3. In the input field, enter:
   ```
   tantalus-boxing-club/tantalus-boxing-club/tantalus-boxing-nextjs
   ```
4. Click **"Save"** button

### Step 4: Verify Build Settings

While you're in Settings, also check **"Build & Development Settings"**:

1. Click **"Build & Development Settings"** in the left sidebar
2. Verify these settings:
   - **Framework Preset:** Next.js (should be auto-detected)
   - **Build Command:** `next build` (or leave as auto-detected)
   - **Output Directory:** `.next` (or leave as auto-detected)
   - **Install Command:** `npm install` (or leave as auto-detected)
3. If anything looks wrong, update it and click **"Save"**

### Step 5: Trigger New Deployment

1. Go to **"Deployments"** tab (top navigation)
2. Find the latest deployment
3. Click the **"..."** (three dots) menu on the right
4. Click **"Redeploy"**
5. In the popup:
   - ✅ Check **"Use existing Build Cache"** (optional, but faster)
   - Click **"Redeploy"**
6. Wait 2-3 minutes for deployment to complete

### Step 6: Verify Deployment

1. Watch the deployment progress
2. Wait for status to show **"Ready"** (green checkmark)
3. Click on the deployment to view details
4. Check **"Build Logs"** tab
5. Look for:
   ```
   ✓ Compiled /rules
   ```
   Or in the route list:
   ```
   Route (app)                              Size     First Load JS
   └ ○ /rules                                XX kB         XX kB
   ```

## ✅ Verification Checklist

After completing the steps above:

- [ ] Root Directory is set to: `tantalus-boxing-club/tantalus-boxing-club/tantalus-boxing-nextjs`
- [ ] Build settings are correct (Next.js framework)
- [ ] New deployment triggered and completed
- [ ] Build logs show `/rules` route compiled
- [ ] Deployment status is "Ready"

## 🧪 Testing the Rules Page

### Test 1: Direct URL Access

1. Open a new browser tab (or incognito/private window)
2. Visit: **https://tantalus-boxing-club.vercel.app/rules**
3. **Expected Result:**
   - ✅ Page loads (not 404 error)
   - ✅ Shows "Tantalus Boxing Club – Creative Fighter League" header
   - ✅ Shows Rules & Guidelines content
   - ✅ No console errors (F12 → Console tab)

### Test 2: Homepage Button

1. Visit: **https://tantalus-boxing-club.vercel.app/**
2. **Expected Result:**
   - ✅ "Rules & Guidelines" button is visible
   - ✅ Button is clickable
   - ✅ Clicking button navigates to `/rules`

### Test 3: Navigation Menu (When Logged In)

1. Log in to the application
2. Check the navigation menu
3. **Expected Result:**
   - ✅ "Rules" link is visible in the menu
   - ✅ Clicking "Rules" navigates to `/rules`

### Test 4: Browser Console

1. Open DevTools (F12)
2. Go to **Console** tab
3. Navigate to `/rules` page
4. **Expected Result:**
   - ✅ No CSP errors about Supabase
   - ✅ No 404 errors
   - ✅ No critical JavaScript errors

## 🔍 Troubleshooting

### If Rules Page Still Returns 404

1. **Check Build Logs:**
   - Go to Deployments → Latest → Build Logs
   - Look for errors or warnings
   - Verify `/rules` appears in compiled routes

2. **Verify Root Directory:**
   - Go back to Settings → General
   - Confirm Root Directory is exactly: `tantalus-boxing-club/tantalus-boxing-club/tantalus-boxing-nextjs`
   - No trailing slash, no extra spaces

3. **Clear Build Cache:**
   - Go to Settings → Build & Development Settings
   - Click "Clear Build Cache"
   - Trigger new deployment

4. **Check Git Connection:**
   - Go to Settings → Git
   - Verify connected repository is correct
   - Verify Production Branch is `main`

### If Build Fails

1. Check build logs for specific errors
2. Verify all environment variables are set:
   - `NEXT_PUBLIC_SUPABASE_URL`
   - `NEXT_PUBLIC_SUPABASE_ANON_KEY`
3. Check if there are TypeScript errors locally:
   ```bash
   npm run build
   ```

## 📸 Screenshot Locations

When setting Root Directory, you should see:

**Settings → General → Root Directory:**
```
Root Directory
tantalus-boxing-club/tantalus-boxing-club/tantalus-boxing-nextjs
[Edit] [Save]
```

**Deployments → Build Logs:**
```
Route (app)                              Size     First Load JS
└ ○ /rules                                12.5 kB        85.2 kB
```

## 🎉 Success Indicators

You'll know it's working when:

1. ✅ Root Directory is configured correctly
2. ✅ Build logs show `/rules` route
3. ✅ Direct URL `/rules` loads the page
4. ✅ Homepage shows "Rules & Guidelines" button
5. ✅ Navigation shows "Rules" link
6. ✅ No 404 errors in browser console

## 📞 Next Steps After Fix

Once the Rules page is working:

1. Test all navigation links
2. Verify Rules page content displays correctly
3. Test Rules page on mobile devices
4. Share the Rules page URL with team members
5. Update any documentation with the correct URL

---

**Remember:** The Rules page is at `/rules`, not `/login`! 🎯

