# 🚨 COMPLETE SETUP GUIDE - Fix All Issues

## 🎯 CRITICAL ISSUES IDENTIFIED

1. **Supabase Not Configured** - No environment variables set
2. **Database Schema Not Set Up** - Tables don't exist
3. **Admin Account Missing** - No default admin created
4. **App Not Working** - Registration fails, loops back

## ✅ STEP-BY-STEP SOLUTION

### STEP 1: Configure Supabase Environment Variables

**Create `.env.local` file in `tantalus-boxing-club` directory:**

```bash
# Get these values from your Supabase project dashboard
REACT_APP_SUPABASE_URL=https://your-project-id.supabase.co
REACT_APP_SUPABASE_ANON_KEY=your-anon-key-here
```

**How to get your Supabase credentials:**
1. Go to https://supabase.com/dashboard
2. Select your project (or create one if you don't have one)
3. Go to **Settings** → **API**
4. Copy:
   - **Project URL** → Use as `REACT_APP_SUPABASE_URL`
   - **anon public** key → Use as `REACT_APP_SUPABASE_ANON_KEY`

### STEP 2: Set Up Database Schema

1. In your Supabase dashboard, go to **SQL Editor**
2. Copy the entire contents of `database/schema-fixed.sql`
3. Paste it into the SQL Editor
4. Click **Run** to execute the schema
5. Verify tables are created (check **Table Editor**)

### STEP 3: Create Admin Account

**Option A: Using the Script (Recommended)**
```bash
# In the tantalus-boxing-club directory
node create-admin.js
```

**Option B: Manual Creation**
1. Go to `http://localhost:3000/register`
2. Fill out the form with:
   - **Email**: admin@tantalusboxing.com
   - **Password**: TantalusAdmin2025!
   - **Fighter Name**: Admin Fighter
   - **Other fields**: Fill as needed

### STEP 4: Restart Development Server

```bash
# Stop current server (Ctrl+C)
# Then restart
npm start
```

## 🔍 TROUBLESHOOTING

### If Supabase Connection Fails:
- Check environment variables are correct
- Verify Supabase project is active
- Ensure you have internet connection

### If Database Schema Fails:
- Check you have proper permissions in Supabase
- Verify the SQL script is complete
- Try running sections of the schema individually

### If Admin Account Creation Fails:
- Check that user authentication is enabled in Supabase
- Verify RLS policies allow user creation
- Try creating a regular user first

### If App Still Doesn't Work:
- Check browser console for errors (F12)
- Verify all environment variables are set
- Restart the development server
- Clear browser cache

## 📋 VERIFICATION CHECKLIST

- [ ] Environment variables configured in `.env.local`
- [ ] Database schema executed successfully
- [ ] Admin account created (or script run successfully)
- [ ] Development server running on port 3000
- [ ] Can access `http://localhost:3000`
- [ ] Registration form loads without errors
- [ ] Can create a test fighter profile
- [ ] Admin can log in with admin@tantalusboxing.com

## 🚀 EXPECTED RESULTS

After completing all steps:
1. **App loads** at `http://localhost:3000`
2. **Registration works** - can create fighter profiles
3. **Admin account exists** - can log in as admin
4. **No error messages** in browser console
5. **Database connected** - all operations work

## 🆘 EMERGENCY FIXES

### If Nothing Works:
1. **Delete `.env.local`** and recreate it
2. **Restart Supabase project** (if possible)
3. **Create new Supabase project** and start fresh
4. **Check Supabase status** at https://status.supabase.com

### If Database Issues Persist:
1. **Disable RLS temporarily** in Supabase
2. **Check table permissions** in Supabase dashboard
3. **Verify foreign key constraints** are correct

## 📞 SUPPORT

If you're still having issues:
1. **Check browser console** for specific error messages
2. **Verify Supabase project** is active and accessible
3. **Test with simple email/password** combinations
4. **Check network connectivity** to Supabase

## 🎯 QUICK START COMMANDS

```bash
# 1. Create environment file
echo "REACT_APP_SUPABASE_URL=https://your-project.supabase.co" > .env.local
echo "REACT_APP_SUPABASE_ANON_KEY=your-anon-key" >> .env.local

# 2. Install dependencies (if needed)
npm install

# 3. Create admin account
node create-admin.js

# 4. Start development server
npm start
```

**🎉 After completing these steps, everything should work perfectly!**

