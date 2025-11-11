# ⚠️ SETUP REQUIRED - Action Needed!

## 🚨 Your Supabase credentials need to be configured

The `.env.local` file exists but contains placeholder values. You need to update it with your **actual Supabase credentials**.

## 📝 Quick Setup (5 minutes)

### Step 1: Get Your Supabase Credentials

1. Go to **[https://supabase.com/dashboard](https://supabase.com/dashboard)**
2. **Create a new project** (or select existing):
   - Click "New Project"
   - Name: "Tantalus Boxing Club"
   - Database Password: (create a secure password)
   - Region: (choose closest to you)
   - Click "Create new project"
   - Wait 2 minutes for setup

3. Once created, go to **Settings** → **API**
4. Copy these two values:
   - **Project URLMenu`https://xxxxxxxxxxxxx.supabase.co`
   - **anon public key**: (long string under "Project API keys")

### Step 2: Update .env.local File

1. Open the file: `tantalus-boxing-club/.env.local`
2. Replace the placeholder values:

**Before:**
```env
REACT_APP_SUPABASE_URL=YOUR_SUPABASE_URL_HERE
REACT_APP_SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY_HERE
```

**After (with your actual values):**
```env
REACT_APP_SUPABASE_URL=https://abcdefghijklmnop.supabase.co
REACT_APP_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFiY2RlZmdoaWprbG1ub3AiLCJyb2xlIjoiYW5vbiIsImlhdCI6MTYxNjMxMzQ4NywiZXhwIjoxOTMxODg5NDg3fQ.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

3. Save the file

### Step 3: Set Up Database Schema

1. In Supabase dashboard, go to **SQL Editor**
2. Click "New Query"
3. Open: `tantalus-boxing-club/database/schema-fixed.sql`
4. Copy the entire file contents
5. Paste into Supabase SQL Editor
6. Click "Run" to execute

### Step 4: Create Admin Account

Run in terminal:
```bash
cd tantalus-boxing-club
node create-admin.js
```

You should see: ` Admin account created successfully!`

### Step 5: Start the App

```bash
npm start
```

### Step 6: Test Login

1. Go to `http://localhost:3000`
2. Login with:
   - Email: `admin@tantalusboxing.com`
   - Password: `TantalusAdmin2025!`

## ✅ You're Done!

Once you can log in successfully, the app is ready to use!

---

## 🆘 Troubleshooting

### "Cannot connect to Supabase"
- Make sure you copied the **full** Project URL (must start with `https://`)
- Ensure there are no spaces or quotes around the values
- Restart the dev server after updating `.env.local`

### "Admin account already exists"
- This is fine! Just try logging in

### "Database error"
- Make sure you ran the SQL schema in Supabase
- Check that your Supabase project is not paused (free tier auto-pauses)

---

## 📞 Current Status

Based on the verification script:
- ✅ `.env.local` file exists
- ❌ **Contains placeholder values - needs update**
- ✅ All other files are ready

**You just need to update `.env.local` with your Supabase credentials!**


