# 🚀 Vercel Environment Variables - Step-by-Step Guide

## ✅ **Ready to Set Up**

Your Git history is cleaned and your build should be completing. Follow these exact steps:

---

## 📋 **STEP 1: Access Vercel Dashboard**

1. **Go to:** https://vercel.com/dashboard
2. **Sign in** (if not already)
3. **Find your project:** Look for `Tantalus-Boxing-Club` or similar
4. **Click** on the project name

---

## 📋 **STEP 2: Navigate to Environment Variables**

1. **Click:** **"Settings"** tab (top navigation bar)
2. **Click:** **"Environment Variables"** (in left sidebar under "Configuration")
3. You should see an empty list or existing variables

---

## 📋 **STEP 3: Add REACT_APP_SUPABASE_URL**

1. **Click:** **"Add New"** button (top right, blue button)

2. **Fill in the form:**
   ```
   Key: REACT_APP_SUPABASE_URL
   Value: https://andmtvsqqomgwphotdwf.supabase.co
   ```

3. **Select Environments:**
   - ✅ Check **"Production"**
   - ✅ Check **"Preview"**
   - ✅ Check **"Development"**
   
   (Select all three!)

4. **Click:** **"Save"** button

5. **Verify:** You should see the variable appear in the list

---

## 📋 **STEP 4: Add REACT_APP_SUPABASE_ANON_KEY**

1. **Click:** **"Add New"** button again

2. **Fill in the form:**
   ```
   Key: REACT_APP_SUPABASE_ANON_KEY
   Value: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFuZG10dnNxcW9tZ3dwaG90ZHdmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5OTQwMTcsImV4cCI6MjA3ODM1NDAxN30.KMkOUaaf61Wsfk3HoMgbDTetBj-dhgtJsj453aCrJSo
   ```

3. **Select Environments:**
   - ✅ Check **"Production"**
   - ✅ Check **"Preview"**
   - ✅ Check **"Development"**
   
   (Select all three!)

4. **Click:** **"Save"** button

5. **Verify:** You should see both variables in the list

---

## 📋 **STEP 5: Redeploy Your Application**

**⚠️ CRITICAL:** Environment variables only take effect after redeployment!

### **Option A: Redeploy Latest Deployment**

1. **Click:** **"Deployments"** tab (top navigation)
2. **Find** your latest deployment (should be at the top)
3. **Click:** **"..."** (three dots menu) on the right side of the deployment
4. **Click:** **"Redeploy"** from the dropdown menu
5. **Confirm:** Click **"Redeploy"** in the popup
6. **Wait:** Deployment will take 1-2 minutes

### **Option B: Trigger New Deployment**

1. **Make a small change** to trigger a new deployment, OR
2. **Push a new commit** to GitHub (Vercel will auto-deploy)

---

## ✅ **STEP 6: Verify Everything Works**

After redeployment completes:

1. **Visit your Vercel URL:**
   - Check the "Domains" section in Settings
   - Or look at the deployment URL (e.g., `your-project.vercel.app`)

2. **Open Browser DevTools:**
   - Press **F12** or right-click → "Inspect"
   - Go to **Console** tab

3. **Check for errors:**
   - Should see no Supabase connection errors
   - Should see no "Invalid API key" errors

4. **Test your app:**
   - Try logging in
   - Try registering a new account
   - Verify features work

---

## 📊 **What You Should See**

### **In Vercel Dashboard:**

```
Environment Variables:
├── REACT_APP_SUPABASE_URL
│   └── Production, Preview, Development
└── REACT_APP_SUPABASE_ANON_KEY
    └── Production, Preview, Development
```

### **In Your App:**

- ✅ App loads without errors
- ✅ Supabase connection works
- ✅ Login/registration functions
- ✅ No console errors

---

## 🔍 **Troubleshooting**

### **Problem: Variables don't appear after saving**
- **Solution:** Refresh the page and check again
- **Solution:** Make sure you clicked "Save" (not just closed the modal)

### **Problem: App still shows "Invalid API key"**
- **Solution:** Make sure you redeployed after adding variables
- **Solution:** Verify you copied the NEW anon key (not the old one)
- **Solution:** Check for extra spaces when pasting

### **Problem: Can't find "Environment Variables" option**
- **Solution:** Make sure you're in Settings tab
- **Solution:** Look in left sidebar under "Configuration"
- **Solution:** You need to be project owner/admin

### **Problem: Redeploy button is grayed out**
- **Solution:** Wait for current deployment to finish
- **Solution:** Check if you have deployment permissions
- **Solution:** Try triggering a new deployment via Git push

---

## ⚠️ **Important Reminders**

1. **DO NOT add `SUPABASE_SERVICE_ROLE_KEY`** - This is server-side only!

2. **Select ALL environments** (Production, Preview, Development) - This ensures it works everywhere

3. **Redeploy after adding variables** - They don't take effect until you redeploy

4. **Use the NEW anon key** - Not the old exposed one

---

## ✅ **Checklist**

- [ ] Added `REACT_APP_SUPABASE_URL` to Vercel
- [ ] Added `REACT_APP_SUPABASE_ANON_KEY` to Vercel
- [ ] Selected all environments (Production, Preview, Development)
- [ ] Redeployed the application
- [ ] Verified app loads without errors
- [ ] Tested login/registration
- [ ] Checked browser console for errors

---

## 🎉 **You're Done!**

Once you complete these steps:
- ✅ Your app is secured (old keys invalidated)
- ✅ Your app is deployed (on Vercel)
- ✅ Your app is configured (environment variables set)
- ✅ Your app is ready to use!

---

**Need Help?** 
- Vercel Docs: https://vercel.com/docs/concepts/projects/environment-variables
- Vercel Support: https://vercel.com/support

