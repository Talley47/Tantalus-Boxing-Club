# 🚀 VERCEL DEPLOYMENT - QUICK START

## ✅ **READY TO DEPLOY TO VERCEL**

Your app is ready! Choose your method:

---

## **OPTION 1: Vercel Dashboard (Recommended)**

### **5-Minute Deployment:**

1. **Go to:** https://vercel.com
2. **Sign up/Login** (free)
3. **Click:** "Add New Project"
4. **Import Git Repository** (if you have code on GitHub/GitLab)
   - OR upload `build` folder manually
5. **Vercel auto-detects** React app
6. **Click:** "Deploy"
7. **Wait 1-2 minutes**
8. **Set Environment Variables:**
   - Project → Settings → Environment Variables
   - Add:
     - `REACT_APP_SUPABASE_URL` = your Supabase URL
     - `REACT_APP_SUPABASE_ANON_KEY` = your anon key
   - Select: Production, Preview, Development
   - Click "Save"
9. **Redeploy:** Deployments → Latest → Redeploy
10. **Done!** Visit your URL

---

## **OPTION 2: Vercel CLI**

### **Command Line Deployment:**

```bash
# 1. Install Vercel CLI
npm install -g vercel

# 2. Login
vercel login

# 3. Deploy
cd tantalus-boxing-club
vercel --prod

# 4. Set environment variables (after first deploy)
vercel env add REACT_APP_SUPABASE_URL
vercel env add REACT_APP_SUPABASE_ANON_KEY

# 5. Redeploy
vercel --prod
```

---

## ⚠️ **CRITICAL: Environment Variables**

**After deployment, add these:**

```
REACT_APP_SUPABASE_URL=https://your-project.supabase.co
REACT_APP_SUPABASE_ANON_KEY=your-anon-key-here
```

**Location:** Vercel Dashboard → Project → Settings → Environment Variables

**Important:** Redeploy after adding!

---

## ✅ **VERIFY**

After deployment:
- Visit your Vercel URL
- Check site loads
- Test login/registration
- Verify HTTPS active
- Check browser console (no errors)

---

## 🎉 **YOU'RE LIVE!**

Your app will be available at: `your-project.vercel.app`

**Need help?** See `VERCEL_DEPLOYMENT.md` for detailed guide.

