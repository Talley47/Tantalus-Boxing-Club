# Enable Leaked Password Protection in Supabase

## What is Leaked Password Protection?

Supabase Auth can check passwords against the HaveIBeenPwned database to prevent users from using compromised passwords that have been leaked in data breaches. This is a security best practice that helps protect your users' accounts.

## How to Enable It

**This setting is configured in the Supabase Dashboard, not via SQL.**

### Exact Steps:

1. **Access Your Supabase Project Dashboard**
   - Log in to: https://supabase.com/dashboard
   - Select your project

2. **Navigate to Authentication Settings**
   - In the left-hand menu, click on **"Authentication"**
   - Then, select **"Settings"** under the Authentication section

3. **Configure Password Security**
   - Scroll down to the **"Password Security"** section
   - Locate the option labeled **"Prevent leaked passwords"** or **"Leaked password protection"**
   - Toggle this option to **"On"** to enable the feature
   - Save the changes

### Important Notes:

- ⚠️ **Plan Requirement**: This feature is available on **Pro Plan and above**
- If you don't see this option, you may need to upgrade your Supabase plan
- The setting takes effect immediately after enabling

### What Happens When Enabled?

- When users sign up or change their password, Supabase will check if the password appears in the HaveIBeenPwned database
- If the password is found in a data breach, the user will be prompted to choose a different password
- This helps prevent account takeover attacks using leaked credentials

### Benefits:

✅ **Enhanced Security**: Prevents use of compromised passwords  
✅ **User Protection**: Helps users avoid passwords that have been leaked  
✅ **Best Practice**: Industry-standard security measure  
✅ **Zero Code Changes**: Works automatically once enabled  

### Note:

- This feature uses the HaveIBeenPwned API (k-anonymity method)
- No passwords are sent to HaveIBeenPwned - only a hash prefix
- The check happens server-side during authentication
- There's no performance impact on your application

## Verification

After enabling, you can test it by:
1. Try to sign up with a known compromised password (like "password123")
2. You should see an error message indicating the password has been compromised
3. The signup should be blocked until a secure password is used

---

**Status**: ⚠️ Currently Disabled  
**Action Required**: Enable in Supabase Dashboard  
**Impact**: High - Improves security posture  

