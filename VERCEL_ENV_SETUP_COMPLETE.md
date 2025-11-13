# ✅ Vercel Environment Variables - Complete Setup Guide

## 🎯 **Quick Setup**

After your Vercel build completes, follow these steps:

---

## 📋 **Step-by-Step Instructions**

### **1. Go to Vercel Dashboard**

1. Visit: **https://vercel.com/dashboard**
2. Sign in to your account
3. Find your project: **`Tantalus-Boxing-Club`** (or similar name)
4. Click on the project

---

### **2. Navigate to Environment Variables**

1. Click: **"Settings"** tab (top navigation bar)
2. Click: **"Environment Variables"** (left sidebar)
3. You'll see a list of existing variables (if any)

---

### **3. Add First Variable: REACT_APP_SUPABASE_URL**

1. Click: **"Add New"** button (top right)
2. Fill in:
   - **Key:** `REACT_APP_SUPABASE_URL`
   - **Value:** `https://andmtvsqqomgwphotdwf.supabase.co`
   - **Environment:** Select all three:
     - ✅ Production
     - ✅ Preview  
     - ✅ Development
3. Click: **"Save"**

---

### **4. Add Second Variable: REACT_APP_SUPABASE_ANON_KEY**

1. Click: **"Add New"** button again
2. Fill in:
   - **Key:** `REACT_APP_SUPABASE_ANON_KEY`
   - **Value:** `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFuZG10dnNxcW9tZ3dwaG90ZHdmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5OTQwMTcsImV4cCI6MjA3ODM1NDAxN30.KMkOUaaf61Wsfk3HoMgbDTetBj-dhgtJsj453aCrJSo`
   - **Environment:** Select all three:
     - ✅ Production
     - ✅ Preview
     - ✅ Development
3. Click: **"Save"**

---

### **5. Redeploy Your Application**

**Important:** Environment variables only take effect after redeployment!

1. Go to: **"Deployments"** tab (top navigation)
2. Find your latest deployment
3. Click: **"..."** (three dots menu) on the right
4. Click: **"Redeploy"**
5. Confirm: Click **"Redeploy"** again in the popup
6. Wait: Deployment will take 1-2 minutes

---

## ✅ **Verify Setup**

After redeployment completes:

1. **Visit your Vercel URL:**
   - Format: `your-project-name.vercel.app`
   - Or check the "Domains" section in Settings

2. **Test the application:**
   - Open browser DevTools (F12)
   - Go to Console tab
   - Check for any Supabase connection errors
   - Try logging in or registering

3. **Verify environment variables:**
   - In Vercel Dashboard → Settings → Environment Variables
   - You should see both variables listed
   - They should be available for Production, Preview, and Development

---

## ⚠️ **Important Notes**

### **DO NOT Add:**
- ❌ `SUPABASE_SERVICE_ROLE_KEY` - This is server-side only and should NEVER be in client-side code or Vercel environment variables

### **Why These Variables?**
- `REACT_APP_SUPABASE_URL` - Your Supabase project URL (public)
- `REACT_APP_SUPABASE_ANON_KEY` - Public anon key (safe for client-side, protected by RLS)

---

## 🔍 **Troubleshooting**

### **If app shows "Invalid API key":**
- Verify you copied the new anon key (not the old one)
- Check for extra spaces when pasting
- Make sure variable name is exactly: `REACT_APP_SUPABASE_ANON_KEY`
- Redeploy after adding variables

### **If app doesn't connect to Supabase:**
- Check browser console for specific errors
- Verify `REACT_APP_SUPABASE_URL` is correct
- Make sure you selected all environments (Production, Preview, Development)
- Try redeploying again

### **If variables don't appear:**
- Refresh the Vercel dashboard
- Check you're in the correct project
- Verify you clicked "Save" after adding each variable

---

## 📊 **Expected Result**

After setup:
- ✅ Environment variables are set in Vercel
- ✅ Application redeployed with new variables
- ✅ App connects to Supabase successfully
- ✅ Login/registration works
- ✅ No console errors

---

## 🎉 **You're Done!**

Your application should now be:
- ✅ Secured (old keys invalidated)
- ✅ Deployed (on Vercel)
- ✅ Configured (environment variables set)
- ✅ Ready to use!

---

**Need Help?** Check `VERCEL_ENV_VARIABLES.md` for more details.

