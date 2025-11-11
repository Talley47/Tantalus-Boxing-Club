# 🧪 PRODUCTION BUILD TEST GUIDE

## Step-by-Step Instructions

### **Step 1: Build Production Version**

Open terminal in `tantalus-boxing-club` directory and run:

```bash
npm run build
```

**What to expect:**
- Build process will take 1-3 minutes
- You should see: `Compiled successfully!`
- A `build/` folder will be created

**If you see errors:**
- Fix any TypeScript/compilation errors
- Check console for specific issues
- Common issues: Missing imports, type errors

---

### **Step 2: Test Production Build Locally**

After build completes, serve it locally:

```bash
npx serve -s build
```

**What to expect:**
- Server starts on `http://localhost:3000` (or similar port)
- You'll see: `Serving!` with a localhost URL

**If `serve` is not installed:**
```bash
npm install -g serve
# Then run: npx serve -s build
```

---

### **Step 3: Test the Application**

Open your browser and go to the URL shown (usually `http://localhost:3000`)

**Test Checklist:**

#### **Basic Functionality** ✅
- [ ] Page loads without errors
- [ ] No console errors (F12 → Console)
- [ ] No blank screens
- [ ] Navigation works

#### **Authentication** 🔐
- [ ] Can access login page
- [ ] Can access registration page
- [ ] Login works (if you have test account)
- [ ] Registration works (test signup)

#### **Main Features** 🎯
- [ ] Home page loads correctly
- [ ] Fighter profile page works
- [ ] Matchmaking page loads
- [ ] Rankings display correctly
- [ ] Social/Chat page works

#### **Security** 🔒
- [ ] Environment variables loaded (check Network tab)
- [ ] API calls go to correct Supabase URL
- [ ] No hardcoded keys visible in source

#### **Performance** ⚡
- [ ] Page loads quickly
- [ ] No excessive loading times
- [ ] Images/assets load correctly

---

### **Step 4: Check Browser Console**

Press **F12** → **Console** tab

**What to look for:**
- ✅ No red errors
- ✅ No warnings about missing environment variables
- ✅ No API connection errors
- ⚠️ Browser extension errors are OK (can ignore)

**Common Issues:**

**"Missing Supabase environment variables"**
- Check `.env.local` exists
- Verify variables are set correctly
- Restart dev server if needed

**"Failed to fetch" or CORS errors**
- Check Supabase URL is correct
- Verify Supabase project is active
- Check network tab for specific errors

**"Module not found" errors**
- Run `npm install` again
- Check all imports are correct
- Verify file paths

---

### **Step 5: Test Production-Specific Features**

#### **Environment Variables**
- Verify app connects to Supabase
- Check Network tab → Supabase requests succeed
- No "undefined" values in API calls

#### **Security Headers** (After deployment)
- Headers will be active after deployment
- Can't test locally, but verify files exist:
  - `public/_headers` (for Netlify)
  - `vercel.json` (for Vercel)

#### **Build Size**
- Check `build/` folder size
- Should be reasonable (typically 1-5 MB)
- Large builds (>10MB) may need optimization

---

### **Step 6: Stop Test Server**

When done testing:
- Press **Ctrl+C** in terminal to stop server

---

## ✅ **SUCCESS CRITERIA**

Production build is ready if:
- ✅ Build completes without errors
- ✅ App loads and functions correctly
- ✅ No console errors (except browser extensions)
- ✅ All main features work
- ✅ Authentication works
- ✅ API connections succeed

---

## 🐛 **TROUBLESHOOTING**

### **Build Fails**
```bash
# Clear cache and rebuild
rm -rf node_modules build
npm install
npm run build
```

### **App Doesn't Load**
- Check terminal for errors
- Verify port isn't already in use
- Try different port: `npx serve -s build -l 3001`

### **API Errors**
- Verify `.env.local` has correct values
- Check Supabase project is active
- Verify network connectivity

### **Missing Assets**
- Check `public/` folder files are included
- Verify file paths are correct
- Check `build/` folder contains assets

---

## 📋 **TEST RESULTS TEMPLATE**

After testing, note:

```
✅ Build: Success/Failed
✅ Load: Success/Failed
✅ Login: Success/Failed
✅ Features: All working / Issues found
✅ Console Errors: None / List errors
✅ Performance: Good / Slow
```

---

**Ready to test?** Run the commands above and let me know the results!

