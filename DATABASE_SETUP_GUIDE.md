# Tantalus Boxing Club - Database Setup Guide

## Prerequisites
- Supabase project created
- Supabase URL and Anon Key available
- Access to Supabase SQL Editor

## Step 1: Access Supabase Dashboard

1. Go to [https://supabase.com/dashboard](https://supabase.com/dashboard)
2. Sign in to your account
3. Click on your project: `andmtvsqqomgwphotdwf`

## Step 2: Run Database Schema

1. **Navigate to SQL Editor**:
   - In the left sidebar, click on "SQL Editor"
   - Click "New Query"

2. **Copy and Paste Schema**:
   - Open the file: `database/schema-clean.sql`
   - Copy ALL content (651 lines)
   - Paste into the SQL Editor

3. **Execute Schema**:
   - Click the "Run" button (or press Ctrl+Enter)
   - Wait for execution to complete
   - You should see "Success" message

## Step 3: Create Admin User

After the schema is set up, run this SQL in a new query:

```sql
-- Create admin user
INSERT INTO auth.users (
    id,
    email,
    encrypted_password,
    email_confirmed_at,
    created_at,
    updated_at,
    raw_app_meta_data,
    raw_user_meta_data,
    is_super_admin,
    role
) VALUES (
    uuid_generate_v4(),
    'admin@tantalusboxing.com',
    crypt('TantalusAdmin2025!', gen_salt('bf')),
    NOW(),
    NOW(),
    NOW(),
    '{"provider": "email", "providers": ["email"]}',
    '{"name": "Admin User"}',
    true,
    'authenticated'
);

-- Get the admin user ID and create fighter profile
DO $$
DECLARE
    admin_user_id UUID;
BEGIN
    SELECT id INTO admin_user_id FROM auth.users WHERE email = 'admin@tantalusboxing.com';
    
    -- Create admin fighter profile
    INSERT INTO fighter_profiles (
        user_id,
        name,
        handle,
        platform,
        platform_id,
        timezone,
        height,
        weight,
        reach,
        age,
        stance,
        nationality,
        fighting_style,
        hometown,
        birthday,
        weight_class,
        tier
    ) VALUES (
        admin_user_id,
        'Admin User',
        'admin',
        'PC',
        'admin',
        'UTC',
        72,
        180,
        72,
        30,
        'Orthodox',
        'USA',
        'Boxer',
        'Admin City',
        '1990-01-01',
        'Heavyweight',
        'Elite'
    );
END $$;
```

## Step 4: Verify Setup

1. **Check Tables**:
   - Go to "Table Editor" in Supabase
   - Verify these tables exist:
     - `tiers`
     - `fighter_profiles`
     - `fight_records`
     - `rankings`
     - `tournaments`
     - `notifications`
     - `system_settings`

2. **Check Admin User**:
   - In Table Editor, go to `fighter_profiles`
   - Look for a record with `handle = 'admin'`
   - Verify the admin user was created

3. **Test Connection** (Optional):
   ```bash
   cd tantalus-boxing-club
   node test-db-connection.js
   ```

## Step 5: Configure Authentication

1. **Go to Authentication Settings**:
   - In Supabase dashboard, go to "Authentication" → "Settings"

2. **Enable Email Authentication**:
   - Make sure "Enable email confirmations" is checked
   - Set "Site URL" to your app URL (e.g., `http://localhost:3000`)

3. **Configure RLS Policies**:
   - The schema includes Row Level Security policies
   - These are automatically applied when the schema runs

## Step 6: Test the Application

1. **Start the Application**:
   ```bash
   cd tantalus-boxing-club
   npm start
   ```

2. **Test Admin Login**:
   - Go to the login page
   - Use credentials:
     - Email: `admin@tantalusboxing.com`
     - Password: `TantalusAdmin2025!`

3. **Verify Features**:
   - Admin panel should be accessible
   - User management should work
   - All components should load without errors

## Troubleshooting

### Common Issues:

1. **"Table doesn't exist" errors**:
   - Make sure you ran the complete schema
   - Check for any SQL errors in the execution

2. **Authentication errors**:
   - Verify your `.env.local` file has correct credentials
   - Check Supabase project settings

3. **Permission errors**:
   - Ensure RLS policies are properly set
   - Check user roles in Supabase

### Getting Help:

- Check Supabase logs in the dashboard
- Verify your environment variables
- Test individual SQL queries in the SQL Editor

## Success Indicators

✅ All tables created without errors  
✅ Admin user can log in  
✅ Application loads without database errors  
✅ Admin panel is accessible  
✅ User management works  

Once these are confirmed, your Tantalus Boxing Club database is fully set up and ready for use!
