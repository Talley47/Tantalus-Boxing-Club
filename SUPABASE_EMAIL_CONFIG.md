# 📧 Supabase Email Configuration Fix

## Issue
The error "Email address is invalid" occurs when Supabase email provider needs configuration.

## Quick Fix (2 minutes)

### Step 1: Configure Email Provider

1. Go to your Supabase Dashboard: https://supabase.com/dashboard
2. Select your project: **andmtvsqqomgwphotdwf**
3. Navigate to: **Authentication** → **Providers** → **Email**
4. Make sure these settings are configured:

#### Email Auth Settings:
- ✅ **Enable Email provider** - Should be ON (green)
- ✅ **Confirm email** - Turn this OFF for development
- ✅ **Secure email change** - Can leave as is
- ✅ **Secure password change** - Can leave as is

5. Click **"Save"** at the bottom

### Step 2: Enable Email Confirmations (Optional)

While you're there, you can also:
1. Scroll down to **"Email Templates"**
2. Disable **"Confirm signup"** for development (re-enable in production)

### Step 3: Try Creating Admin Again

Run:
```bash
cd tantalus-boxing-club
node create-admin.js
```

## Alternative: Create Admin Manually

If the script still doesn't work, create the admin account manually:

### Manual Creation Steps:

1. In Supabase Dashboard → **Authentication** → **Users**
2. Click **"Add user"** → **"Create new user"**
3. Fill in:
   - **EmailMenu`admin@tantalusboxing.com`
   - **PasswordMenu`TantalusAdmin2025!`
   - **Auto Confirm UserMenu✅ CHECK THIS
4. Click **"Create user"**
5. The admin user will be created

### Then Create Profile in SQL Editor:

1. Go to **SQL Editor** → **New Query**
2. Paste this SQL (replace `USER_ID` with the actual UUID from the users table):

```sql
-- First, add role to profiles table
INSERT INTO profiles (id, email, full_name, role, created_at, updated_at)
VALUES (
  'USER_ID_FROM_AUTH_USERS_TABLE',
  'admin@tantalusboxing.com',
  'Admin User',
  'admin',
  NOW(),
  NOW()
)
ON CONFLICT (id) DO UPDATE SET role = 'admin';

-- Then create fighter profile
INSERT INTO fighter_profiles (
  user_id, name, handle, birthday, hometown, stance,
  height_feet, height_inches, reach, weight, weight_class,
  trainer, gym, tier, points, wins, losses, draws
)
VALUES (
  'USER_ID_FROM_AUTH_USERS_TABLE',
  'Admin Fighter',
  'admin',
  '1994-01-01',
  'Admin City',
  'orthodox',
  6,
  0,
  72,
  200,
  'heavyweight',
  'System Trainer',
  'TBC HQ',
  'elite',
  1000,
  0,
  0,
  0
);
```

## Verification

After configuration:
```bash
node verify-setup.js
```

Then try starting the app:
```bash
npm start
```

And login with:
- Email: `admin@tantalusboxing.com`
- Password: `TantalusAdmin2025!`

---

**Next:** Once admin account is created, we can test the registration flow and then migrate to Next.js! 🚀


