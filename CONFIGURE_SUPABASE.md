# 🔧 Configure Supabase for Tantalus Boxing Club

## Step 1: Get Your Supabase Credentials

1. Go to your Supabase dashboard: **[https://supabase.com/dashboard](https://supabase.com/dashboard)**
2. Select your **Tantalus Boxing Club** project
3. Go to **Settings** → **API**
4. Copy these two values:

### Values to Copy:
```
Project URL: https://xxxxxxxxxxxxx.supabase.co
anon public key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.ey...
```

## Step 2: Configure OLD React App

### 2.1 Update .env.local

1. Open the file: `tantalus-boxing-club/.env.local`
2. Replace the contents with:

```env
REACT_APP_SUPABASE_URL=https://YOUR_PROJECT_ID.supabase.co
REACT_APP_SUPABASE_ANON_KEY=YOUR_ANON_KEY_HERE
```

3. Replace `YOUR_PROJECT_ID.supabase.co` with your actual Project URL
4. Replace `YOUR_ANON_KEY_HERE` with your actual anon/public key
5. **Save the file**

### 2.2 Set Up Database Schema

1. In Supabase dashboard, go to **SQL Editor**
2. Click **"New Query"**
3. Open the file: `tantalus-boxing-club/database/schema-fixed.sql`
4. Copy ALL the contents
5. Paste into Supabase SQL Editor
6. Click **"Run"** button
7. Wait for completion (should show success message)

### 2.3 Create Admin Account

Open terminal and run:
```bash
cd tantalus-boxing-club
node create-admin.js
```

You should see: `✓ Admin account created successfully!`

### 2.4 Start the Old React App

```bash
npm start
```

The app should open at `http://localhost:3000`

### 2.5 Test Admin Login

1. Go to `http://localhost:3000`
2. Click "Login"
3. Enter:
   - **Email**: `admin@tantalusboxing.com`
   - **Password**: `TantalusAdmin2025!`
4. You should see the dashboard

## Step 3: Configure NEW Next.js App

### 3.1 Create .env.local for Next.js

1. Create a file: `tantalus-boxing-club/tantalus-boxing-club/tantalus-boxing-nextjs/.env.local`
2. Add the following (use the SAME Supabase credentials):

```env
# Supabase Configuration
NEXT_PUBLIC_SUPABASE_URL=https://YOUR_PROJECT_ID.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=YOUR_ANON_KEY_HERE
SUPABASE_SERVICE_ROLE_KEY=YOUR_SERVICE_ROLE_KEY_HERE

# Upstash Redis (Optional - for rate limiting)
# Get from: https://console.upstash.com
UPSTASH_REDIS_REST_URL=https://your-redis-url.upstash.io
UPSTASH_REDIS_REST_TOKEN=your-redis-token

# Optional: Monitoring (can skip for now)
# NEXT_PUBLIC_SENTRY_DSN=your_sentry_dsn_here
# NEXT_PUBLIC_POSTHOG_KEY=your_posthog_key_here
# NEXT_PUBLIC_POSTHOG_HOST=https://app.posthog.com

# Application Configuration
NODE_ENV=development
NEXT_PUBLIC_APP_URL=http://localhost:3000
```

3. Replace the Supabase values with your actual credentials
4. **Save the file**

**Note:** The Next.js app can use the SAME database as the old React app!

### 3.2 Get Service Role Key (Optional but recommended)

1. In Supabase dashboard → Settings → API
2. Scroll down to "Service role secret"
3. Click "Reveal" and copy the key
4. Add to `.env.local` under `SUPABASE_SERVICE_ROLE_KEY`

⚠️ **IMPORTANT**: Keep service role key secret! Never commit to git!

## 📋 Verification Checklist

### Old React App:
- [ ] `.env.local` created and configured
- [ ] Database schema executed in Supabase
- [ ] Admin account created (`node create-admin.js`)
- [ ] App starts without errors (`npm start`)
- [ ] Can login as admin
- [ ] Can create new fighter account

### New Next.js App:
- [ ] `.env.local` created and configured
- [ ] Uses SAME database as old app
- [ ] App runs on http://localhost:3000 or 3001
- [ ] Home page loads correctly
- [ ] Can navigate to /login

## 🎯 What I'll Help With Next

Once you've updated both `.env.local` files:

1. I'll help test the old React app
2. We'll verify registration flow works
3. Then we'll test the Next.js app
4. Finally, we'll complete the migration to Next.js

## ❓ Need the Files?

Run this command to see what needs to be configured:
```bash
cd tantalus-boxing-club
node verify-setup.js
```

---

**Ready to proceed! Update the .env.local files and let me know when done.** 🚀


