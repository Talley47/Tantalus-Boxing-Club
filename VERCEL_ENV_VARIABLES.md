# 🔐 Vercel Environment Variables Setup

## ✅ **After Your Build Completes**

Set these environment variables in Vercel:

---

## 📋 **Environment Variables to Add**

### **1. REACT_APP_SUPABASE_URL**

- **Name:** `REACT_APP_SUPABASE_URL`
- **Value:** `https://andmtvsqqomgwphotdwf.supabase.co`
- **Environment:** ✅ Production, ✅ Preview, ✅ Development

---

### **2. REACT_APP_SUPABASE_ANON_KEY**

- **Name:** `REACT_APP_SUPABASE_ANON_KEY`
- **Value:** `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFuZG10dnNxcW9tZ3dwaG90ZHdmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5OTQwMTcsImV4cCI6MjA3ODM1NDAxN30.KMkOUaaf61Wsfk3HoMgbDTetBj-dhgtJsj453aCrJSo`
- **Environment:** ✅ Production, ✅ Preview, ✅ Development

---

## ⚠️ **DO NOT ADD**

- ❌ **SUPABASE_SERVICE_ROLE_KEY** - This is server-side only and should NEVER be in client-side code or Vercel environment variables

---

## 📝 **Step-by-Step Instructions**

1. **Go to Vercel Dashboard:**
   - Visit: https://vercel.com/dashboard
   - Sign in

2. **Select Your Project:**
   - Find: `Tantalus-Boxing-Club` or `Tantalus-Boxing-Club`
   - Click on it

3. **Navigate to Settings:**
   - Click: **Settings** tab (top navigation)
   - Click: **Environment Variables** (left sidebar)

4. **Add First Variable:**
   - Click: **"Add New"** button
   - **Key:** `REACT_APP_SUPABASE_URL`
   - **Value:** `https://andmtvsqqomgwphotdwf.supabase.co`
   - **Environment:** Select all (Production, Preview, Development)
   - Click: **Save**

5. **Add Second Variable:**
   - Click: **"Add New"** button again
   - **Key:** `REACT_APP_SUPABASE_ANON_KEY`
   - **Value:** `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFuZG10dnNxcW9tZ3dwaG90ZHdmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5OTQwMTcsImV4cCI6MjA3ODM1NDAxN30.KMkOUaaf61Wsfk3HoMgbDTetBj-dhgtJsj453aCrJSo`
   - **Environment:** Select all (Production, Preview, Development)
   - Click: **Save**

6. **Redeploy:**
   - Go to: **Deployments** tab
   - Click: **"..."** (three dots) on the latest deployment
   - Click: **"Redeploy"**
   - This applies the new environment variables

---

## ✅ **Verify Deployment**

After redeploying:

1. **Visit your Vercel URL** (e.g., `your-project.vercel.app`)
2. **Check browser console** (F12) for errors
3. **Test login/registration** functionality
4. **Verify** no Supabase connection errors

---

## 🔍 **Troubleshooting**

### **If app doesn't work:**
- Check environment variables are set correctly
- Verify you selected all environments (Production, Preview, Development)
- Make sure you redeployed after adding variables
- Check browser console for specific errors

### **If you see "Invalid API key":**
- Verify you copied the new anon key (not the old one)
- Check for extra spaces when pasting
- Make sure variable name is exactly: `REACT_APP_SUPABASE_ANON_KEY`

---

**Status:** ⚠️ **ACTION REQUIRED** - Set these after build completes

