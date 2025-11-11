# 🚀 VERCEL DEPLOYMENT GUIDE

## ✅ **PRE-DEPLOYMENT CHECKLIST**

- ✅ Build folder ready (`build/`)
- ✅ Security headers configured (`vercel.json`)
- ✅ Environment variables prepared
- ✅ All files ready

---

## 🎯 **VERCEL DEPLOYMENT - STEP BY STEP**

### **METHOD 1: Vercel Dashboard (Easiest)**

#### **Step 1: Create Vercel Account**
1. Go to: https://vercel.com
2. Click "Sign Up" (free account)
3. Sign up with GitHub, GitLab, or email

#### **Step 2: Create New Project**
1. Click "Add New Project"
2. Choose one:
   - **Option A:** Import Git Repository (if you have code on GitHub/GitLab)
   - **Option B:** Upload `build` folder manually (see Method 2)

#### **Step 3: Configure Project (If Using Git)**
1. Select your repository
2. Vercel auto-detects React app
3. Build settings (usually auto-filled):
   - **Framework Preset:** Create React App
   - **Build Command:** `npm run build`
   - **Output Directory:** `build`
   - **Install Command:** `npm install`
4. Click "Deploy"

#### **Step 4: Set Environment Variables**
**CRITICAL:** After first deployment:

1. Go to your project dashboard
2. Click "Settings" → "Environment Variables"
3. Add these variables:

   **Variable 1:**
   - Name: `REACT_APP_SUPABASE_URL`
   - Value: `https://your-project.supabase.co`
   - Environment: Production, Preview, Development (select all)

   **Variable 2:**
   - Name: `REACT_APP_SUPABASE_ANON_KEY`
   - Value: `your-anon-key-here`
   - Environment: Production, Preview, Development (select all)

4. Click "Save"
5. Go to "Deployments" tab
6. Click "Redeploy" on latest deployment

#### **Step 5: Get Your URL**
- Vercel provides URL immediately: `your-project.vercel.app`
- You can also add custom domain later

---

### **METHOD 2: Vercel CLI (Command Line)**

#### **Step 1: Install Vercel CLI**
```bash
npm install -g vercel
```

#### **Step 2: Login to Vercel**
```bash
vercel login
```
Follow prompts to authenticate.

#### **Step 3: Deploy**
```bash
cd tantalus-boxing-club
vercel --prod
```

#### **Step 4: Follow Prompts**
- Link to existing project? → No (first time) or Yes (if updating)
- Project name? → `tantalus-boxing-club` (or your choice)
- Directory? → `./build` (or just press Enter)
- Override settings? → No

#### **Step 5: Set Environment Variables**
After deployment, set environment variables:

**Option A: Via CLI**
```bash
vercel env add REACT_APP_SUPABASE_URL
# Paste your Supabase URL when prompted
# Select: Production, Preview, Development

vercel env add REACT_APP_SUPABASE_ANON_KEY
# Paste your anon key when prompted
# Select: Production, Preview, Development
```

**Option B: Via Dashboard**
1. Go to Vercel dashboard
2. Project → Settings → Environment Variables
3. Add both variables (see Method 1, Step 4)

#### **Step 6: Redeploy**
```bash
vercel --prod
```

---

### **METHOD 3: Manual Upload (Alternative)**

If you prefer to upload the build folder directly:

1. Go to Vercel dashboard
2. Click "Add New Project"
3. Look for "Upload" option (if available)
4. Upload `build` folder contents
5. Set environment variables in dashboard
6. Deploy

---

## ⚠️ **CRITICAL: Environment Variables**

**You MUST add these after deployment:**

```
REACT_APP_SUPABASE_URL=https://your-project.supabase.co
REACT_APP_SUPABASE_ANON_KEY=your-anon-key-here
```

**Get values from:**
- Supabase Dashboard → Settings → API

**Where to add:**
- Vercel Dashboard → Project → Settings → Environment Variables

**Important:**
- Add to Production, Preview, AND Development environments
- Redeploy after adding variables

---

## ✅ **VERIFY DEPLOYMENT**

After deployment:

1. **Visit your Vercel URL** (e.g., `your-project.vercel.app`)

2. **Check:**
   - ✅ Site loads correctly
   - ✅ HTTPS active (🔒 in URL bar)
   - ✅ No console errors (F12 → Console)
   - ✅ Login page works
   - ✅ Can register account
   - ✅ All features work

3. **Test Security Headers:**
   ```bash
   curl -I https://your-project.vercel.app
   ```
   Should see security headers configured.

4. **Online Security Check:**
   - Visit: https://securityheaders.com
   - Enter your Vercel URL
   - Should score A or A+

---

## 🔧 **TROUBLESHOOTING**

### **"Missing environment variables" Error**
- Environment variables not set
- Add them in Vercel dashboard
- Redeploy after adding

### **"Build failed"**
- Check build logs in Vercel dashboard
- Verify `package.json` has correct build script
- Check for TypeScript/compilation errors

### **"Blank page"**
- Check browser console for errors
- Verify environment variables are set correctly
- Check Vercel deployment logs

### **"API errors"**
- Verify Supabase URL/key are correct
- Check Supabase project is active
- Verify environment variables are set

---

## 📋 **POST-DEPLOYMENT CHECKLIST**

After deployment:

- [ ] Site loads correctly
- [ ] HTTPS active
- [ ] Environment variables set
- [ ] Login works
- [ ] Registration works
- [ ] No console errors
- [ ] Security headers verified
- [ ] All features tested

---

## 🎉 **SUCCESS!**

Once deployed:
- ✅ Your app is live at `your-project.vercel.app`
- ✅ Share URL with users
- ✅ Set up custom domain (optional)
- ✅ Monitor deployments in Vercel dashboard

---

## 🚀 **QUICK START COMMANDS**

```bash
# Install Vercel CLI
npm install -g vercel

# Login
vercel login

# Deploy
cd tantalus-boxing-club
vercel --prod

# Set environment variables (after first deploy)
vercel env add REACT_APP_SUPABASE_URL
vercel env add REACT_APP_SUPABASE_ANON_KEY

# Redeploy
vercel --prod
```

---

## 📚 **ADDITIONAL RESOURCES**

- **Vercel Docs:** https://vercel.com/docs
- **React Deployment:** https://vercel.com/docs/frameworks/create-react-app
- **Environment Variables:** https://vercel.com/docs/concepts/projects/environment-variables

---

**Ready to deploy? Follow Method 1 (Dashboard) for easiest deployment! 🚀**

