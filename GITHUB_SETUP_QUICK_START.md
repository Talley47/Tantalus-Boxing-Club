# ⚡ GitHub Setup - Quick Start Guide

## ✅ **READY TO GO!**

Your repository is committed and ready. Follow these 3 simple steps:

---

## 📝 **STEP 1: Create GitHub Repository** (2 minutes)

1. Go to: **https://github.com** and sign in
2. Click: **"+"** → **"New repository"**
3. Name: `tantalus-boxing-club`
4. Description: `Tantalus Boxing Club - Boxing League Management App`
5. Choose: **Public** or **Private**
6. **DO NOT** check "Initialize with README"
7. Click: **"Create repository"**

---

## 🚀 **STEP 2: Connect & Push** (1 minute)

### **Easiest Method - Use Script:**

1. **Open** `connect-to-github.ps1` (or `connect-to-github.bat`)
2. **Replace** `YOUR_USERNAME` with your GitHub username (line 6)
3. **Run** the script:
   ```powershell
   .\connect-to-github.ps1
   ```

### **Manual Method - Copy & Paste:**

**Replace `YOUR_USERNAME` with your GitHub username:**

```bash
git remote add origin https://github.com/YOUR_USERNAME/tantalus-boxing-club.git
git branch -M main
git push -u origin main
```

---

## 🔐 **STEP 3: Authenticate** (2 minutes)

When prompted for password, use a **Personal Access Token**:

1. Go to: **https://github.com/settings/tokens**
2. Click: **"Generate new token (classic)"**
3. Name: `Tantalus Deployment`
4. Select: ✅ **`repo`** scope
5. Click: **"Generate token"**
6. **Copy the token** and paste it as your password

---

## ✅ **DONE!**

Visit: `https://github.com/YOUR_USERNAME/tantalus-boxing-club`

Your code is now on GitHub! 🎉

---

## 🚀 **Next: Deploy to Vercel**

See `VERCEL_DEPLOYMENT.md` for deployment instructions.

---

## 📚 **Need More Help?**

- **Detailed guide:** `GITHUB_CONNECTION_COMMANDS.md`
- **Original guide:** `CREATE_GITHUB_REPO.md`
- **Troubleshooting:** See `GITHUB_CONNECTION_COMMANDS.md` → Troubleshooting section

