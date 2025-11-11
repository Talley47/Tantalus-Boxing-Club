# 🚀 PRODUCTION DEPLOYMENT GUIDE

## 📋 **PRE-DEPLOYMENT CHECKLIST**

Before deploying, verify these items:

### **Critical Items** ✅
- [x] Production build successful (`npm run build`)
- [x] Security headers configured (`_headers`, `vercel.json`)
- [x] Environment variables configured (`.env.local`)
- [x] Hardcoded keys removed
- [ ] RLS policies verified (run SQL script in Supabase)
- [ ] Supabase Auth configured (email confirmations, password requirements)
- [ ] Rate limiting enabled in Supabase

### **Important Items** ⚠️
- [ ] Production build tested locally (`npx serve -s build`)
- [ ] `security.txt` updated with your domain
- [ ] `npm audit` reviewed (vulnerabilities are dev-only, acceptable)

---

## 🎯 **DEPLOYMENT OPTIONS**

Choose your hosting provider:

### **Option 1: Netlify** (Recommended for React apps)
### **Option 2: Vercel** (Great for React apps)
### **Option 3: Other** (AWS, Azure, etc.)

---

## 📦 **DEPLOYMENT STEPS**

### **STEP 1: Final Preparation**

1. **Verify build folder exists:**
   ```bash
   cd tantalus-boxing-club
   ls build  # Should show static files
   ```

2. **Ensure .env.local is NOT in build:**
   - `.env.local` should NOT be in `build/` folder
   - It's already in `.gitignore` ✅

3. **Update security.txt** (if not done):
   - Edit `public/security.txt`
   - Replace `yourdomain.com` with your actual domain

---

### **STEP 2: Choose Deployment Method**

#### **Method A: Netlify (Drag & Drop)**

1. **Go to:** https://app.netlify.com
2. **Sign up/Login** (free account)
3. **Drag & Drop:**
   - Drag the entire `build` folder to Netlify dashboard
   - Or click "Add new site" → "Deploy manually"
4. **Configure:**
   - Site name: `tantalus-boxing-club` (or your choice)
   - Wait for deployment (1-2 minutes)
5. **Set Environment Variables:**
   - Go to Site Settings → Environment Variables
   - Add:
     - `REACT_APP_SUPABASE_URL` = your Supabase URL
     - `REACT_APP_SUPABASE_ANON_KEY` = your anon key
   - Redeploy after adding variables

#### **Method B: Netlify (Git Integration)**

1. **Push to GitHub/GitLab:**
   ```bash
   git add .
   git commit -m "Production build ready"
   git push origin main
   ```

2. **Connect to Netlify:**
   - Go to Netlify → Add new site → Import from Git
   - Connect your repository
   - Build settings:
     - Build command: `npm run build`
     - Publish directory: `build`
   - Add environment variables (same as Method A)

#### **Method C: Vercel**

1. **Install Vercel CLI:**
   ```bash
   npm install -g vercel
   ```

2. **Deploy:**
   ```bash
   cd tantalus-boxing-club
   vercel
   ```

3. **Follow prompts:**
   - Link to existing project or create new
   - Set environment variables when prompted
   - Deploy!

4. **Or use Vercel Dashboard:**
   - Go to: https://vercel.com
   - Import Git repository
   - Vercel auto-detects React app
   - Add environment variables in dashboard

---

### **STEP 3: Configure Environment Variables**

**CRITICAL:** Add these in your hosting provider's dashboard:

1. **Netlify:**
   - Site Settings → Environment Variables → Add variable
   - Add both:
     - `REACT_APP_SUPABASE_URL`
     - `REACT_APP_SUPABASE_ANON_KEY`
   - Click "Redeploy site" after adding

2. **Vercel:**
   - Project Settings → Environment Variables
   - Add both variables
   - Redeploy

3. **Other Providers:**
   - Find "Environment Variables" or "Config Vars" section
   - Add both variables

**⚠️ IMPORTANT:** 
- Use your PRODUCTION Supabase keys (same as `.env.local`)
- Never commit these to Git
- Redeploy after adding variables

---

### **STEP 4: Verify Deployment**

After deployment completes:

1. **Visit your site URL** (provided by hosting provider)

2. **Check these:**
   - [ ] Site loads correctly
   - [ ] HTTPS is active (check URL bar for 🔒)
   - [ ] No console errors (F12 → Console)
   - [ ] Login page works
   - [ ] Can register new account

3. **Verify Security Headers:**
   ```bash
   curl -I https://yourdomain.com
   ```
   Should see:
   - `X-Frame-Options: DENY`
   - `X-Content-Type-Options: nosniff`
   - `Strict-Transport-Security: ...`

4. **Test Security:**
   - Visit: https://securityheaders.com
   - Enter your domain
   - Should score A or A+

---

### **STEP 5: Post-Deployment Configuration**

#### **Configure Supabase Auth** (if not done):
1. Supabase Dashboard → Authentication → Settings
2. Enable:
   - Email confirmations: ON
   - Password requirements: 8+ chars, uppercase, lowercase, numbers

#### **Enable Rate Limiting** (if not done):
1. Supabase Dashboard → Settings → API
2. Enable rate limiting
3. Set limits (100/min anonymous, 200/min authenticated)

#### **Verify RLS Policies** (if not done):
1. Supabase Dashboard → SQL Editor
2. Run `database/verify-rls-security.sql`
3. Verify all tables have RLS enabled

---

## 🔧 **TROUBLESHOOTING**

### **Site Shows Blank Page**
- Check browser console for errors
- Verify environment variables are set correctly
- Check build folder was deployed correctly
- Verify Supabase URL/key are correct

### **"Missing Supabase environment variables" Error**
- Environment variables not set in hosting provider
- Add them in hosting dashboard
- Redeploy after adding

### **API Errors / CORS Issues**
- Verify Supabase project is active
- Check Supabase URL is correct
- Verify API key is correct
- Check Supabase project settings

### **Build Fails on Hosting Provider**
- Check build logs in hosting dashboard
- Verify `package.json` has correct build script
- Check Node.js version compatibility
- Review error messages in build logs

---

## 📊 **DEPLOYMENT CHECKLIST**

Before going live:

- [ ] Production build tested locally
- [ ] Environment variables set in hosting provider
- [ ] Site deployed successfully
- [ ] HTTPS active (🔒 in URL bar)
- [ ] Site loads correctly
- [ ] Login/registration works
- [ ] No console errors
- [ ] Security headers verified
- [ ] RLS policies verified
- [ ] Supabase Auth configured
- [ ] Rate limiting enabled

---

## 🎉 **SUCCESS!**

Once all items are checked:
- ✅ Your app is live!
- ✅ Share your URL with users
- ✅ Monitor for any issues
- ✅ Set up monitoring (optional)

---

## 📚 **QUICK REFERENCE**

- **Build Command:** `npm run build`
- **Publish Directory:** `build`
- **Environment Variables:** `REACT_APP_SUPABASE_URL`, `REACT_APP_SUPABASE_ANON_KEY`
- **Security Headers:** Already configured (`_headers`, `vercel.json`)

---

**Ready to deploy?** Choose your hosting provider and follow the steps above!

